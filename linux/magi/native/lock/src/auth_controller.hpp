#pragma once
#include "credential.hpp"
#include <QObject>
#include <QTimer>
#include <QElapsedTimer>
#include <cstdint>
#include <functional>
#include <optional>
#include <string>
#include <sys/types.h>
namespace magi {
class Controller;
enum class AuthState { Idle, Editing, Authenticating, Failed, WorkerError, Unsupported, Cancelled, Succeeded };
const char* authStateName(AuthState state);
// Only this value object crosses the presentation boundary, never the controller.
struct AuthPresentation { unsigned count = 0; bool active = false; bool caps = false; AuthState state = AuthState::Idle; };
class AuthController final : public QObject {
public:
    explicit AuthController(std::string worker, int timeoutMs = 120000, int retryMs = 1500);
    ~AuthController() override;
    // Output focus changes suspend input without cancelling the one session attempt.
    void setInputActive(bool active, bool preserveAuth = false);
    void setCaps(bool caps);
    bool append(std::span<const char> text);
    void backspace();
    void clear();
    bool submit();
    void cancel();
    AuthPresentation presentation() const;
    AuthState state() const { return state_; }
    std::uint64_t generation() const { return generation_; }
    std::function<void()> changed;
    std::function<void(std::uint64_t)> succeeded;
private:
    friend class Controller;
    friend struct AuthTestAccess; // Tests inspect cleanup flags, never export secrets.
    void clearCredential();
    bool consumeSuccess(std::uint64_t generation);
    bool spawn();
    bool send(unsigned kind, unsigned id, std::span<const char> payload = {});
    void poll(std::uint64_t generation);
    void receive();
    void stop(AuthState result, const char* diagnostic = "WORKER ERROR");
    void finish();
    void notify();
    bool editable() const;
    Credential credential_;
    std::string worker_;
    QTimer poller_, retry_;
    QElapsedTimer elapsed_, stoppingTime_;
    int timeoutMs_, retryMs_, fd_ = -1;
    pid_t pid_ = -1;
    std::uint64_t generation_ = 0;
    unsigned nextId_ = 1;
    AuthState state_ = AuthState::Idle;
    bool active_ = false, caps_ = false, hello_ = false, sent_ = false;
    bool stopping_ = false, eof_ = false, reaped_ = false, cleanExit_ = false, consumed_ = false;
    std::optional<unsigned> result_;
};
}
