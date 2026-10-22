#pragma once
#include <array>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>

// Phase 11A: linked only into tests. No QObject, D-Bus, PAM or Wayland authority.
namespace magi::fingerprint {
enum class Capability { Unavailable, ReaderPresent, NoEnrollment, Enrolled, Busy, DaemonError };
enum class Attempt { Idle, Waiting, Scanning, Retry, Matched, Failed, Cancelled, DeviceLost, DaemonLost };
enum class Event : std::uint8_t { Ready=1, Scan, Retry, Match, NoMatch, Timeout, DeviceLost, DaemonLost, Busy, Error };
struct Binding {
    std::uint64_t lock, attempt;
    std::uint32_t uid;
    bool operator==(const Binding&) const = default;
};
struct Message { Binding binding; Event event; };
// Fixed 32-byte v1 little-endian datagram. Reserved bytes must be zero.
using Packet = std::array<std::uint8_t,32>;
Packet encode(Message message);
std::optional<Message> decode(std::span<const std::uint8_t> bytes);
std::optional<Event> verifyStatus(std::string_view status, bool done);
class Model {
public:
    Model(std::uint64_t lock, std::uint32_t uid) : binding_{lock,0,uid} {}
    void capability(Capability value) { capability_=value; if(value!=Capability::Enrolled) cancel(); }
    Capability capability() const { return capability_; }
    Attempt state() const { return state_; }
    Binding binding() const { return binding_; }
    bool start(bool secureLockReady);
    bool receive(std::span<const std::uint8_t> packet);
    void cancel();
    void invalidate(); // topology, sleep, daemon owner change, teardown
    // Native owner must separately require its current secure lock and policy gate.
    bool consume(Binding binding, bool secureLockReady);
private:
    Binding binding_;
    Capability capability_ = Capability::Unavailable;
    Attempt state_ = Attempt::Idle;
    bool active_ = false, ready_ = false, consumed_ = true, exhausted_ = false;
};
// Narrow deterministic replacement for fprintd; no access to system bus or storage.
class SyntheticBackend {
public:
    explicit SyntheticBackend(Model& model) : model_(model) {}
    bool start(bool secure) { if(!model_.start(secure)) return false; binding_=model_.binding(); return deliver(Event::Ready); }
    bool deliver(Event event) { return model_.receive(encode({binding_,event})); }
    bool status(std::string_view status, bool done) { auto event=verifyStatus(status,done); return deliver(event.value_or(Event::Error)); }
    void cancel() { model_.cancel(); }
    void resume(Capability capability) { model_.invalidate(); model_.capability(capability); }
private:
    Model& model_;
    Binding binding_{};
};
}
