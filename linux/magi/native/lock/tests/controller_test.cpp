#include "controller.hpp"
#include "options.hpp"
#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
using namespace magi;
#define CHECK(condition) do { if (!(condition)) throw std::runtime_error(\
    std::string(__FILE__) + ":" + std::to_string(__LINE__) + " " #condition); } while (false)
struct Fake final : Backend {
    bool requestOkay = true, surfaceOkay = true;
    FrameResult frameResult = FrameResult::Presented;
    int requests = 0, creates = 0, removes = 0, disconnects = 0, unlocks = 0;
    std::vector<Configure> commits;
    std::vector<std::string> events;
    bool requestLock() override { ++requests; events.emplace_back("request"); return requestOkay; }
    bool createSurface(uint32_t) override { ++creates; events.emplace_back("role"); return surfaceOkay; }
    void removeSurface(uint32_t) override { ++removes; events.emplace_back("surface removed"); }
    FrameResult present(uint32_t, Configure c) override {
        if (frameResult == FrameResult::Presented || frameResult == FrameResult::Fallback) {
            events.emplace_back("prepare"); events.emplace_back("ack");
            events.emplace_back("attach"); events.emplace_back("commit"); commits.push_back(c);
        }
        return frameResult;
    }
    void diagnostic(std::string_view) override {}
    void disconnect() override { ++disconnects; events.emplace_back("disconnect"); }
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    void developmentUnlockAndSync() override { ++unlocks; events.emplace_back("unsafe unlock"); }
#endif
};
void states() {
    Fake backend;
    {
        Controller c(backend);
        CHECK(c.state() == State::Idle && !c.confirmed());
        CHECK(!c.locked());
        CHECK(c.addOutput(7)); CHECK(!c.addOutput(7));
        CHECK(backend.creates == 0);
        CHECK(c.acquire()); CHECK(!c.acquire());
        CHECK(c.state() == State::Acquiring && !c.confirmed());
        CHECK(backend.requests == 1 && backend.creates == 1);
        CHECK(backend.events[0] == "request" && backend.events[1] == "role");
        CHECK(c.locked()); CHECK(!c.locked());
        CHECK(c.state() == State::Locked && c.confirmed());
        CHECK(!c.acquire());
        CHECK(backend.unlocks == 0);
    }
    CHECK(backend.disconnects == 1 && backend.unlocks == 0);
}
void outputs() {
    Fake b; Controller c(b);
    CHECK(c.acquire()); CHECK(c.locked()); // Zero outputs is allowed.
    CHECK(c.addOutput(90)); CHECK(c.addOutput(2)); CHECK(!c.addOutput(90));
    CHECK(b.creates == 2 && c.outputs().size() == 2);
    CHECK(c.configure(90, {11, 1920, 1080}));
    CHECK(c.outputs().at(90).committed == (Configure{11, 1920, 1080}));
    CHECK(c.removeOutput(90)); CHECK(!c.removeOutput(90));
    CHECK(!c.configure(90, {12, 1, 1}));
    c.bufferAvailable(90); // Late queued release after output deletion is safe.
    CHECK(c.state() == State::Locked && c.confirmed() && b.unlocks == 0);
    CHECK(c.addOutput(90)); CHECK(b.creates == 3); // Reused registry name, fresh lifetime.
    CHECK(c.removeOutput(2)); CHECK(c.removeOutput(90));
    CHECK(c.outputs().empty() && c.state() == State::Locked);
    c.cleanup(); c.cleanup(); CHECK(b.disconnects == 1);
    CHECK(!c.addOutput(5));
}
void configure() {
    Fake b; Controller c(b);
    c.addOutput(1);
    CHECK(!c.configure(1, {1, 640, 480}));
    CHECK(c.acquire());
    CHECK(c.configure(1, {0xffffffffu, 640, 480}));
    CHECK(!c.configure(1, {0xffffffffu, 640, 480}));
    CHECK(c.configure(1, {0, 1080, 1920})); // Serial wrap, transformed logical geometry.
    b.frameResult = FrameResult::Deferred;
    CHECK(c.configure(1, {5, 2560, 1440}));
    CHECK(c.configure(1, {8, 1920, 1080}));
    CHECK(!c.configure(1, {8, 1920, 1080}));
    CHECK(b.commits.size() == 2);
    CHECK(c.outputs().at(1).pending == (Configure{8, 1920, 1080}));
    b.frameResult = FrameResult::Presented;
    c.bufferAvailable(1);
    CHECK(b.commits.size() == 3 && b.commits.back().serial == 8);
    CHECK(!c.outputs().at(1).pending);
    CHECK(!c.configure(1, {9, 0, 1080}));
    CHECK(!c.outputs().at(1).surface && c.outputs().at(1).failed);
    CHECK(b.removes == 1 && b.unlocks == 0);
    CHECK(validGeometry({1, 3840, 2160}));
    CHECK(!validGeometry({1, 0xffffffffu, 0xffffffffu}));
    CHECK(!validGeometry({1, 16384, 16384}));
}
void failures() {
    for (auto result : {FrameResult::Fallback, FrameResult::Failed}) {
        Fake b; Controller c(b); c.addOutput(1); c.acquire(); c.locked();
        b.frameResult = result;
        CHECK(c.configure(1, {99, 800, 600}));
        CHECK(c.state() == State::Locked && c.confirmed());
        CHECK(b.unlocks == 0);
        if (result == FrameResult::Fallback) CHECK(c.outputs().at(1).fallback);
        else CHECK(c.outputs().at(1).failed && !c.outputs().at(1).surface);
        c.cleanup(); CHECK(b.unlocks == 0 && b.disconnects == 1);
    }
    Fake b; b.surfaceOkay = false;
    Controller c(b); CHECK(c.acquire()); CHECK(c.locked()); c.addOutput(1);
    CHECK(c.outputs().at(1).failed && b.unlocks == 0 && c.state() == State::Locked);
    c.finished(); CHECK(c.state() == State::Failed && c.confirmed());
    CHECK(!c.locked() && !c.acquire());
    c.cleanup(); CHECK(b.unlocks == 0);
    Fake denied; Controller d(denied); d.acquire(); d.finished();
    CHECK(d.state() == State::Failed && !d.confirmed()); CHECK(denied.unlocks == 0);
    Fake request; request.requestOkay = false; Controller e(request);
    CHECK(!e.acquire() && e.state() == State::Failed && request.unlocks == 0);
    Fake lost; Controller f(lost); f.acquire(); f.locked(); f.disconnected();
    CHECK(f.state() == State::Failed && lost.unlocks == 0);
}
Options parse(std::initializer_list<std::string_view> args) {
    return parseOptions({args.begin(), args.size()});
}
void gating() {
    CHECK(!parse({}).error.empty());
    CHECK(parse({"--help"}).error.empty());
    CHECK(parse({"--build-info"}).error.empty());
    CHECK(!parse({"--help", "--acquire-session-lock"}).error.empty());
    CHECK(!parse({"--acquire-session-lock", "--acquire-session-lock"}).error.empty());
    CHECK(!parse({"--unlock"}).error.empty());
    CHECK(!parse({"--unsafe-development-unlock-after=30"}).error.empty());
    CHECK(!parse({"--acquire-session-lock", "--unsafe-development-unlock-after=0"}).error.empty());
    CHECK(!parse({"--acquire-session-lock", "--unsafe-development-unlock-after=30x"}).error.empty());
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    CHECK(!parse({"--acquire-session-lock"}).error.empty());
    CHECK(parse({"--acquire-session-lock", "--unsafe-development-unlock-after=30"}).developmentSeconds == 30);
    CHECK(!parse({"--acquire-session-lock", "--unsafe-development-unlock-after=301"}).error.empty());
    Fake b; Controller c(b);
    CHECK(!c.developmentUnlock(true)); c.acquire(); CHECK(!c.developmentUnlock(true));
    c.locked(); CHECK(!c.developmentUnlock(false));
    CHECK(c.developmentUnlock(true)); CHECK(!c.developmentUnlock(true));
    CHECK(c.state() == State::Unlocking && b.unlocks == 1);
    CHECK(!c.locked()); CHECK(c.unlockSynced()); CHECK(!c.unlockSynced());
    CHECK(c.state() == State::Idle && !c.confirmed());
    CHECK(!c.acquire()); // Each owner/connection has exactly one lock generation.
    Fake failed; Controller f(failed); f.acquire(); f.locked(); f.fatal();
    CHECK(!f.developmentUnlock(true) && failed.unlocks == 0);
#else
    CHECK(parse({"--acquire-session-lock"}).error.empty());
    CHECK(!parse({"--acquire-session-lock", "--unsafe-development-unlock-after=30"}).error.empty());
#endif
}
int main() {
    try { states(); outputs(); configure(); failures(); gating(); }
    catch (const std::exception& error) { std::cerr << error.what() << '\n'; return EXIT_FAILURE; }
    std::cout << "Controller lifecycle, failure, geometry and gating tests passed (development="
              << MAGI_LOCK_DEVELOPMENT_UNLOCK << ")\n";
}
