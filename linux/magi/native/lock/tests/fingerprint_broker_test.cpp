#include "broker.hpp"
#include "controller.hpp"
#include "power_intent.hpp"
#include <QCoreApplication>
#include <QElapsedTimer>
#include <QThread>
#include <iostream>
#include <stdexcept>
using namespace magi;
#define CHECK(x) do { if (!(x)) throw std::runtime_error(std::to_string(__LINE__) + ": " #x); } while(false)
namespace magi::fingerprint {
struct BrokerTestAccess {
    static void deadline(Broker& b) { b.deadline_.start(20); }
    static void retry(Broker& b) { b.retry_.start(10); }
};
}
struct BackendFixture final : Backend {
    int unlocks = 0;
    bool requestLock() override { return true; }
    bool createSurface(uint32_t) override { return true; }
    void removeSurface(uint32_t) override {}
    FrameResult present(uint32_t, Configure, bool) override { return FrameResult::Presented; }
    void diagnostic(std::string_view) override {}
    void authenticatedUnlockAndSync() override { ++unlocks; }
    void disconnect() override {}
};
struct Daemon {
    sd_bus* bus = nullptr;
    QTimer timer;
    std::string mode = "match";
    int claims=0, stops=0, releases=0, verifies=0;
    static constexpr auto path = "/net/reactivated/Fprint/Device/0";
    static constexpr auto iface = "net.reactivated.Fprint.Device";
    static int method(sd_bus_message* m, void* data, sd_bus_error*) {
        auto& self=*static_cast<Daemon*>(data);
        const std::string name=sd_bus_message_get_member(m);
        if (name=="GetDefaultDevice") {
            if(self.mode=="unavailable") return sd_bus_reply_method_errorf(m,"net.reactivated.Fprint.Error.NoSuchDevice","Unavailable");
            return sd_bus_reply_method_return(m,"o",path);
        }
        if(name=="ListEnrolledFingers") {
            const char* user=nullptr; CHECK(sd_bus_message_read(m,"s",&user)>0 && std::string(user).empty());
            if(self.mode=="unenrolled") return sd_bus_reply_method_errorf(m,"net.reactivated.Fprint.Error.NoEnrolledPrints","No enrollment");
            return sd_bus_reply_method_return(m,"as",1,"right-index-finger");
        }
        if(name=="Claim") {
            const char* user=nullptr; CHECK(sd_bus_message_read(m,"s",&user)>0 && std::string(user).empty());
            ++self.claims;
            if(self.mode=="busy") return sd_bus_reply_method_errorf(m,"net.reactivated.Fprint.Error.AlreadyInUse","Busy");
        }
        if(name=="VerifyStart") {
            ++self.verifies;
            const auto mode=self.mode;
            if(mode!="waiting") QTimer::singleShot(20,&self.timer,[&self,mode] {
                sd_bus_emit_signal(self.bus,path,iface,"VerifyStatus","sb",
                    mode=="mismatch" ? "verify-no-match" : mode=="removed" ? "verify-disconnected" : "verify-match",1);
            });
        }
        if(name=="VerifyStop") {
            ++self.stops;
            if(self.mode=="cleanup-error") return sd_bus_reply_method_errorf(m,"net.reactivated.Fprint.Error.Internal","Cleanup failed");
        }
        if(name=="Release") ++self.releases;
        return sd_bus_reply_method_return(m,"");
    }
    Daemon() {
        CHECK(getenv("DBUS_SYSTEM_BUS_ADDRESS"));
        CHECK(sd_bus_new(&bus)>=0);
        CHECK(sd_bus_set_address(bus,getenv("DBUS_SYSTEM_BUS_ADDRESS"))>=0);
        CHECK(sd_bus_set_bus_client(bus,1)>=0);
        CHECK(sd_bus_start(bus)>=0);
        CHECK(sd_bus_request_name(bus,"net.reactivated.Fprint",0)>=0);
        static const sd_bus_vtable manager[]={SD_BUS_VTABLE_START(0),SD_BUS_METHOD("GetDefaultDevice","","o",method,0),SD_BUS_VTABLE_END};
        static const sd_bus_vtable device[]={SD_BUS_VTABLE_START(0),
            SD_BUS_METHOD("ListEnrolledFingers","s","as",method,0),SD_BUS_METHOD("Claim","s","",method,0),
            SD_BUS_METHOD("VerifyStart","s","",method,0),SD_BUS_METHOD("VerifyStop","","",method,0),
            SD_BUS_METHOD("Release","","",method,0),SD_BUS_SIGNAL("VerifyStatus","sb",0),SD_BUS_VTABLE_END};
        CHECK(sd_bus_add_object_vtable(bus,nullptr,"/net/reactivated/Fprint/Manager","net.reactivated.Fprint.Manager",manager,this)>=0);
        CHECK(sd_bus_add_object_vtable(bus,nullptr,path,iface,device,this)>=0);
        QObject::connect(&timer,&QTimer::timeout,[this]{for(int i=0;i<16;++i) {int rc=sd_bus_process(bus,nullptr);CHECK(rc>=0);if(!rc)break;}});
        timer.start(2);
    }
    ~Daemon() { timer.stop();sd_bus_flush_close_unref(bus); }
};
bool wait(const std::function<bool()>& predicate, int ms=1500) {
    QElapsedTimer elapsed;elapsed.start();
    while(!predicate() && elapsed.elapsed()<ms) {QCoreApplication::processEvents();QThread::msleep(1);}
    return predicate();
}
int main(int argc,char** argv) {
    QCoreApplication app(argc,argv);
    try {
        PowerIntent intent;
        CHECK(!intent.click(PowerIntent::Reboot,0));CHECK(!intent.click(PowerIntent::Reboot,50));
        CHECK(intent.click(PowerIntent::Reboot,900));CHECK(intent.pending()==PowerIntent::None);
        CHECK(!intent.click(PowerIntent::Suspend,2000));intent.cancel();CHECK(!intent.click(PowerIntent::Suspend,3000));
        CHECK(!intent.click(PowerIntent::Suspend,14000));CHECK(!intent.click(PowerIntent::None,15000));
        Daemon daemon;
        for(const auto mode:{"unavailable","unenrolled","busy","mismatch","removed","cleanup-error","waiting","match"}) {
            daemon.mode=mode;
            BackendFixture backend;Controller controller(backend);CHECK(controller.acquire());CHECK(controller.locked());
            fingerprint::Broker broker;
            int matches=0;
            broker.succeeded=[&](fingerprint::Binding binding){
                ++matches;CHECK(controller.fingerprintUnlock(broker,binding));CHECK(!controller.fingerprintUnlock(broker,binding));
            };
            broker.start();broker.start(); // idempotent, no duplicate claimant
            if(daemon.mode=="waiting") {
                CHECK(wait([&]{return std::string(broker.status())=="Touch fingerprint sensor";}));
                fingerprint::BrokerTestAccess::deadline(broker);
            }
            CHECK(wait([&]{return broker.quiescent();}));
            CHECK(matches==(daemon.mode=="match"?1:0));CHECK(backend.unlocks==matches);
            if(daemon.mode=="match") CHECK(daemon.stops>0 && daemon.releases>0);
            broker.cancel();
        }
        // Mismatch retries on a fresh connection; password remains independent.
        daemon.mode="mismatch";
        fingerprint::Broker retry;
        CHECK(wait([&]{return retry.quiescent();}));retry.start();
        CHECK(wait([&]{return std::string(retry.status()).find("didn’t match")!=std::string::npos;}));
        daemon.mode="waiting";fingerprint::BrokerTestAccess::retry(retry);
        CHECK(wait([&]{return std::string(retry.status())=="Touch fingerprint sensor";}));
        retry.cancel();CHECK(retry.quiescent());
        // Cancel/sleep/reload drops old results; native sleep gate rejects a match.
        for(bool blocked:{false,true}) {
            daemon.mode="waiting";BackendFixture backend;Controller controller(backend);
            CHECK(controller.acquire());CHECK(controller.locked());
            fingerprint::Broker broker;int matches=0;
            broker.succeeded=[&](fingerprint::Binding binding){++matches;CHECK(!controller.fingerprintUnlock(broker,binding));};
            broker.start();CHECK(wait([&]{return std::string(broker.status())=="Touch fingerprint sensor";}));
            if(blocked) controller.blockForSleep(true);else broker.cancel();
            sd_bus_emit_signal(daemon.bus,Daemon::path,Daemon::iface,"VerifyStatus","sb","verify-match",1);
            wait([&]{return matches>0;},100);
            CHECK(backend.unlocks==0);CHECK(matches==(blocked?1:0));broker.cancel();
        }
        // Daemon owner loss invalidates waiting state, even with late signals.
        daemon.mode="waiting";fingerprint::Broker lost;int matches=0;
        lost.succeeded=[&](fingerprint::Binding){++matches;};lost.start();
        CHECK(wait([&]{return std::string(lost.status())=="Touch fingerprint sensor";}));
        CHECK(sd_bus_release_name(daemon.bus,"net.reactivated.Fprint")>=0);
        CHECK(wait([&]{return lost.quiescent();}));CHECK(matches==0);
        Daemon replacement;replacement.mode="waiting";
        fingerprint::BrokerTestAccess::retry(lost);
        CHECK(wait([&]{return std::string(lost.status())=="Touch fingerprint sensor";}));
        // Old unique owner and wrong object path cannot inject a match.
        sd_bus_emit_signal(daemon.bus,Daemon::path,Daemon::iface,"VerifyStatus","sb","verify-match",1);
        sd_bus_emit_signal(replacement.bus,"/net/reactivated/Fprint/Device/99",Daemon::iface,"VerifyStatus","sb","verify-match",1);
        wait([&]{return matches>0;},100);CHECK(matches==0);
        sd_bus_emit_signal(replacement.bus,Daemon::path,Daemon::iface,"VerifyStatus","sb","verify-match",1);
        CHECK(wait([&]{return matches==1;}));lost.cancel();
        std::cout<<"Fingerprint broker private-bus integration PASS\n";
    } catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
}
