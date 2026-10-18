#pragma once
namespace magi {
enum class SleepState { Unarmed, Awake, Preparing, SecureForSleep, Error };
enum class SleepCoordinator { Native, Hypridle };
class SleepBackend {
public:
    virtual ~SleepBackend() = default;
    virtual bool acquireDelay() = 0;
    virtual void releaseDelay() = 0;
    virtual void ensureLock() = 0;
    virtual bool secureLockReady() const = 0;
    virtual void quiesce() = 0;
    virtual bool authQuiescent() const = 0;
    virtual void resumeInput() = 0;
    virtual void coordinatedReady() = 0;
};
// No wall-clock guesses: readiness is compositor confirmation AND worker reap.
// Native deadline failure retains the FD; delegation never owns/releases the
// external FD. logind may still expire either owner's finite delay.
class SleepPolicy {
public:
    explicit SleepPolicy(SleepBackend& backend, SleepCoordinator coordinator = SleepCoordinator::Native)
        : backend_(backend), coordinator_(coordinator) {}
    bool arm();
    void prepare(bool sleeping);
    void progress();
    void fail();
    SleepState state() const { return state_; }
    bool held() const { return held_; }
    SleepCoordinator coordinator() const { return coordinator_; }
private:
    SleepBackend& backend_;
    SleepCoordinator coordinator_;
    SleepState state_ = SleepState::Unarmed;
    bool held_ = false;
};
}
