#include "controller.hpp"
#include "auth_controller.hpp"
namespace magi {
std::string_view stateName(State state) {
    switch (state) {
    case State::Idle: return "Idle";
    case State::Acquiring: return "Acquiring";
    case State::Locked: return "Locked";
    case State::Unlocking: return "Unlocking";
    case State::Failed: return "Failed";
    }
    return "Invalid";
}
bool validGeometry(const Configure& c) {
    // At most 64 MiB per frame. Oversize leaves compositor fallback, not a
    // truncated surface. Avoid multiplication/stride/Wayland signed overflow.
    return c.width > 0 && c.height > 0 && c.width <= 16384 && c.height <= 16384
        && std::uint64_t(c.width) * c.height * 4 <= 64 * 1024 * 1024;
}
Controller::~Controller() { cleanup(); }
bool Controller::acquire() {
    if (state_ != State::Idle || cleaned_ || requested_) return false;
    requested_ = true;
    state_ = State::Acquiring;
    if (!backend_.requestLock()) { fatal(); return false; }
    for (auto& [id, output] : outputs_) ensureSurface(id, output);
    return true;
}
bool Controller::locked() {
    if (state_ != State::Acquiring) return false;
    confirmed_ = true;
    state_ = State::Locked;
    return true;
}
void Controller::finished() {
    // Compositor retirement is not authentication. Disconnect instead of
    // sending an unlock from generic failure handling (including after locked).
    fatal();
}
void Controller::fatal() {
    state_ = State::Failed;
    backend_.diagnostic("Failed; no unlock requested; compositor protection may remain");
}
void Controller::disconnected() { fatal(); }
void Controller::cleanup() {
    if (cleaned_) return;
    cleaned_ = true;
    if (state_ != State::Idle) state_ = State::Failed;
    // Backend closes connection and locally destroys proxies, never sends an
    // invalid lock.destroy or unlock_and_destroy. No state-dependent release.
    backend_.disconnect();
    outputs_.clear();
}
bool Controller::addOutput(std::uint32_t id) {
    if (cleaned_) return false;
    auto [it, added] = outputs_.try_emplace(id);
    if (!added) return false;
    if (state_ == State::Acquiring || state_ == State::Locked)
        ensureSurface(id, it->second);
    return true;
}
bool Controller::removeOutput(std::uint32_t id) {
    auto it = outputs_.find(id);
    if (it == outputs_.end()) return false;
    if (it->second.surface) backend_.removeSurface(id);
    outputs_.erase(it);
    return true;
}
void Controller::ensureSurface(std::uint32_t id, Output& output) {
    if (output.surface || output.failed) return;
    output.surface = backend_.createSurface(id);
    if (!output.surface) {
        output.failed = true;
        backend_.diagnostic("Output surface unavailable; retaining lock, compositor fallback required");
    }
}
bool Controller::configure(std::uint32_t id, Configure c) {
    if (state_ != State::Acquiring && state_ != State::Locked) return false;
    auto it = outputs_.find(id);
    if (it == outputs_.end() || !it->second.surface) return false;
    auto& output = it->second;
    if (!validGeometry(c)) {
        output.failed = true;
        output.pending.reset();
        // Remove stale-sized content: active output must become compositor
        // fallback. Never attach null or recreate a duplicate output role.
        backend_.removeSurface(id);
        output.surface = false;
        backend_.diagnostic("Invalid/oversize configure; compositor fallback required");
        return false;
    }
    // Serials are opaque uint32 values and may wrap. Never sort numerically.
    if ((output.committed && output.committed->serial == c.serial)
        || (output.pending && output.pending->serial == c.serial)) return false;
    output.pending = c; // Unacked older configure is superseded.
    draw(id, output);
    return true;
}
void Controller::draw(std::uint32_t id, Output& output) {
    if (!output.surface || output.failed || (!output.pending && !(output.dirty && output.committed))) return;
    const bool acknowledge = output.pending.has_value();
    const auto result = backend_.present(id, acknowledge ? *output.pending : *output.committed, acknowledge);
    if (result == FrameResult::Deferred) return;
    if (result == FrameResult::Failed) {
        output.failed = true;
        output.pending.reset();
        backend_.removeSurface(id);
        output.surface = false;
        backend_.diagnostic("Buffer/presentation unavailable; compositor fallback required");
        return;
    }
    output.fallback = result == FrameResult::Fallback;
    if (acknowledge) output.committed = output.pending;
    output.pending.reset();
    output.dirty = false;
}
void Controller::refresh() {
    if (state_ != State::Acquiring && state_ != State::Locked) return;
    for (auto& [id, output] : outputs_) { output.dirty = true; draw(id, output); }
}
void Controller::bufferAvailable(std::uint32_t id) {
    if (state_ != State::Acquiring && state_ != State::Locked) return;
    auto it = outputs_.find(id);
    if (it != outputs_.end()) draw(id, it->second);
}
bool Controller::authenticatedUnlock(AuthController& auth, std::uint64_t generation) {
    if (state_ != State::Locked || !confirmed_ || cleaned_ || !auth.consumeSuccess(generation)) return false;
    state_ = State::Unlocking;
    backend_.authenticatedUnlockAndSync();
    return true;
}
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
bool Controller::developmentUnlock(bool enabled) {
    if (!enabled || state_ != State::Locked || !confirmed_) return false;
    state_ = State::Unlocking;
    backend_.developmentUnlockAndSync();
    return true;
}
#endif
bool Controller::unlockSynced() {
    if (state_ != State::Unlocking) return false;
    state_ = State::Idle;
    confirmed_ = false;
    return true;
}
}
