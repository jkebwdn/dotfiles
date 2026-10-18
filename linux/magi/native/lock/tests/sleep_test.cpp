#include "sleep_policy.hpp"
#include "controller.hpp"
#include "native_input.hpp"
#include "instance_guard.hpp"
#include "options.hpp"
#include <QCoreApplication>
#include <QElapsedTimer>
#include <QThread>
#include <QTemporaryDir>
#include <cstring>
#include <iostream>
#include <functional>
#include <stdexcept>
#include <sys/wait.h>
#include <unistd.h>
using namespace magi;
#define CHECK(x) do { if (!(x)) throw std::runtime_error("check failed: " #x); } while(false)
namespace {
int cases=0;
std::string logs;
constexpr char secret[]="MAGI_TEST_SECRET_7df1_CPP";
void wait(const std::function<bool()>& done) {
    QElapsedTimer t; t.start();
    while (!done() && t.elapsed()<3500) { QCoreApplication::processEvents(); QThread::msleep(2); }
    CHECK(done());
}
struct Lock : Backend {
    int requests=0,unlocks=0,paints=0; bool fail=false,fallback=false;
    bool requestLock() override { ++requests; return !fail; }
    bool createSurface(uint32_t) override { return true; }
    void removeSurface(uint32_t) override {}
    FrameResult present(uint32_t,Configure,bool) override { ++paints; return fallback ? FrameResult::Fallback : FrameResult::Presented; }
    void diagnostic(std::string_view) override {}
    void authenticatedUnlockAndSync() override { ++unlocks; }
    void disconnect() override {}
};
struct Sleep : SleepBackend {
    Lock backend; Controller lock{backend}; AuthController auth; NativeInput input{auth};
    bool acquireOkay=true,fd=false; int acquisitions=0,releases=0,quiesces=0,resumes=0,delegatedReady=0;
    explicit Sleep(const std::string& fixture) : auth(fixture,3000,20) {}
    bool acquireDelay() override { ++acquisitions; fd=acquireOkay; return fd; }
    void releaseDelay() override { CHECK(fd && secureLockReady() && authQuiescent()); fd=false; ++releases; }
    void ensureLock() override { if(lock.state()==State::Idle) lock.acquire(); }
    bool secureLockReady() const override { return lock.secureLockReady(); }
    void quiesce() override { ++quiesces; lock.blockForSleep(true); input.blockForSleep(true); }
    bool authQuiescent() const override { return auth.quiescent(); }
    void resumeInput() override { ++resumes; input.blockForSleep(false); lock.blockForSleep(false); lock.refresh(); }
    void coordinatedReady() override { CHECK(secureLockReady() && authQuiescent() && !fd); ++delegatedReady; }
};
void coordinated(const std::string& dir) {
    // Model the real chain: the external inhibitor predates sleep; only a
    // compositor event (not service READY or a render) can release Hypridle's FD.
    { Sleep b(dir+"/fixture-success"); SleepPolicy p(b,SleepCoordinator::Hypridle);
      bool externalHeld=true; CHECK(p.arm()); p.prepare(true); p.prepare(true);
      CHECK(b.acquisitions==0 && !p.held() && b.backend.requests==1);
      CHECK(b.auth.generation()==0 && b.auth.quiescent());
      b.lock.addOutput(1); b.lock.configure(1,{1,1920,1080}); p.progress();
      CHECK(!b.lock.secureLockReady() && externalHeld && !b.delegatedReady);
      CHECK(b.lock.locked()); // Fake compositor notifies both clients.
      if(b.lock.secureLockReady()) externalHeld=false;
      p.progress(); p.progress();
      CHECK(!externalHeld && b.delegatedReady==1 && b.releases==0 && b.acquisitions==0);
      CHECK(p.state()==SleepState::SecureForSleep && b.auth.generation()==0);
      p.prepare(false); CHECK(b.acquisitions==1 && p.held() && b.resumes==1);
      CHECK(p.coordinator()==SleepCoordinator::Native && b.lock.secureLockReady());
      CHECK(b.auth.quiescent() && b.backend.unlocks==0);
      // A second sleep, before authentication, is protected by the native FD.
      p.prepare(true); CHECK(b.releases==1 && b.delegatedReady==1);
      p.prepare(false); CHECK(b.acquisitions==2 && b.backend.unlocks==0); cases+=5; }
    { Sleep b(dir+"/fixture-success"); b.backend.fail=true;
      SleepPolicy p(b,SleepCoordinator::Hypridle); CHECK(p.arm()); p.prepare(true); p.progress();
      CHECK(!b.lock.secureLockReady() && !b.delegatedReady && !b.acquisitions && !b.backend.unlocks);
      p.fail(); p.prepare(false); CHECK(p.state()==SleepState::Error && !b.resumes);
      // Only the fake platform may expire its external delay; no readiness invented.
      ++cases; }
    { Sleep b(dir+"/fixture-success"); SleepPolicy p(b,SleepCoordinator::Hypridle);
      CHECK(p.arm()); p.prepare(false); CHECK(p.held() && b.acquisitions==1 && !b.resumes);
      CHECK(p.coordinator()==SleepCoordinator::Native); p.prepare(false); CHECK(b.acquisitions==1); ++cases; }
    { Sleep b(dir+"/fixture-success"); SleepPolicy p(b,SleepCoordinator::Hypridle);
      CHECK(p.arm()); p.prepare(true); b.lock.locked(); p.progress(); b.acquireOkay=false;
      p.prepare(false); CHECK(p.state()==SleepState::Error && !b.resumes && !b.backend.unlocks); ++cases; }
    { Sleep b(dir+"/fixture-success"); SleepPolicy p(b,SleepCoordinator::Hypridle);
      CHECK(p.arm()); p.prepare(true); b.input.key(28,true);
      CHECK(b.auth.generation()==0 && b.auth.quiescent() && !b.auth.presentation().active); ++cases; }
    { Sleep b(dir+"/fixture-success"); SleepPolicy p(b,SleepCoordinator::Hypridle);
      b.acquireOkay=false; CHECK(p.arm()); CHECK(!b.acquisitions);
      p.prepare(false); CHECK(p.state()==SleepState::Error && b.acquisitions==1);
      CHECK(!b.auth.presentation().active && !b.lock.secureLockReady() && !b.backend.unlocks); ++cases; }
}
void lifecycle(const std::string& dir) {
    { Sleep b(dir+"/fixture-success"); SleepPolicy p(b);
      CHECK(!b.lock.secureLockReady()); CHECK(p.arm()); CHECK(p.arm()); CHECK(b.acquisitions==1);
      p.prepare(false); CHECK(b.resumes==0); p.prepare(true); p.prepare(true);
      CHECK(b.backend.requests==1 && b.quiesces==1 && !b.releases);
      b.lock.addOutput(1); b.lock.configure(1,{1,1920,1080}); p.progress(); CHECK(!b.releases);
      CHECK(b.lock.locked()); p.progress(); CHECK(p.state()==SleepState::SecureForSleep && b.releases==1);
      p.progress(); p.prepare(true); CHECK(b.releases==1);
      p.prepare(false); CHECK(b.fd && b.acquisitions==2 && b.resumes==1);
      CHECK(b.lock.secureLockReady() && b.backend.unlocks==0); cases+=5; }
    { Sleep b(dir+"/fixture-success"); b.lock.acquire(); b.lock.locked(); SleepPolicy p(b); CHECK(p.arm());
      b.auth.setInputActive(true); CHECK(b.auth.append({secret,sizeof(secret)-1}));
      p.prepare(true); CHECK(b.auth.presentation().count==0 && b.auth.quiescent());
      CHECK(b.releases==1 && b.backend.requests==1); p.prepare(false);
      CHECK(!b.auth.presentation().active && b.auth.generation()==0 && b.backend.unlocks==0); cases+=2; }
    { Sleep b(dir+"/fixture-success"); b.acquireOkay=false; SleepPolicy p(b);
      CHECK(!p.arm()); CHECK(p.state()==SleepState::Error); p.prepare(true); p.prepare(false);
      CHECK(b.backend.requests==0 && b.releases==0 && b.backend.unlocks==0); ++cases; }
    for(bool failed : {false,true}) {
      Sleep b(dir+"/fixture-success"); b.backend.fail=failed; SleepPolicy p(b); CHECK(p.arm()); p.prepare(true);
      p.fail(); p.progress(); p.prepare(false);
      CHECK(p.state()==SleepState::Error && b.fd && b.releases==0 && !b.lock.secureLockReady());
      CHECK(b.backend.unlocks==0); ++cases;
    }
    { Sleep b(dir+"/fixture-success"); SleepPolicy p(b); CHECK(p.arm()); b.lock.acquire(); b.lock.locked();
      p.prepare(true); b.acquireOkay=false; p.prepare(false);
      CHECK(p.state()==SleepState::Error && b.resumes==0 && b.backend.unlocks==0); ++cases; }
}
void authSleep(const std::string& dir) {
    for(const auto mode : {"delayed-success","hang","success"}) {
      Sleep b(dir+"/fixture-"+mode); SleepPolicy p(b); CHECK(p.arm()); b.lock.acquire(); b.lock.locked();
      b.auth.setInputActive(true); CHECK(b.auth.append({secret,sizeof(secret)-1})); CHECK(b.auth.submit());
      const auto generation=b.auth.generation();
      // Include a fully completed but unconsumed Success at the sleep boundary.
      if(std::string(mode)=="success") wait([&]{return b.auth.state()==AuthState::Succeeded;});
      p.prepare(true); CHECK(b.auth.presentation().count==0);
      CHECK(!b.lock.authenticatedUnlock(b.auth,generation));
      if(!b.auth.quiescent()) CHECK(b.releases==0);
      wait([&]{p.progress(); return b.releases==1;});
      CHECK(b.auth.quiescent() && b.auth.generation()==generation && b.backend.unlocks==0);
      p.prepare(false); CHECK(b.auth.quiescent()); CHECK(!b.lock.authenticatedUnlock(b.auth,generation));
      CHECK(b.backend.unlocks==0); ++cases;
    }
}
void outputs(const std::string& dir) {
    for(int count : {0,1,2}) {
      Sleep b(dir+"/fixture-success"); SleepPolicy p(b); CHECK(p.arm()); b.lock.acquire(); b.lock.locked();
      b.lock.addOutput(9); b.lock.configure(9,{1,1920,1080}); const auto old=b.lock.outputs().at(9).lifetime;
      p.prepare(true); b.lock.removeOutput(9); p.prepare(false);
      CHECK(b.lock.outputs().empty() && b.lock.secureLockReady()); b.backend.fallback=true;
      for(int i=0;i<count;++i) { b.lock.addOutput(9+i); b.lock.configure(9+i,{2,640,480}); }
      auto paints=b.backend.paints; b.lock.bufferAvailable(9,old); CHECK(b.backend.paints==paints);
      CHECK(!b.lock.configure(9,{4,1,1},old)); CHECK(b.auth.quiescent() && b.backend.unlocks==0); ++cases;
    }
}
void keyboard(const std::string& dir) {
    Sleep b(dir+"/fixture-success"); SleepPolicy p(b); CHECK(p.arm()); b.lock.acquire(); b.lock.locked();
    auto* ctx=xkb_context_new(XKB_CONTEXT_NO_FLAGS); xkb_rule_names names{}; names.layout="gb";
    auto* map=xkb_keymap_new_from_names(ctx,&names,XKB_KEYMAP_COMPILE_NO_FLAGS); CHECK(map);
    char* text=xkb_keymap_get_as_string(map,XKB_KEYMAP_FORMAT_TEXT_V1); CHECK(text);
    CHECK(b.input.keymap({text,strlen(text)+1})); b.input.focus(true); b.input.modifiers(0,0,0,0);
    b.input.key(30,true); CHECK(b.auth.presentation().count==1);
    p.prepare(true); b.input.focus(true); b.input.modifiers(1,0,0,0); b.input.key(28,true);
    CHECK(b.auth.generation()==0 && !b.auth.presentation().active);
    p.prepare(false); b.input.key(30,false); b.input.key(30,true); CHECK(b.auth.presentation().count==0);
    wait([&]{return b.auth.state()==AuthState::Idle;});
    CHECK(b.input.keymap({text,strlen(text)+1})); b.input.focus(true); b.input.key(30,true); CHECK(b.auth.presentation().count==0);
    b.input.key(30,false); b.input.modifiers(0,0,0,0); b.input.key(30,true); b.input.key(30,false);
    CHECK(b.auth.presentation().count==1);
    b.auth.clear(); CHECK(b.auth.append({secret,sizeof(secret)-1}));
    b.auth.succeeded=[&](auto g){CHECK(b.lock.authenticatedUnlock(b.auth,g));};
    b.input.key(28,true); wait([&]{return b.backend.unlocks==1;});
    CHECK(b.auth.generation()==1); free(text); xkb_keymap_unref(map); xkb_context_unref(ctx); cases+=3;
}
void instances() {
    QTemporaryDir dir; CHECK(dir.isValid()); auto path=dir.path().toStdString();
    { InstanceGuard owner; CHECK(owner.acquire(path,"wayland-test"));
      InstanceGuard duplicate; CHECK(!duplicate.acquire(path,"wayland-test"));
      auto child=fork(); CHECK(child>=0);
      if(child==0) { InstanceGuard contender; _exit(contender.acquire(path,"wayland-test") ? 1 : 0); }
      int status=0; CHECK(waitpid(child,&status,0)==child && WIFEXITED(status) && WEXITSTATUS(status)==0);
      InstanceGuard invalid; CHECK(!invalid.acquire(path,"../bad")); }
    InstanceGuard next; CHECK(next.acquire(path,"wayland-test")); cases+=3;
}
}
int main(int argc,char** argv) {
    QCoreApplication app(argc,argv); qInstallMessageHandler([](QtMsgType,const QMessageLogContext&,const QString& msg){logs+=msg.toStdString();});
    try {
      CHECK(argc==2); lifecycle(argv[1]); coordinated(argv[1]); authSleep(argv[1]); outputs(argv[1]); keyboard(argv[1]); instances();
      CHECK(!parseOptions(std::array<std::string_view,1>{"--sleep-integration"}).error.empty());
      CHECK(!parseOptions(std::array<std::string_view,1>{"--notify-ready"}).error.empty()); cases+=2;
      CHECK(!parseOptions(std::array<std::string_view,1>{"--sleep-coordinator=hypridle"}).error.empty());
      CHECK(!parseOptions(std::array<std::string_view,4>{"--acquire-session-lock","--authenticate","--sleep-integration","--sleep-coordinator=invalid"}).error.empty());
      auto options=parseOptions(std::array<std::string_view,4>{"--acquire-session-lock","--authenticate","--sleep-integration","--sleep-coordinator=hypridle"});
      CHECK(options.error.empty() && options.sleepCoordinator==SleepCoordinator::Hypridle); cases+=3;
      CHECK(!parseOptions(std::array<std::string_view,5>{"--acquire-session-lock","--authenticate","--sleep-integration","--sleep-coordinator=native","--sleep-coordinator=hypridle"}).error.empty()); ++cases;
      CHECK(logs.find(secret)==std::string::npos);
    } catch(const std::exception& e) { std::cerr<<"after "<<cases<<" scenarios: "<<e.what()<<'\n'; return 1; }
    std::cout<<cases<<" sleep/readiness/inhibitor/input/instance scenarios passed; no real logind, Wayland or PAM\n";
}
