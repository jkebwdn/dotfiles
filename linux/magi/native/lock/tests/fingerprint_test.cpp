#include "model.hpp"
#include "auth_controller.hpp"
#include <QCoreApplication>
#include <cassert>
namespace magi {
struct AuthTestAccess {
    static bool wiped(const AuthController& auth) {
        for(const auto byte:auth.credential_.data_) if(byte!=0) return false;
        return auth.credential_.empty();
    }
};
}
using namespace magi::fingerprint;
// Test owner has no Wayland backend. Exercises the owner-side consumption contract
// and the real native password cancellation/scrubbing API, never an unlock socket.
struct Owner {
    Model fingerprint{42,1000}; SyntheticBackend broker{fingerprint};
    magi::AuthController password{"/nonexistent"};
    bool secure=true; unsigned unlocks=0;
    Owner(){password.setInputActive(true);}
    void matched(){if(fingerprint.consume(fingerprint.binding(),secure)){password.cancel();secure=false;++unlocks;}}
    void passwordWon(){fingerprint.cancel();password.cancel();if(secure){secure=false;++unlocks;}}
};
int main(int argc,char** argv) {
    QCoreApplication app(argc,argv);
    for(auto capability:{Capability::Unavailable,Capability::ReaderPresent,Capability::NoEnrollment,Capability::Busy,Capability::DaemonError}) {
        Owner o;o.fingerprint.capability(capability);assert(!o.broker.start(true));assert(o.password.append(std::span("x",1)));o.passwordWon();assert(o.unlocks==1);
    }
    for(auto event:{Event::NoMatch,Event::Timeout,Event::DeviceLost,Event::DaemonLost,Event::Busy,Event::Error}) {
        Owner o;o.fingerprint.capability(Capability::Enrolled);assert(o.broker.start(true));assert(o.broker.deliver(event));o.matched();assert(o.secure && !o.unlocks);assert(o.password.append(std::span("x",1)));o.passwordWon();assert(o.unlocks==1);
    }
    Owner o;o.fingerprint.capability(Capability::Enrolled);assert(o.secure && !o.unlocks);
    assert(!o.broker.start(false));assert(o.broker.start(true));assert(o.broker.deliver(Event::Scan));
    assert(o.password.append(std::span("partial",7)));assert(o.password.presentation().count==7);
    auto old=o.fingerprint.binding();assert(o.broker.status("verify-match",true));
    o.matched();o.matched();assert(o.unlocks==1 && o.password.presentation().count==0 && o.password.quiescent());
    assert(magi::AuthTestAccess::wiped(o.password));
    assert(!o.broker.deliver(Event::Match));
    Owner p;p.fingerprint.capability(Capability::Enrolled);assert(p.broker.start(true));assert(p.broker.deliver(Event::Scan));p.passwordWon();assert(!p.broker.deliver(Event::Match));p.matched();assert(p.unlocks==1);
    Owner r;r.fingerprint.capability(Capability::Enrolled);assert(r.broker.start(true));old=r.fingerprint.binding();r.broker.cancel();assert(!r.broker.deliver(Event::Match));assert(r.broker.start(true));
    assert(!r.fingerprint.receive(encode({old,Event::Match})));
    for(int field=0;field<3;++field){auto wrong=r.fingerprint.binding();if(field==0)++wrong.lock;if(field==1)++wrong.attempt;if(field==2)++wrong.uid;assert(!r.fingerprint.receive(encode({wrong,Event::Match})));}
    r.broker.resume(Capability::Unavailable);assert(!r.broker.deliver(Event::Match));assert(r.password.append(std::span("x",1)));r.fingerprint.capability(Capability::Enrolled);assert(r.broker.start(true));
    for(auto status:{"verify-retry-scan","verify-swipe-too-short","verify-finger-not-centered","verify-remove-and-retry","verify-too-fast"}){assert(r.broker.status(status,false));assert(r.fingerprint.state()==Attempt::Retry);}
    assert(!verifyStatus("verify-match",false));assert(!verifyStatus("unknown",true));
    auto packet=encode({r.fingerprint.binding(),Event::Match});
    std::array<std::uint8_t,33> oversized{};assert(!decode(oversized));
    for(unsigned n=0;n<32;++n)assert(!decode(std::span(packet.data(),n)));
    for(auto i:{0,1,2,3,4,5,6,7,28,29,30,31}){auto bad=packet;bad[i]=255;assert(!decode(bad));}
    // Death invalidates any outstanding candidate; no result is inferred from EOF.
    r.fingerprint.invalidate();assert(!r.fingerprint.receive(packet));r.matched();assert(r.secure);
    Model sequence{1,1000};sequence.capability(Capability::Enrolled);assert(sequence.start(true));assert(!sequence.receive(encode({sequence.binding(),Event::Match})));assert(!sequence.consume(sequence.binding(),true));
    Model malformed{2,1000};malformed.capability(Capability::Enrolled);SyntheticBackend b{malformed};assert(b.start(true));assert(!malformed.receive({}));assert(!b.deliver(Event::Match));
    Model duplicateReady{3,1000};duplicateReady.capability(Capability::Enrolled);
    SyntheticBackend d{duplicateReady};assert(d.start(true));assert(!d.deliver(Event::Ready));assert(!d.deliver(Event::Match));
    Model locked{4,1000};locked.capability(Capability::Enrolled);SyntheticBackend l{locked};assert(l.start(true));assert(l.deliver(Event::Match));assert(!locked.consume(locked.binding(),false));locked.invalidate();assert(!locked.consume(locked.binding(),true));
    Owner bad;bad.fingerprint.capability(Capability::Enrolled);assert(bad.broker.start(true));
    assert(!bad.fingerprint.receive({}));bad.matched();assert(bad.secure);
    assert(bad.password.append(std::span("x",1)));bad.passwordWon();assert(bad.unlocks==1);
    // Shared value snapshots for any number of outputs have no methods/authority.
    const auto first=r.fingerprint.state(),second=r.fingerprint.state();assert(first==second);
}
