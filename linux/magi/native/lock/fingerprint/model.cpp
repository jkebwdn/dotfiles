#include "model.hpp"
#include <limits>
namespace magi::fingerprint {
Packet encode(Message m) {
    Packet p{}; p[0]='M';p[1]='F';p[2]='P';p[3]=1;p[4]=static_cast<std::uint8_t>(m.event);
    auto put=[&](unsigned offset,std::uint64_t value,unsigned size){for(unsigned i=0;i<size;++i)p[offset+i]=value>>(i*8);};
    put(8,m.binding.lock,8);put(16,m.binding.attempt,8);put(24,m.binding.uid,4);return p;
}
std::optional<Message> decode(std::span<const std::uint8_t> p) {
    if(p.size()!=32 || p[0]!='M' || p[1]!='F' || p[2]!='P' || p[3]!=1 || p[4]<1 || p[4]>10) return {};
    for(auto i:{5,6,7,28,29,30,31}) if(p[i]) return {};
    auto get=[&](unsigned offset,unsigned size){std::uint64_t v=0;for(unsigned i=0;i<size;++i)v|=std::uint64_t(p[offset+i])<<(i*8);return v;};
    Binding b{get(8,8),get(16,8),static_cast<std::uint32_t>(get(24,4))};
    if(!b.lock || !b.attempt) return {};
    return Message{b,static_cast<Event>(p[4])};
}
std::optional<Event> verifyStatus(std::string_view s,bool done) {
    if(s=="verify-match" && done) return Event::Match;
    if(s=="verify-no-match" && done) return Event::NoMatch;
    if(s=="verify-disconnected" && done) return Event::DeviceLost;
    if(s=="verify-unknown-error" && done) return Event::Error;
    if(!done && (s=="verify-retry-scan" || s=="verify-swipe-too-short" || s=="verify-finger-not-centered" || s=="verify-remove-and-retry" || s=="verify-too-fast")) return Event::Retry;
    return {};
}
bool Model::start(bool secure) {
    if(!secure || exhausted_ || active_ || capability_!=Capability::Enrolled) return false;
    if(binding_.attempt==std::numeric_limits<std::uint64_t>::max()) { exhausted_=true; return false; }
    ++binding_.attempt; state_=Attempt::Waiting;active_=true;ready_=false;consumed_=true;return true;
}
void Model::cancel() { active_=false;ready_=false;consumed_=true;state_=Attempt::Cancelled; }
void Model::invalidate() { cancel(); }
bool Model::receive(std::span<const std::uint8_t> packet) {
    const auto m=decode(packet);
    if(!m) {cancel();state_=Attempt::Failed;return false;}
    if(!active_ || m->binding!=binding_) return false;
    if(m->event==Event::Ready) {
        if(ready_) {cancel();state_=Attempt::Failed;return false;}
        ready_=true;return true;
    }
    if(!ready_) {cancel();state_=Attempt::Failed;return false;}
    switch(m->event) {
    case Event::Scan: state_=Attempt::Scanning;return true;
    case Event::Retry: state_=Attempt::Retry;return true;
    case Event::Match: state_=Attempt::Matched;consumed_=false;break;
    case Event::DeviceLost: state_=Attempt::DeviceLost;capability_=Capability::Unavailable;break;
    case Event::DaemonLost: state_=Attempt::DaemonLost;capability_=Capability::DaemonError;break;
    case Event::Busy: state_=Attempt::Failed;capability_=Capability::Busy;break;
    default: state_=Attempt::Failed;break;
    }
    active_=false;return true;
}
bool Model::consume(Binding b,bool secure) {
    if(!secure || b!=binding_ || consumed_ || state_!=Attempt::Matched || capability_!=Capability::Enrolled) return false;
    consumed_=true;return true;
}
}
