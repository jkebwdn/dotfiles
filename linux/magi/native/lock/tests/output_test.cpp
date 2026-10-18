#include "controller.hpp"
#include "native_input.hpp"
#include "presentation.hpp"
#include <QGuiApplication>
#include <QElapsedTimer>
#include <QQuickWindow>
#include <QThread>
#include <cstring>
#include <functional>
#include <iostream>
#include <set>
#include <stdexcept>
namespace magi {
struct AuthTestAccess {
    static pid_t pid(const AuthController& a) { return a.pid_; }
    static bool retry(const AuthController& a) { return a.retry_.isActive(); }
};
}
using namespace magi;
#define CHECK(c) do { if (!(c)) throw std::runtime_error(std::string("line ")+std::to_string(__LINE__)+": " #c); } while(false)
namespace {
std::string logs;
int cases = 0;
constexpr char secret[] = "MAGI_TEST_SECRET_7df1_CPP";
void waitFor(const std::function<bool()>& done) {
    QElapsedTimer t; t.start();
    while (!done() && t.elapsed()<4000) { QCoreApplication::processEvents(); QThread::msleep(2); }
    CHECK(done());
}
struct Fake final : Backend {
    AuthController* auth = nullptr;
    std::set<uint32_t> surfaces;
    std::map<uint32_t, FrameResult> results;
    std::map<uint32_t, Configure> frames;
    std::map<uint32_t, AuthPresentation> views;
    std::map<uint32_t, unsigned> acknowledgements;
    uint32_t failCreate = 0, invalidQml = 0;
    int requests = 0, unlocks = 0, paints = 0;
    bool render = false;
    bool requestLock() override { ++requests; return true; }
    bool createSurface(uint32_t id) override {
        if (id==failCreate) return false;
        CHECK(surfaces.insert(id).second); return true;
    }
    void removeSurface(uint32_t id) override {
        CHECK(surfaces.erase(id)==1); frames.erase(id); views.erase(id);
    }
    FrameResult present(uint32_t id, Configure c, bool ack) override {
        CHECK(surfaces.contains(id));
        auto result = results.contains(id) ? results.at(id) : FrameResult::Presented;
        if (result==FrameResult::Deferred || result==FrameResult::Failed) return result;
        auto view = auth ? auth->presentation() : AuthPresentation{};
        if (render) {
            QImage image(int(c.width),int(c.height),QImage::Format_RGB32);
            auto source = id==invalidQml ? QByteArray("import QtQuick\nNotAType {}") : QByteArray{};
            if (!Presentation::render(image,QString::number(id),"Locked","SYNTHETIC",source,view)) {
                Presentation::fallback(image,view); result=FrameResult::Fallback;
            }
            for (int y=0;y<image.height();++y) for (int x=0;x<image.width();++x) CHECK(qAlpha(image.pixel(x,y))==255);
        }
        frames[id]=c; views[id]=view; acknowledgements[id]+=ack; ++paints; return result;
    }
    void diagnostic(std::string_view) override {}
    void authenticatedUnlockAndSync() override { ++unlocks; }
    void disconnect() override { surfaces.clear(); frames.clear(); views.clear(); }
};
void add(Controller& c,uint32_t id,uint32_t width=640,uint32_t height=480) {
    CHECK(c.addOutput(id)); CHECK(c.outputs().at(id).lifecycle==OutputState::AwaitingConfigure);
    CHECK(c.configure(id,{1,width,height}));
}
void lifecycle() {
    Fake b; Controller c(b);
    CHECK(c.addOutput(9)); CHECK(c.outputs().at(9).lifecycle==OutputState::Discovered);
    CHECK(c.acquire()); CHECK(c.configure(9,{1,1920,1080})); CHECK(c.locked());
    CHECK(c.outputs().at(9).lifecycle==OutputState::Presented);
    CHECK(c.removeOutput(9)); CHECK(c.outputs().empty()); CHECK(c.state()==State::Locked);
    add(c,9); CHECK(b.requests==1 && b.unlocks==0); ++cases;
    add(c,2,1080,1920); add(c,75,3440,1440); CHECK(c.outputs().size()==3); ++cases;
    CHECK(!c.addOutput(2)); CHECK(!c.removeOutput(88)); CHECK(c.removeOutput(2)); CHECK(!c.removeOutput(2));
    CHECK(!c.configure(2,{2,800,600})); CHECK(!c.configure(88,{2,1,1})); ++cases;
    const auto old=c.outputs().at(9).lifetime;
    CHECK(c.removeOutput(9)); add(c,9); const auto fresh=c.outputs().at(9).lifetime; CHECK(old!=fresh);
    CHECK(!c.configure(9,{77,1,1},old));
    b.results[9]=FrameResult::Deferred; CHECK(c.configure(9,{2,800,600},fresh));
    b.results[9]=FrameResult::Presented; auto paints=b.paints; c.bufferAvailable(9,old); CHECK(b.paints==paints);
    c.bufferAvailable(9,fresh); CHECK(b.frames.at(9).width==800); ++cases;
    CHECK(c.removeOutput(9)); CHECK(c.removeOutput(75)); CHECK(c.outputs().empty());
    add(c,501); CHECK(c.state()==State::Locked && b.unlocks==0); ++cases;
    // Connector labels are deliberately absent from Controller identity. DP-1
    // reappearing under another registry global cannot inherit pending frames.
    CHECK(c.removeOutput(501)); add(c,600); CHECK(!c.configure(501,{8,20,20})); ++cases;
}
void geometryAndFailure() {
    for (auto size : {Configure{1,1920,1080},Configure{2,2560,1440},Configure{3,2560,1440},
                      Configure{4,1,1},Configure{5,1080,1920},Configure{6,3440,1440}}) {
        Fake b; Controller c(b); c.acquire(); c.locked(); add(c,1);
        CHECK(c.configure(1,{size.serial+10,size.width,size.height}));
        CHECK(b.frames.at(1).width==size.width && b.frames.at(1).height==size.height);
        auto acks=b.acknowledgements.at(1); c.refresh(); CHECK(b.acknowledgements.at(1)==acks); ++cases;
    }
    for (auto result : {FrameResult::Fallback,FrameResult::Failed,FrameResult::Deferred}) {
        Fake b; Controller c(b); c.acquire(); c.locked(); add(c,1);
        b.results[2]=result; add(c,2);
        CHECK(c.outputs().at(1).lifecycle==OutputState::Presented);
        CHECK(c.state()==State::Locked && b.unlocks==0);
        const auto expected=result==FrameResult::Fallback ? OutputState::Presented :
            result==FrameResult::Failed ? OutputState::PresentationFailed : OutputState::Configured;
        CHECK(c.outputs().at(2).lifecycle==expected);
        c.removeOutput(2); CHECK(!b.surfaces.contains(2) && b.surfaces.contains(1)); ++cases;
    }
    Fake b; Controller c(b); c.acquire(); c.locked(); add(c,1); b.failCreate=2;
    CHECK(c.addOutput(2)); CHECK(c.outputs().at(2).lifecycle==OutputState::PresentationFailed);
    CHECK(!c.configure(2,{1,800,600})); CHECK(b.unlocks==0); ++cases;
    CHECK(!c.configure(1,{99,0,1080})); CHECK(!b.surfaces.contains(1));
    CHECK(!c.configure(1,{100,1920,1080})); CHECK(c.state()==State::Locked); ++cases;
}
void presentationStates(const std::string& dir) {
    for (const auto stage : {AuthState::Editing, AuthState::Authenticating, AuthState::Failed,
                            AuthState::WorkerError, AuthState::Unsupported, AuthState::Cancelled}) {
        const auto mode=stage==AuthState::Failed ? "failed" : stage==AuthState::WorkerError ? "workererror" :
            stage==AuthState::Unsupported ? "echoon" : stage==AuthState::Cancelled ? "cancelled" : "delayed-success";
        AuthController auth(dir+"/fixture-"+mode,1500,1000);
        Fake b; b.auth=&auth; b.render=true; b.invalidQml=2;
        Controller c(b); c.acquire(); c.locked();
        auth.setInputActive(true); CHECK(auth.append({secret,sizeof(secret)-1}));
        if (stage!=AuthState::Editing) CHECK(auth.submit());
        if (stage!=AuthState::Editing && stage!=AuthState::Authenticating) waitFor([&]{ return auth.state()==stage; });
        const auto g=auth.generation(); const auto pid=AuthTestAccess::pid(auth); const auto count=auth.presentation().count;
        add(c,1,320,240); add(c,2,240,320); c.refresh();
        CHECK(c.outputs().at(2).fallback && !c.outputs().at(1).fallback);
        CHECK(auth.state()==stage && auth.generation()==g && AuthTestAccess::pid(auth)==pid);
        CHECK(auth.presentation().count==count && b.unlocks==0);
        CHECK(b.views.at(1).state==stage && b.views.at(2).state==stage); ++cases;
    }
    // Physical modes / scale / rotation are synthetic compositor inputs only.
    // The client renders the resulting logical configure unchanged, at DPR 1.
    struct Monitor { unsigned physicalWidth, physicalHeight, scale; bool rotated; };
    Fake b; b.render=true; Controller c(b); c.acquire(); c.locked();
    unsigned id=1;
    for (auto m : {Monitor{3840,2160,2,false},Monitor{1280,720,1,false},Monitor{1920,1080,3,true}}) {
        auto width=m.physicalWidth/m.scale, height=m.physicalHeight/m.scale;
        if (m.rotated) std::swap(width,height);
        add(c,id,width,height); CHECK(b.frames.at(id).width==width && b.frames.at(id).height==height); ++id; ++cases;
    }
    CHECK(c.outputs().size()==3 && b.unlocks==0);
}
void focusAndEditing(const std::string& dir) {
    AuthController auth(dir+"/fixture-delayed-success",1500,100);
    NativeInput input(auth);
    auto* context=xkb_context_new(XKB_CONTEXT_NO_FLAGS); xkb_rule_names names{}; names.layout="gb";
    auto* map=xkb_keymap_new_from_names(context,&names,XKB_KEYMAP_COMPILE_NO_FLAGS); CHECK(map);
    auto* text=xkb_keymap_get_as_string(map,XKB_KEYMAP_FORMAT_TEXT_V1);
    CHECK(input.keymap({text,std::strlen(text)+1})); free(text); xkb_keymap_unref(map); xkb_context_unref(context);
    Fake b; b.auth=&auth; Controller c(b); c.acquire(); c.locked(); add(c,1);
    input.focus(true); input.modifiers(0,0,0,0); input.key(30,true); input.key(30,false);
    CHECK(auth.presentation().count==1); add(c,2);
    input.focus(false,{},true); c.removeOutput(1); c.refresh();
    CHECK(auth.presentation().count==1 && auth.state()==AuthState::Editing && !auth.presentation().active);
    input.key(30,true); input.key(30,false); CHECK(auth.presentation().count==1);
    input.focus(true); input.key(30,true); input.key(30,false); CHECK(auth.presentation().count==1); // fresh modifiers required
    input.modifiers(0,0,0,0); auth.clear(); CHECK(auth.append({secret,sizeof(secret)-1})); CHECK(auth.submit()); auto pid=AuthTestAccess::pid(auth); auto generation=auth.generation();
    input.focus(false,{},true); c.removeOutput(2); CHECK(c.outputs().empty()); add(c,3);
    CHECK(AuthTestAccess::pid(auth)==pid && auth.generation()==generation && auth.state()==AuthState::Authenticating);
    auth.succeeded=[&](auto g) { CHECK(c.authenticatedUnlock(auth,g)); };
    waitFor([&]{ return b.unlocks==1; }); CHECK(c.state()==State::Unlocking); ++cases;
    // Seat/keymap/owner loss is still an explicit cancelling boundary, even if
    // output removal has already suspended input.
    AuthController abandoned(dir+"/fixture-delayed-success",1500,100); abandoned.setInputActive(true);
    CHECK(abandoned.append({secret,sizeof(secret)-1})); abandoned.setInputActive(false,true);
    abandoned.setInputActive(false); CHECK(abandoned.presentation().count==0 && abandoned.state()==AuthState::Cancelled); ++cases;
}
void successRaces(const std::string& dir) {
    for (int ordering=0;ordering<5;++ordering) {
        AuthController auth(dir+"/fixture-delayed-success",1500,100); Fake b; b.auth=&auth;
        Controller c(b); c.acquire(); c.locked(); add(c,1); add(c,2);
        auth.setInputActive(true); CHECK(auth.append({secret,sizeof(secret)-1})); CHECK(auth.submit());
        auto generation=auth.generation(); auto pid=AuthTestAccess::pid(auth);
        add(c,3); c.removeOutput(1); CHECK(auth.generation()==generation && AuthTestAccess::pid(auth)==pid);
        CHECK(!auth.submit());
        if (ordering==4) { b.render=true; b.invalidQml=2; c.refresh(); CHECK(c.outputs().at(2).fallback); CHECK(!c.outputs().at(3).fallback); }
        auth.succeeded=[&](auto g) {
            if (ordering==0) add(c,4);
            if (ordering==1) c.removeOutput(2);
            if (ordering==2) CHECK(c.configure(2,{2,800,600}));
            if (ordering==3) { b.results[2]=FrameResult::Deferred; CHECK(c.configure(2,{2,800,600})); }
            CHECK(!c.authenticatedUnlock(auth,g+1)); CHECK(c.authenticatedUnlock(auth,g));
            CHECK(!c.authenticatedUnlock(auth,g));
            auto paints=b.paints;
            CHECK(!c.configure(3,{20,1,1})); c.bufferAvailable(2); c.refresh();
            CHECK(c.addOutput(99)); CHECK(!b.surfaces.contains(99)); CHECK(b.paints==paints);
        };
        waitFor([&]{ return b.unlocks==1; }); CHECK(auth.generation()==generation && b.requests==1); ++cases;
    }
}
void failures(const std::string& dir) {
    for (const auto mode : {"failed","workererror","echoon","hang","crash","truncated","cancelled","delayed-success"}) {
        AuthController auth(dir+"/fixture-"+mode,std::string(mode)=="hang" ? 50 : 1500,500);
        Fake b; b.auth=&auth; Controller c(b); c.acquire(); c.locked(); add(c,1); add(c,2);
        auth.succeeded=[&](auto g) { c.authenticatedUnlock(auth,g); };
        auth.setInputActive(true); CHECK(auth.append({secret,sizeof(secret)-1})); CHECK(auth.submit());
        auto g=auth.generation(); auto pid=AuthTestAccess::pid(auth);
        add(c,3); c.removeOutput(1); CHECK(AuthTestAccess::pid(auth)==pid && auth.generation()==g);
        if (std::string(mode)=="delayed-success") auth.cancel();
        waitFor([&]{ return auth.state()!=AuthState::Authenticating; });
        const auto state=auth.state();
        const auto expected=std::string(mode)=="failed" ? AuthState::Failed :
            std::string(mode)=="echoon" ? AuthState::Unsupported :
            (std::string(mode)=="cancelled" || std::string(mode)=="delayed-success") ? AuthState::Cancelled : AuthState::WorkerError;
        CHECK(state==expected); add(c,4); c.removeOutput(2); auth.setInputActive(false,true); c.refresh();
        CHECK(auth.state()==state && auth.generation()==g && b.unlocks==0);
        CHECK(b.views.at(3).state==state && b.views.at(4).state==state);
        CHECK(!auth.submit()); CHECK(!c.authenticatedUnlock(auth,g));
        waitFor([&]{ return AuthTestAccess::pid(auth)==-1; }); CHECK(AuthTestAccess::retry(auth));
        add(c,5); c.removeOutput(3); CHECK(AuthTestAccess::retry(auth) && auth.state()==state);
        CHECK(c.state()==State::Locked && b.unlocks==0); ++cases;
    }
}
}
int main(int argc,char** argv) {
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software); QGuiApplication app(argc,argv);
    qInstallMessageHandler([](QtMsgType,const QMessageLogContext&,const QString& text){ logs+=text.toStdString(); });
    try {
        CHECK(argc==2); lifecycle(); geometryAndFailure(); presentationStates(argv[1]); focusAndEditing(argv[1]); successRaces(argv[1]); failures(argv[1]);
        CHECK(logs.find(secret)==std::string::npos);
    } catch(const std::exception& e) { std::cerr<<e.what()<<'\n'; return 1; }
    std::cout<<cases<<" synthetic multi-output scenarios passed; no Wayland connection or PAM\n";
}
