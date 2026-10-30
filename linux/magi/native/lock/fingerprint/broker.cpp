#include "broker.hpp"
#include <unistd.h>
#include <cstring>
namespace magi::fingerprint {
namespace {
constexpr auto service = "net.reactivated.Fprint";
constexpr auto manager = "/net/reactivated/Fprint/Manager";
constexpr auto device = "net.reactivated.Fprint.Device";
constexpr auto dbus = "org.freedesktop.DBus";
constexpr auto dbusPath = "/org/freedesktop/DBus";
}
Broker::Broker() : model_(1, getuid()) {
    poll_.setInterval(10);
    connect(&poll_, &QTimer::timeout, this, [this] { process(); });
    deadline_.setSingleShot(true);
    connect(&deadline_, &QTimer::timeout, this, [this] { fail("Fingerprint timed out · use password"); });
    retry_.setSingleShot(true);
    connect(&retry_, &QTimer::timeout, this, [this] { if (enabled_) attempt(); });
}
Broker::~Broker() { cancel(); }
void Broker::text(const char* value) { status_ = value; if (changed) changed(); }
void Broker::close() {
    poll_.stop(); deadline_.stop();
    pending_ = sd_bus_slot_unref(pending_);
    statusSlot_ = sd_bus_slot_unref(statusSlot_);
    ownerSlot_ = sd_bus_slot_unref(ownerSlot_);
    // Disconnect releases a pending Claim even when its reply was cancelled.
    // No blocking teardown call can delay password input or sleep preparation.
    if (bus_) sd_bus_close(bus_);
    bus_ = sd_bus_unref(bus_);
    owner_.clear(); path_.clear();
}
void Broker::cancel() { enabled_ = false; retry_.stop(); model_.invalidate(); close(); text(""); }
void Broker::start() { if (enabled_) return; enabled_ = true; attempt(); }
void Broker::fail(const char* value) {
    model_.invalidate(); close(); text(value);
    if (enabled_) retry_.start(5000);
}
void Broker::attempt() {
    close(); model_.invalidate();
    if (sd_bus_open_system(&bus_) < 0 || sd_bus_set_method_call_timeout(bus_, 2000000) < 0) { fail(); return; }
    poll_.start(); deadline_.start(30000);
    // Use an existing owner directly. Activate only when there is no owner.
    activationAttempted_ = false;
    call(Step::Owner, dbus, dbusPath, dbus, "GetNameOwner", service);
}
void Broker::call(Step step, const char* destination, const char* path, const char* interface, const char* method, const char* argument) {
    step_ = step; pending_ = sd_bus_slot_unref(pending_);
    const int rc = argument
        ? sd_bus_call_method_async(bus_, &pending_, destination, path, interface, method, replied, this, "s", argument)
        : sd_bus_call_method_async(bus_, &pending_, destination, path, interface, method, replied, this, "");
    if (rc < 0) fail();
}
void Broker::process() {
    // A bounded dispatch batch keeps keyboard/PAM/render callbacks responsive.
    for (unsigned i = 0; bus_ && i < 16; ++i) {
        const int rc = sd_bus_process(bus_, nullptr);
        if (rc < 0) { fail(); return; }
        if (!rc) return;
    }
}
int Broker::replied(sd_bus_message* m, void* data, sd_bus_error*) { static_cast<Broker*>(data)->reply(m); return 0; }
int Broker::signalled(sd_bus_message* m, void* data, sd_bus_error*) { static_cast<Broker*>(data)->signal(m); return 0; }
void Broker::reply(sd_bus_message* m) {
    pending_ = sd_bus_slot_unref(pending_);
    if (!enabled_ || !bus_) return;
    if (sd_bus_message_is_method_error(m, nullptr)) {
        if (step_ == Step::Owner && !activationAttempted_
            && sd_bus_message_is_method_error(m, "org.freedesktop.DBus.Error.NameHasNoOwner")) {
            activationAttempted_ = true; step_ = Step::Activate;
            if (sd_bus_call_method_async(bus_, &pending_, dbus, dbusPath, dbus, "StartServiceByName", replied, this, "su", service, 0u) < 0) fail();
            return;
        }
        if (step_ == Step::Enrollment && sd_bus_message_is_method_error(m, "net.reactivated.Fprint.Error.NoEnrolledPrints")) fail("No fingerprint enrolled · use password");
        else fail();
        return;
    }
    const char* value = nullptr;
    switch (step_) {
    case Step::Activate:
        call(Step::Owner, dbus, dbusPath, dbus, "GetNameOwner", service); break;
    case Step::Owner:
        if (sd_bus_message_read(m, "s", &value) <= 0 || !value || *value != ':') { fail(); break; }
        owner_ = value;
        // Local match installation is nonblocking. AddMatch acknowledgement is
        // not required for safety: missed owner loss fails by deadline/destination.
        if (sd_bus_match_signal_async(bus_, &ownerSlot_, dbus, dbusPath, dbus, "NameOwnerChanged", signalled, nullptr, this) < 0) { fail(); break; }
        call(Step::Device, owner_.c_str(), manager, "net.reactivated.Fprint.Manager", "GetDefaultDevice"); break;
    case Step::Device:
        if (sd_bus_message_read(m, "o", &value) <= 0 || !value) { fail(); break; }
        path_ = value;
        call(Step::Enrollment, owner_.c_str(), path_.c_str(), device, "ListEnrolledFingers", ""); break;
    case Step::Enrollment:
        if (sd_bus_message_enter_container(m, 'a', "s") <= 0 || sd_bus_message_read(m, "s", &value) <= 0) { fail("No fingerprint enrolled · use password"); break; }
        call(Step::Claim, owner_.c_str(), path_.c_str(), device, "Claim", ""); break;
    case Step::Claim:
        step_ = Step::Subscribe;
        // VerifyStart follows successful AddMatch, so no accepted signal can be
        // lost between starting the device and installing our subscription.
        if (sd_bus_match_signal_async(bus_, &statusSlot_, owner_.c_str(), path_.c_str(), device, "VerifyStatus", signalled, replied, this) < 0) fail();
        break;
    case Step::Subscribe:
        model_.capability(Capability::Enrolled);
        if (!model_.start(true)) { fail(); break; }
        call(Step::Verify, owner_.c_str(), path_.c_str(), device, "VerifyStart", "any"); break;
    case Step::Verify:
        step_ = Step::Waiting;
        model_.receive(encode({model_.binding(), Event::Ready}));
        text("Touch fingerprint sensor"); break;
    case Step::Stop:
        call(Step::Release, owner_.c_str(), path_.c_str(), device, "Release"); break;
    case Step::Release: {
        const auto binding = model_.binding();
        model_.receive(encode({binding, outcome_}));
        close();
        if (outcome_ == Event::Match) {
            text("Fingerprint matched");
            if (succeeded) succeeded(binding);
            // A denied native gate cannot leave a reusable match behind.
            model_.invalidate();
        } else text("Fingerprint didn’t match · try again");
        if (enabled_) retry_.start(1500);
        break;
    }
    case Step::Waiting: fail(); break;
    }
}
void Broker::signal(sd_bus_message* m) {
    if (!enabled_ || !bus_) return;
    if (sd_bus_message_is_signal(m, dbus, "NameOwnerChanged")) {
        const char *name = nullptr, *old = nullptr, *fresh = nullptr;
        if (sd_bus_message_read(m, "sss", &name, &old, &fresh) > 0 && name && old
            && std::string_view(name) == service && owner_ == old) fail();
        return;
    }
    const auto sender = sd_bus_message_get_sender(m), path = sd_bus_message_get_path(m);
    if (step_ != Step::Waiting || !sender || owner_ != sender || !path || path_ != path
        || !sd_bus_message_is_signal(m, device, "VerifyStatus")) return;
    const char* value = nullptr; int done = 0;
    if (sd_bus_message_read(m, "sb", &value, &done) <= 0 || !value) { fail(); return; }
    const auto event = verifyStatus(value, done).value_or(Event::Error);
    if (event == Event::Retry) { model_.receive(encode({model_.binding(), event})); text("Try again"); return; }
    if (event == Event::DeviceLost || event == Event::Error) { fail(); return; }
    outcome_ = event;
    call(Step::Stop, owner_.c_str(), path_.c_str(), device, "VerifyStop");
}
bool Broker::consume(Binding binding, bool secure) { return enabled_ && model_.consume(binding, secure); }
}
