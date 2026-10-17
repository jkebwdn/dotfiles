#include "auth_controller.hpp"
#include "native_input.hpp"
#include "controller.hpp"
#include <QCoreApplication>
#include <QElapsedTimer>
#include <QThread>
#include <QStringList>
#include <cassert>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <iostream>
#include <string>
#include <type_traits>
#include <xkbcommon/xkbcommon-keysyms.h>
using namespace magi;
namespace {
constexpr char synthetic[] = "MAGI_TEST_SECRET_7df1_CPP";
std::string logs;
void logger(QtMsgType, const QMessageLogContext&, const QString& message) { logs += message.toStdString(); logs += '\n'; }
#define CHECK(c) do { if (!(c)) { std::cerr << "Check failed at line " << __LINE__ << '\n'; std::abort(); } } while(false)
std::span<const char> secret() { return {synthetic, sizeof(synthetic)-1}; }
struct FakeLock final : Backend {
    int unlocks = 0, devUnlocks = 0, acknowledgements = 0, paints = 0;
    bool requestLock() override { return true; }
    bool createSurface(std::uint32_t) override { return true; }
    void removeSurface(std::uint32_t) override {}
    FrameResult present(std::uint32_t, Configure, bool ack) override { ++paints; acknowledgements += ack; return FrameResult::Presented; }
    void diagnostic(std::string_view) override {}
    void disconnect() override {}
    void authenticatedUnlockAndSync() override { ++unlocks; }
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    void developmentUnlockAndSync() override { ++devUnlocks; }
#endif
};
void until(const std::function<bool()>& predicate, int maximum = 4000) {
    QElapsedTimer clock; clock.start();
    while (!predicate() && clock.elapsed() < maximum) { QCoreApplication::processEvents(); QThread::msleep(2); }
    CHECK(predicate());
}
void buffer() {
    static_assert(!std::is_copy_constructible_v<Credential>);
    static_assert(!std::is_move_constructible_v<Credential>);
    Credential c;
    CHECK(!c.append({"\0",1})); CHECK(!c.append({"\xc0\xaf",2}));
    CHECK(!c.append({"\xed\xa0\x80",3})); CHECK(!c.append({"\x80",1}));
    CHECK(c.append({"a\xc3\xa9\xf0\x9f\x94\x92",7})); CHECK(c.units()==3);
    c.backspace(); CHECK(c.units()==2 && c.bytes().size()==3);
    c.backspace(); CHECK(c.units()==1 && c.bytes().size()==1);
    auto retained = c.bytes(); c.clear(); CHECK(c.empty() && c.units()==0);
    CHECK(retained[0]==0);
    char full[Credential::capacity]; std::memset(full,'x',sizeof(full));
    CHECK(c.append(full)); CHECK(!c.append({"y",1})); CHECK(c.units()==511);
    c.clear(); CHECK(c.empty());
    // Inspect live raw storage after destruction of an explicitly placed object.
    alignas(Credential) unsigned char memory[sizeof(Credential)];
    auto* placed = new(memory) Credential;
    CHECK(placed->append(secret())); auto bytes=placed->bytes(); auto* start=bytes.data(); auto n=bytes.size();
    placed->~Credential();
    for (std::size_t i=0; i<n; ++i) CHECK(reinterpret_cast<const unsigned char*>(start)[i]==0);
}
void keyboard() {
    AuthController auth("/does/not/exist",100,10); NativeInput input(auth);
    auto* context=xkb_context_new(XKB_CONTEXT_NO_FLAGS);
    xkb_rule_names names{}; names.layout="gb";
    auto* map=xkb_keymap_new_from_names(context,&names,XKB_KEYMAP_COMPILE_NO_FLAGS);
    CHECK(map); char* text=xkb_keymap_get_as_string(map,XKB_KEYMAP_FORMAT_TEXT_V1);
    CHECK(input.keymap({text,std::strlen(text)+1})); free(text);
    auto stroke=[&](unsigned evdev) { input.key(evdev,true); input.key(evdev,false); };
    stroke(30); CHECK(auth.presentation().count==0); // No focus
    input.focus(true); input.modifiers(0,0,0,0);
    stroke(28); CHECK(auth.generation()==0); // Empty Enter
    stroke(30); CHECK(auth.presentation().count==1);
    input.key(30,true); input.key(30,true); CHECK(auth.presentation().count==2); input.key(30,false);
    stroke(14); CHECK(auth.presentation().count==1); // Backspace
    stroke(1); CHECK(auth.presentation().count==0); // Escape, no unlock
    auto ctrl=1u<<xkb_keymap_mod_get_index(map,XKB_MOD_NAME_CTRL);
    auto shift=1u<<xkb_keymap_mod_get_index(map,XKB_MOD_NAME_SHIFT);
    auto caps=1u<<xkb_keymap_mod_get_index(map,XKB_MOD_NAME_CAPS);
    input.modifiers(ctrl,0,0,0); stroke(47); CHECK(auth.presentation().count==0); // Ctrl-V
    input.modifiers(shift,0,0,0); stroke(110); CHECK(auth.presentation().count==0); // Shift-Insert
    input.modifiers(0,0,caps,0); CHECK(auth.presentation().caps);
    stroke(30); CHECK(auth.presentation().count==1);
    input.modifiers(ctrl,0,0,0); stroke(22); CHECK(auth.presentation().count==0); // Ctrl-U
    input.modifiers(0,0,0,0); CHECK(!auth.presentation().caps);
    stroke(30); stroke(28); CHECK(auth.state()==AuthState::WorkerError && auth.presentation().count==0); // Spawn error clears
    input.focus(false); CHECK(auth.presentation().count==0);
    xkb_keymap_unref(map); xkb_context_unref(context);
}
std::string fixture(const std::string& directory, const char* mode) { return directory+"/fixture-"+mode; }
void attempts(const std::string& dir) {
    for (const char* mode : {"success","failed","pamerror","crash","exitonly","hang","version","truncated","oversize","unknown","wrongid","zero-success","echoon","secondprompt","badexit","extraframe"}) {
        FakeLock backend; Controller lock(backend); CHECK(lock.acquire()); CHECK(lock.locked());
        AuthController auth(fixture(dir,mode),std::string(mode)=="hang" ? 50 : 2000,30);
        int successCallbacks=0;
        auth.succeeded=[&](auto generation) {
            ++successCallbacks;
            CHECK(!lock.authenticatedUnlock(auth,generation+1));
            CHECK(lock.authenticatedUnlock(auth,generation));
            CHECK(!lock.authenticatedUnlock(auth,generation));
        };
        auth.setInputActive(true); CHECK(auth.append(secret()));
        CHECK(auth.submit()); CHECK(!auth.submit()); CHECK(!auth.append(secret()));
        until([&] { return auth.state()!=AuthState::Authenticating; });
        // Error/cancel may still be reaping; no next worker until both reap and delay.
        if (std::string(mode)=="success") {
            CHECK(auth.state()==AuthState::Succeeded && successCallbacks==1 && backend.unlocks==1);
            CHECK(lock.state()==State::Unlocking); CHECK(lock.unlockSynced()); CHECK(!lock.unlockSynced());
        } else {
            CHECK(backend.unlocks==0 && successCallbacks==0 && lock.state()==State::Locked);
            if (std::string(mode)=="failed") CHECK(auth.state()==AuthState::Failed);
            if (std::string(mode)=="echoon" || std::string(mode)=="secondprompt") CHECK(auth.state()==AuthState::Unsupported);
        }
        CHECK(auth.presentation().count==0);
    }
}
void staleAndRetry(const std::string& dir) {
    FakeLock backend; Controller lock(backend); lock.acquire(); lock.locked();
    AuthController auth(fixture(dir,"success"),2000,10); auth.setInputActive(true);
    CHECK(auth.append(secret())); CHECK(auth.submit()); const auto old=auth.generation();
    until([&] { return auth.state()==AuthState::Succeeded; });
    auth.cancel(); CHECK(!lock.authenticatedUnlock(auth,old));
    until([&] { return auth.state()==AuthState::Editing; });
    CHECK(auth.append(secret())); CHECK(auth.submit());
    CHECK(!lock.authenticatedUnlock(auth,old));
    until([&] { return auth.state()==AuthState::Succeeded; });
    CHECK(!lock.authenticatedUnlock(auth,old));
    CHECK(lock.authenticatedUnlock(auth,auth.generation())); CHECK(backend.unlocks==1);
    AuthController failed(fixture(dir,"failed"),2000,10); failed.setInputActive(true);
    CHECK(failed.append(secret())); CHECK(failed.submit());
    until([&] { return failed.state()==AuthState::Failed; }); CHECK(!failed.submit());
    until([&] { return failed.state()==AuthState::Editing; });
    CHECK(failed.append(secret())); CHECK(failed.submit()); failed.cancel();
    CHECK(failed.presentation().count==0 && !lock.authenticatedUnlock(failed,failed.generation()));
    until([&] { return failed.state()==AuthState::Editing; });
    FakeLock acquiring; Controller notLocked(acquiring); notLocked.acquire();
    CHECK(!notLocked.authenticatedUnlock(auth,auth.generation()));
}
void nativeKeysToRust(const std::string& dir) {
    FakeLock backend; Controller lock(backend); lock.acquire(); lock.locked();
    AuthController auth(fixture(dir,"success"),2000,10); NativeInput input(auth);
    auto* context=xkb_context_new(XKB_CONTEXT_NO_FLAGS);
    xkb_rule_names names{}; names.layout="gb";
    auto* map=xkb_keymap_new_from_names(context,&names,XKB_KEYMAP_COMPILE_NO_FLAGS);
    CHECK(map); auto* text=xkb_keymap_get_as_string(map,XKB_KEYMAP_FORMAT_TEXT_V1);
    CHECK(input.keymap({text,std::strlen(text)+1})); free(text); input.focus(true);
    auto shift=1u<<xkb_keymap_mod_get_index(map,XKB_MOD_NAME_SHIFT);
    for (char byte : secret()) {
        const auto expected=xkb_utf32_to_keysym(static_cast<unsigned char>(byte));
        bool found=false;
        for (unsigned key=8; key<256 && !found; ++key) for (unsigned level=0; level<2 && !found; ++level) {
            const xkb_keysym_t* symbols=nullptr;
            int n=xkb_keymap_key_get_syms_by_level(map,key,0,level,&symbols);
            if (n==1 && symbols[0]==expected) {
                input.modifiers(level ? shift : 0,0,0,0);
                input.key(key-8,true); input.key(key-8,false); found=true;
            }
        }
        CHECK(found);
    }
    CHECK(auth.presentation().count==secret().size());
    auth.succeeded=[&](auto generation) { CHECK(lock.authenticatedUnlock(auth,generation)); };
    input.modifiers(0,0,0,0); input.key(28,true); input.key(28,false);
    until([&] { return backend.unlocks==1; }); CHECK(auth.presentation().count==0);
    xkb_keymap_unref(map); xkb_context_unref(context);
}
void cancellationAndTimeout(const std::string& dir) {
    for (bool cancel : {true,false}) {
        FakeLock backend; Controller lock(backend); lock.acquire(); lock.locked();
        AuthController auth(fixture(dir,"hang"),50,10); auth.setInputActive(true);
        CHECK(auth.append(secret())); CHECK(auth.submit());
        if (cancel) auth.cancel();
        until([&] { return auth.state()==AuthState::Editing; });
        CHECK(auth.presentation().count==0 && backend.unlocks==0);
        CHECK(!lock.authenticatedUnlock(auth,auth.generation()));
    }
}
void repaintAndEmergency() {
    FakeLock backend; Controller lock(backend); lock.addOutput(1); lock.acquire(); lock.locked();
    lock.configure(1,{9,800,600}); lock.refresh(); lock.refresh();
    CHECK(backend.acknowledgements==1 && backend.paints==3 && backend.unlocks==0);
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    CHECK(!lock.developmentUnlock(false)); CHECK(backend.devUnlocks==0);
    CHECK(lock.developmentUnlock(true)); CHECK(!lock.developmentUnlock(true)); CHECK(backend.devUnlocks==1);
#endif
}
}
int main(int argc,char** argv) {
    QCoreApplication app(argc,argv); CHECK(argc==2);
    qInstallMessageHandler(logger);
    buffer(); keyboard(); attempts(argv[1]); staleAndRetry(argv[1]); nativeKeysToRust(argv[1]); cancellationAndTimeout(argv[1]); repaintAndEmergency();
    CHECK(logs.find(synthetic)==std::string::npos);
    CHECK(logs.find("PAM PromptEchoOff")!=std::string::npos);
    std::cout << "Native buffer/input, Rust IPC fixtures, authorization, stale-result, retry, cleanup and log leakage checks passed\n";
}
