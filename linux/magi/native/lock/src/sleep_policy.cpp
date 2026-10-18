#include "sleep_policy.hpp"
namespace magi {
bool SleepPolicy::arm() {
    if (state_ != SleepState::Unarmed) return state_ == SleepState::Awake;
    if (coordinator_ == SleepCoordinator::Hypridle) {
        state_ = SleepState::Awake;
        return true; // Explicit delegation, never an acquisition-error fallback.
    }
    held_ = backend_.acquireDelay();
    state_ = held_ ? SleepState::Awake : SleepState::Error;
    if (!held_) backend_.quiesce();
    return held_;
}
void SleepPolicy::prepare(bool sleeping) {
    if (sleeping) {
        if (state_ != SleepState::Awake) return;
        state_ = SleepState::Preparing;
        backend_.quiesce(); // Blocks success/input and clears secrets before request.
        backend_.ensureLock();
        progress();
    } else {
        if (state_ == SleepState::Awake && coordinator_ == SleepCoordinator::Hypridle) {
            // The operation ended before startup, or this was an idle/manual
            // request through Hypridle. Protect the next sleep before editing.
            held_ = backend_.acquireDelay();
            if (!held_) { fail(); return; }
            coordinator_ = SleepCoordinator::Native;
            return;
        }
        if (state_ != SleepState::Preparing && state_ != SleepState::SecureForSleep) return;
        // Reacquire before allowing any fresh authentication. Failures stay blocked.
        if (!held_) held_ = backend_.acquireDelay();
        if (!held_) { fail(); return; }
        coordinator_ = SleepCoordinator::Native;
        state_ = SleepState::Awake;
        backend_.resumeInput();
    }
}
void SleepPolicy::progress() {
    if (state_ != SleepState::Preparing) return;
    if (!backend_.secureLockReady() || !backend_.authQuiescent()) return;
    state_ = SleepState::SecureForSleep;
    if (coordinator_ == SleepCoordinator::Native) {
        backend_.releaseDelay(); held_ = false;
    } else {
        backend_.coordinatedReady(); // Informational only: Hypridle owns its FD.
    }
}
void SleepPolicy::fail() {
    state_ = SleepState::Error;
    backend_.quiesce(); // Never turn failure/timeout into permission to sleep/unlock.
}
}
