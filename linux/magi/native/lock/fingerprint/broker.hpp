#pragma once
#include "model.hpp"
#include <QObject>
#include <QTimer>
#include <functional>
#include <string>
#include <systemd/sd-bus.h>
namespace magi { class Controller; }
namespace magi::fingerprint {
// One private system-bus connection per attempt. Never accepts UI results,
// usernames, daemon destinations or device paths. fprintd owns all biometrics.
class Broker final : public QObject {
public:
    explicit Broker();
    ~Broker() override;
    void start(); // Call only once the native session lock is secure.
    void cancel();
    bool quiescent() const { return bus_ == nullptr; }
    const char* status() const { return status_; }
    std::function<void()> changed;
    std::function<void(Binding)> succeeded;
private:
    friend class magi::Controller;
    friend struct BrokerTestAccess;
    bool consume(Binding binding, bool secure);
    enum class Step { Activate, Owner, Device, Enrollment, Claim, Subscribe, Verify, Waiting, Stop, Release };
    void attempt();
    void close();
    void fail(const char* status = "Fingerprint unavailable");
    void text(const char* status);
    void call(Step step, const char* destination, const char* path, const char* interface, const char* method, const char* argument = nullptr);
    void process();
    void reply(sd_bus_message* message);
    void signal(sd_bus_message* message);
    static int replied(sd_bus_message*, void*, sd_bus_error*);
    static int signalled(sd_bus_message*, void*, sd_bus_error*);
    Model model_;
    sd_bus* bus_ = nullptr;
    sd_bus_slot *pending_ = nullptr, *statusSlot_ = nullptr, *ownerSlot_ = nullptr;
    QTimer poll_, deadline_, retry_;
    std::string owner_, path_;
    Step step_ = Step::Activate;
    Event outcome_ = Event::Error;
    bool enabled_ = false, activationAttempted_ = false;
    const char* status_ = "";
};
}
