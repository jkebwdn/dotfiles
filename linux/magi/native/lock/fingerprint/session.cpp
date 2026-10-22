#include "session.hpp"
namespace magi::fingerprint {
bool Session::start(std::string daemon,std::string path,std::uint64_t now, bool secureLockReady) {
    if(active_ || claimed_ || now<next_ || daemon.empty() || daemon[0]!=':' || path.empty() || !model_.start(secureLockReady)) return false;
    binding_=model_.binding();daemon_=std::move(daemon);path_=std::move(path);started_=now;
    // Ready means successful claim and VerifyStart, not merely reader presence.
    if(!device_.claim()) {model_.cancel();model_.capability(Capability::Busy);next_=now+1500;return false;}
    claimed_=true;
    if(!device_.verifyStart()) {cleanup();model_.cancel();return false;}
    verifying_=active_=true;model_.receive(encode({binding_,Event::Ready}));return true;
}
bool Session::cleanup() {
    active_=false;
    bool ok=true;
    if(verifying_) {verifying_=false;ok=device_.verifyStop();}
    if(claimed_) {claimed_=false;ok=device_.release() && ok;}
    return ok;
}
void Session::cancel() {model_.cancel();cleanup();}
void Session::lost(bool daemon) {
    if(active_) model_.receive(encode({binding_,daemon?Event::DaemonLost:Event::DeviceLost}));
    else model_.invalidate();
    active_=verifying_=claimed_=false; // No further calls against a vanished device/daemon.
}
void Session::status(Binding subscription, std::string_view daemon,std::string_view path,std::string_view status,bool done, std::uint64_t now) {
    if(!active_ || subscription!=binding_ || daemon!=daemon_ || path!=path_) return;
    const auto event=verifyStatus(status,done).value_or(Event::Error);
    if(event==Event::DeviceLost) {lost(false);return;}
    if(event==Event::Retry) {model_.receive(encode({binding_,event}));return;}
    // A match is only reported after successful orderly cleanup. Uncertain cleanup
    // fails closed; password does not wait for this adapter or its deadline.
    const bool clean=cleanup();
    model_.receive(encode({binding_,clean?event:Event::Error}));
    next_=now+1500;
}
void Session::tick(std::uint64_t now) {
    if(active_ && now>=started_ && now-started_>=30000) {
        cleanup();model_.receive(encode({binding_,Event::Timeout}));next_=now+1500;
    }
}
}
