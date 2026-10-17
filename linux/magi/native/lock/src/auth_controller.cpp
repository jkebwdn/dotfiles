#include "auth_controller.hpp"
#include <QDebug>
#include <array>
#include <cerrno>
#include <cstring>
#include <csignal>
#include <fcntl.h>
#include <spawn.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <unistd.h>
namespace magi {
namespace {
struct Frame {
    std::array<unsigned char, 524> data{};
    ~Frame() { explicit_bzero(data.data(), data.size()); }
};
}
const char* authStateName(AuthState s) {
    switch (s) {
    case AuthState::Idle: return "Locked";
    case AuthState::Editing: return "Enter password, then Enter";
    case AuthState::Authenticating: return "Authenticating";
    case AuthState::Failed: return "Authentication failed";
    case AuthState::WorkerError: return "Authentication unavailable";
    case AuthState::Unsupported: return "Unsupported PAM conversation";
    case AuthState::Cancelled: return "Cancelled";
    case AuthState::Succeeded: return "Authentication succeeded";
    }
    return "Authentication unavailable";
}
AuthController::AuthController(std::string worker, int timeout, int retry)
    : worker_(std::move(worker)), timeoutMs_(timeout), retryMs_(retry) {
    retry_.setSingleShot(true);
    connect(&retry_, &QTimer::timeout, this, [this] {
        if (pid_ < 0 && state_ != AuthState::Succeeded) { state_ = active_ ? AuthState::Editing : AuthState::Idle; notify(); }
    });
}
AuthController::~AuthController() {
    poller_.stop(); retry_.stop(); credential_.clear();
    if (fd_ >= 0) close(fd_);
    if (pid_ > 0) {
        kill(pid_, SIGKILL);
        while (waitpid(pid_, nullptr, 0) < 0 && errno == EINTR) {}
    }
}
void AuthController::notify() { if (changed) changed(); }
AuthPresentation AuthController::presentation() const {
    return {static_cast<unsigned>(credential_.units()), active_ && editable(), caps_, state_};
}
bool AuthController::editable() const {
    return pid_ < 0 && !retry_.isActive() && (state_ == AuthState::Idle || state_ == AuthState::Editing);
}
void AuthController::setInputActive(bool active) {
    if (active_ == active) return;
    active_ = active;
    if (!active) cancel();
    else if (editable()) state_ = AuthState::Editing;
    notify();
}
void AuthController::setCaps(bool caps) { if (caps_ != caps) { caps_ = caps; notify(); } }
bool AuthController::append(std::span<const char> text) {
    if (!active_ || !editable() || !credential_.append(text)) return false;
    state_ = AuthState::Editing; notify(); return true;
}
void AuthController::backspace() { if (active_ && editable()) { credential_.backspace(); notify(); } }
void AuthController::clear() {
    credential_.clear();
    if (pid_ > 0 || state_ == AuthState::Succeeded) cancel();
    else notify();
}
bool AuthController::submit() {
    if (!active_ || !editable() || credential_.empty()) return false;
    if (generation_ == UINT64_MAX) { credential_.clear(); state_ = AuthState::WorkerError; notify(); return false; }
    ++generation_;
    hello_ = sent_ = stopping_ = eof_ = reaped_ = cleanExit_ = consumed_ = false;
    result_.reset(); nextId_ = 1;
    state_ = AuthState::Authenticating;
    if (!spawn()) { credential_.clear(); state_ = AuthState::WorkerError; retry_.start(retryMs_); notify(); return false; }
    elapsed_.start();
    QObject::disconnect(&poller_, nullptr, this, nullptr);
    const auto current = generation_;
    connect(&poller_, &QTimer::timeout, this, [this, current] { poll(current); });
    poller_.start(10);
    qInfo("Auth attempt started"); notify(); return true;
}
bool AuthController::spawn() {
    if (getuid() == 0 || getuid() != geteuid() || getgid() != getegid()
        || worker_.empty() || worker_.front() != '/' || access(worker_.c_str(), X_OK)) return false;
    int pair[2];
    if (socketpair(AF_UNIX, SOCK_SEQPACKET | SOCK_CLOEXEC, 0, pair)) return false;
    // Duplicate above stdio/FD3 before file actions, even if stdio was closed.
    int childFd = fcntl(pair[1], F_DUPFD_CLOEXEC, 4);
    close(pair[1]);
    if (childFd < 0) { close(pair[0]); return false; }
    posix_spawn_file_actions_t actions;
    posix_spawnattr_t attributes;
    if (posix_spawn_file_actions_init(&actions)) { close(childFd); close(pair[0]); return false; }
    if (posix_spawnattr_init(&attributes)) { posix_spawn_file_actions_destroy(&actions); close(childFd); close(pair[0]); return false; }
    int error = posix_spawn_file_actions_adddup2(&actions, childFd, 3);
    for (int fd = 0; fd <= 2; ++fd) error |= posix_spawn_file_actions_addopen(&actions, fd, "/dev/null", O_RDWR, 0);
    error |= posix_spawn_file_actions_addclosefrom_np(&actions, 4);
    sigset_t mask, defaults;
    sigemptyset(&mask); sigemptyset(&defaults);
    for (int signal : {SIGINT, SIGTERM, SIGUSR1, SIGALRM, SIGPIPE}) sigaddset(&defaults, signal);
    error |= posix_spawnattr_setsigmask(&attributes, &mask);
    error |= posix_spawnattr_setsigdefault(&attributes, &defaults);
    error |= posix_spawnattr_setflags(&attributes, POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_SETSIGDEF);
    char arg1[] = "--ipc-fd=3", arg2[] = "--one-attempt";
    char path[] = "PATH=/usr/bin", lang[] = "LANG=C";
    char* args[] = {worker_.data(), arg1, arg2, nullptr};
    char* env[] = {path, lang, nullptr};
    pid_t child = -1;
    if (!error) error = posix_spawn(&child, worker_.c_str(), &actions, &attributes, args, env);
    posix_spawn_file_actions_destroy(&actions); posix_spawnattr_destroy(&attributes); close(childFd);
    if (error) { close(pair[0]); return false; }
    fd_ = pair[0]; pid_ = child;
    qInfo() << "Auth worker spawned PID" << pid_;
    return true;
}
bool AuthController::send(unsigned kind, unsigned id, std::span<const char> payload) {
    if (payload.size() > 511 || fd_ < 0) return false;
    Frame frame;
    auto& b = frame.data;
    std::memcpy(b.data(), "MAG3", 4); b[4] = 1; b[5] = kind;
    b[6] = id >> 8; b[7] = id;
    b[10] = payload.size() >> 8; b[11] = payload.size();
    if (!payload.empty()) std::memcpy(b.data()+12, payload.data(), payload.size());
    return ::send(fd_, b.data(), 12+payload.size(), MSG_NOSIGNAL | MSG_DONTWAIT) == ssize_t(12+payload.size());
}
void AuthController::receive() {
    // Bounded work per event-loop turn; no nested event loops or blocking reads.
    for (int i = 0; i < 8 && !stopping_ && !eof_; ++i) {
        Frame frame;
        auto& b = frame.data;
        auto n = recv(fd_, b.data(), b.size(), MSG_DONTWAIT | MSG_TRUNC);
        if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)) return;
        if (n == 0) { eof_ = true; if (!result_) stop(AuthState::WorkerError); return; }
        if (n < 12 || n > ssize_t(b.size()) || std::memcmp(b.data(), "MAG3", 4) || b[4] != 1 || result_) { stop(AuthState::WorkerError); return; }
        const auto id = (unsigned(b[6]) << 8) | b[7];
        const auto len = (std::uint32_t(b[8]) << 24) | (std::uint32_t(b[9]) << 16) | (unsigned(b[10]) << 8) | b[11];
        if (len > 512 || n != 12 + ssize_t(len)) { stop(AuthState::WorkerError); return; }
        if (!hello_) {
            if (b[5] != 1 || id || len || !send(2, 0)) { stop(AuthState::WorkerError); return; }
            hello_ = true; continue;
        }
        if (b[5] == 8) {
            if (id || len != 1 || b[12] > 5 || (b[12] == 0 && !sent_)) { stop(AuthState::WorkerError); return; }
            credential_.clear(); result_ = b[12]; continue;
        }
        if (id != nextId_ || nextId_ > 64) { stop(AuthState::WorkerError); return; }
        ++nextId_;
        switch (b[5]) {
        case 3:
            qInfo("PAM PromptEchoOff");
            if (sent_ || credential_.empty()) { stop(AuthState::Unsupported); return; }
            sent_ = true;
            {
                const bool okay = send(7, id, credential_.bytes());
                credential_.clear(); notify();
                if (!okay) { stop(AuthState::WorkerError); return; }
            }
            break;
        case 4:
            qInfo("PAM PromptEchoOn");
            // Identity is preset by worker. Text alone cannot securely identify
            // arbitrary echo-on semantics; never guess or expose editing to QML.
            stop(AuthState::Unsupported); return;
        case 5: case 6:
            qInfo(b[5] == 5 ? "PAM Info" : "PAM Error");
            if (!send(10, id)) { stop(AuthState::WorkerError); return; }
            break;
        default: stop(AuthState::WorkerError); return;
        }
    }
}
void AuthController::stop(AuthState state) {
    credential_.clear(); consumed_ = true;
    state_ = state;
    if (pid_ > 0 && !stopping_) {
        send(9, 0); // Best effort: do not wait for a hung peer to read Cancel.
        stopping_ = true; stoppingTime_.start();
    }
    notify();
}
void AuthController::cancel() {
    credential_.clear(); consumed_ = true;
    if (pid_ > 0) stop(AuthState::Cancelled);
    else if (state_ != AuthState::Idle) { state_ = AuthState::Cancelled; retry_.start(retryMs_); notify(); }
}
void AuthController::poll(std::uint64_t generation) {
    if (generation != generation_ || pid_ < 0) return;
    if (!stopping_ && elapsed_.elapsed() >= timeoutMs_) stop(AuthState::WorkerError);
    if (!stopping_) receive();
    if (stopping_ && !reaped_ && stoppingTime_.elapsed() >= 2000) kill(pid_, SIGKILL);
    if (!reaped_) {
        int status = 0;
        const auto rc = waitpid(pid_, &status, WNOHANG);
        if (rc == pid_) { reaped_ = true; cleanExit_ = WIFEXITED(status) && WEXITSTATUS(status) == 0; }
        else if (rc < 0 && errno != EINTR) { reaped_ = true; cleanExit_ = false; stop(AuthState::WorkerError); }
    }
    if (reaped_ && !stopping_) receive(); // Drain bytes queued just before exit.
    if (reaped_ && !stopping_ && (!cleanExit_ || !result_)) stop(AuthState::WorkerError);
    if (reaped_ && (stopping_ || (result_ && eof_))) finish();
}
void AuthController::finish() {
    poller_.stop(); close(fd_); fd_ = -1; pid_ = -1; credential_.clear();
    if (!stopping_) {
        if (*result_ == 0 && cleanExit_) state_ = AuthState::Succeeded;
        else if (*result_ == 1) state_ = AuthState::Failed;
        else if (*result_ == 2) state_ = AuthState::Cancelled;
        else state_ = AuthState::WorkerError;
    }
    qInfo() << "Auth worker reaped;" << authStateName(state_);
    const auto generation = generation_;
    if (state_ != AuthState::Succeeded) retry_.start(retryMs_);
    notify();
    if (state_ == AuthState::Succeeded && succeeded) succeeded(generation);
}
bool AuthController::consumeSuccess(std::uint64_t generation) {
    if (generation != generation_ || state_ != AuthState::Succeeded || consumed_ || pid_ > 0 || !cleanExit_ || !result_ || *result_ != 0 || !eof_) return false;
    consumed_ = true; return true;
}
}
