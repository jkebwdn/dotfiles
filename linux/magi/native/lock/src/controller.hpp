#pragma once
#include <cstdint>
#include <map>
#include <optional>
#include <string_view>

namespace magi {
class AuthController;
enum class State { Idle, Acquiring, Locked, Unlocking, Failed };
std::string_view stateName(State state);
struct Configure {
    std::uint32_t serial, width, height;
    bool operator==(const Configure&) const = default;
};
// Dimensions are surface-local; native buffers use scale 1, normal transform.
bool validGeometry(const Configure& configure);
enum class FrameResult { Presented, Fallback, Deferred, Failed };
struct Output {
    bool surface = false;
    bool fallback = false;
    bool failed = false;
    bool dirty = false;
    std::optional<Configure> pending;
    std::optional<Configure> committed;
};
class Backend {
public:
    virtual ~Backend() = default;
    virtual bool requestLock() = 0;
    virtual bool createSurface(std::uint32_t output) = 0;
    virtual void removeSurface(std::uint32_t output) = 0;
    // Must prepare content, then ack this configure, attach non-null buffer,
    // and commit. Deferred/Failed must NOT ack or commit.
    virtual FrameResult present(std::uint32_t output, Configure configure, bool acknowledge = true) = 0;
    virtual void diagnostic(std::string_view message) = 0;
    virtual void authenticatedUnlockAndSync() = 0;
    virtual void disconnect() = 0; // Never protocol unlock.
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    virtual void developmentUnlockAndSync() = 0;
#endif
};
class Controller {
public:
    explicit Controller(Backend& backend) : backend_(backend) {}
    ~Controller();
    Controller(const Controller&) = delete;
    Controller& operator=(const Controller&) = delete;
    State state() const { return state_; }
    bool confirmed() const { return confirmed_; }
    const std::map<std::uint32_t, Output>& outputs() const { return outputs_; }
    bool acquire();
    bool locked();
    void finished();
    void fatal();
    void disconnected();
    void cleanup();
    bool addOutput(std::uint32_t id);
    bool removeOutput(std::uint32_t id);
    bool configure(std::uint32_t id, Configure configure);
    void bufferAvailable(std::uint32_t id);
    void refresh();
    bool authenticatedUnlock(AuthController& auth, std::uint64_t generation);
    bool unlockSynced();
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    bool developmentUnlock(bool explicitlyEnabled);
#endif
private:
    void ensureSurface(std::uint32_t id, Output& output);
    void draw(std::uint32_t id, Output& output);
    Backend& backend_;
    State state_ = State::Idle;
    bool confirmed_ = false;
    bool cleaned_ = false;
    bool requested_ = false;
    std::map<std::uint32_t, Output> outputs_;
};
}
