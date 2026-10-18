#include "logind_sleep.hpp"
#include "wayland_owner.hpp"
#include <QDebug>
#include <fcntl.h>
#include <unistd.h>
namespace magi {
namespace {
constexpr auto service="org.freedesktop.login1";
constexpr auto path="/org/freedesktop/login1";
constexpr auto interface="org.freedesktop.login1.Manager";
}
LogindSleep::LogindSleep(WaylandOwner& owner, SleepCoordinator coordinator) : owner_(owner), policy_(*this, coordinator) {
    poll_.setInterval(10);
    connect(&poll_, &QTimer::timeout, this, [this] { process(); });
    deadline_.setSingleShot(true);
    deadline_.setInterval(4000);
    connect(&deadline_, &QTimer::timeout, this, [this] { failure(); });
}
LogindSleep::~LogindSleep() {
    poll_.stop(); deadline_.stop();
    if (fd_>=0) close(fd_);
    sd_bus_slot_unref(signal_); sd_bus_slot_unref(ownerSlot_); sd_bus_unref(bus_);
}
bool LogindSleep::start() {
    if (bus_) return false;
    if (sd_bus_open_system(&bus_)<0 || sd_bus_set_method_call_timeout(bus_,1000000)<0) return false;
    if (sd_bus_match_signal(bus_,&signal_,service,path,interface,"PrepareForSleep",signal,this)<0 ||
        sd_bus_match_signal(bus_,&ownerSlot_,"org.freedesktop.DBus","/org/freedesktop/DBus","org.freedesktop.DBus","NameOwnerChanged",ownerChanged,this)<0) return false;
    if (!policy_.arm()) return false;
    uint64_t maximum=0;
    if (sd_bus_get_property_trivial(bus_,service,path,interface,"InhibitDelayMaxUSec",nullptr,'t',&maximum)<0 || maximum<500000) return false;
    deadline_.setInterval(int(std::min<uint64_t>(4000,maximum/1000-250)));
    int preparing=0;
    if (sd_bus_get_property_trivial(bus_,service,path,interface,"PreparingForSleep",nullptr,'b',&preparing)<0) return false;
    // Subscription precedes FD/property query: already-pending sleep is not missed.
    if (preparing) {
        qInfo("SLEEP INTENT: PreparingForSleep already true at startup");
        deadline_.start(); policy_.prepare(true);
    } else {
        policy_.prepare(false); // End delegation before allowing awake input.
    }
    if (policy_.state()==SleepState::Error) return false;
    poll_.start();
    qInfo("Sleep integration armed; finite logind delay is NOT an absolute suspend veto");
    return true;
}
bool LogindSleep::acquireDelay() {
    if (fd_>=0) return true;
    sd_bus_message* reply=nullptr;
    const int rc=sd_bus_call_method(bus_,service,path,interface,"Inhibit",nullptr,&reply,"ssss",
                                   "sleep","MAGI Lock","Clear credentials, reap authentication and confirm compositor lock","delay");
    int borrowed=-1;
    if (rc>=0 && sd_bus_message_read(reply,"h",&borrowed)>0) fd_=fcntl(borrowed,F_DUPFD_CLOEXEC,3);
    sd_bus_message_unref(reply);
    if (fd_>=0) qInfo("SLEEP DELAY ACQUIRED: native logind inhibitor held");
    return fd_>=0;
}
void LogindSleep::releaseDelay() {
    deadline_.stop();
    if (fd_>=0) { close(fd_); fd_=-1; }
    qInfo("SECURE FOR SLEEP: compositor locked, auth reaped, delay released");
}
void LogindSleep::ensureLock() { if (!owner_.start()) failure(); }
bool LogindSleep::secureLockReady() const { return owner_.secureLockReady(); }
void LogindSleep::quiesce() { owner_.prepareSleep(); }
bool LogindSleep::authQuiescent() const { return owner_.authQuiescent(); }
void LogindSleep::resumeInput() { deadline_.stop(); owner_.resumeSleep(); }
void LogindSleep::coordinatedReady() {
    deadline_.stop();
    qInfo("HYPRIDLE COORDINATED: compositor locked, auth quiescent; no native inhibitor acquired or released");
}
void LogindSleep::failure() {
    deadline_.stop();
    if (policy_.state()==SleepState::Error) return;
    policy_.fail();
    qCritical("SLEEP SAFETY UNPROVEN: retaining delay if held; logind may expire it; authentication remains blocked");
}
int LogindSleep::signal(sd_bus_message* message, void* data, sd_bus_error*) {
    auto& self=*static_cast<LogindSleep*>(data);
    int sleep=0;
    if (sd_bus_message_read(message,"b",&sleep)<0) { self.failure(); return 0; }
    qInfo(sleep ? "SLEEP SIGNAL: PrepareForSleep(true)" : "SLEEP SIGNAL: PrepareForSleep(false)");
    if (sleep && self.policy_.state()==SleepState::Awake) self.deadline_.start();
    self.policy_.prepare(sleep);
    return 0;
}
int LogindSleep::ownerChanged(sd_bus_message* message, void* data, sd_bus_error*) {
    const char *name=nullptr,*old=nullptr,*fresh=nullptr;
    if (sd_bus_message_read(message,"sss",&name,&old,&fresh)>0 && std::string_view(name)==service && old && *old)
        static_cast<LogindSleep*>(data)->failure();
    return 0;
}
bool LogindSleep::allowUnlock() {
    if (policy_.state()!=SleepState::Awake) return false;
    int preparing=0;
    if (sd_bus_get_property_trivial(bus_,service,path,interface,"PreparingForSleep",nullptr,'b',&preparing)<0) {
        failure(); return false;
    }
    if (preparing) {
        deadline_.start(); policy_.prepare(true); return false;
    }
    // Veto only; this is not authorization or an atomic transaction with logind.
    return policy_.state()==SleepState::Awake;
}
void LogindSleep::process() {
    for (int i=0;i<32;++i) {
        const int rc=sd_bus_process(bus_,nullptr);
        if (rc<0) { poll_.stop(); failure(); return; }
        if (!rc) break;
    }
    policy_.progress();
}
}
