#include "session.hpp"
#include <cassert>
using namespace magi::fingerprint;
struct Fake : Device {
    unsigned claims=0,starts=0,stops=0,releases=0;
    bool available=true,clean=true;
    bool claim() override {++claims;return available;}
    bool verifyStart() override {++starts;return true;}
    bool verifyStop() override {++stops;return clean;}
    bool release() override {++releases;return true;}
};
int main() {
    for(auto status:{"verify-match","verify-no-match","verify-unknown-error","unexpected"}) {
        Model m{42,1000};m.capability(Capability::Enrolled);Fake d;Session s{m,d};assert(s.start(":1.4","/device/0",0,true));
        s.status(m.binding(),":1.5","/device/0","verify-match",true,35000);assert(m.state()==Attempt::Waiting);
        s.status(m.binding(),":1.4","/device/1","verify-match",true,0);assert(m.state()==Attempt::Waiting);
        s.status(m.binding(),":1.4","/device/0",status,true,0);assert(d.stops==1 && d.releases==1);
        assert(m.consume(m.binding(),true)==(std::string_view(status)=="verify-match"));assert(!m.consume(m.binding(),true));
    }
    Model m{42,1000};m.capability(Capability::Enrolled);Fake d;Session s{m,d};assert(s.start(":1.4","/device/0",0,true));
    s.status(m.binding(),":1.4","/device/0","verify-retry-scan",false,0);assert(d.stops==0 && m.state()==Attempt::Retry);
    s.tick(29999);assert(m.state()==Attempt::Retry);s.tick(30000);assert(m.state()==Attempt::Failed && d.stops==1);assert(!s.start(":1.4","/device/0",31000,true));
    assert(s.start(":1.4","/device/0",31500,true));const auto stale=m.binding();s.cancel();s.status(m.binding(),":1.4","/device/0","verify-match",true,0);assert(!m.consume(m.binding(),true));
    assert(s.start(":1.4","/device/0",33000,true));s.status(stale,":1.4","/device/0","verify-match",true,33000);assert(m.state()==Attempt::Waiting);auto stops=d.stops;s.lost(true);assert(d.stops==stops && m.state()==Attempt::DaemonLost);
    m.capability(Capability::Enrolled);assert(s.start(":1.5","/device/0",35000,true));s.status(m.binding(),":1.4","/device/0","verify-match",true,35000);assert(m.state()==Attempt::Waiting);
    d.clean=false;s.status(m.binding(),":1.5","/device/0","verify-match",true,35000);assert(!m.consume(m.binding(),true));
    d.available=false;assert(!s.start(":1.5","/device/0",38000,true));assert(m.capability()==Capability::Busy);
}
