#pragma once
#include "sleep_policy.hpp"
#include <QObject>
#include <QTimer>
#include <systemd/sd-bus.h>
namespace magi {
class WaylandOwner;
// Opt-in adapter. Construction alone never connects to the system bus.
class LogindSleep final : public QObject, public SleepBackend {
public:
    explicit LogindSleep(WaylandOwner& owner, SleepCoordinator coordinator = SleepCoordinator::Native);
    ~LogindSleep() override;
    bool start();
    bool allowUnlock();
    bool acquireDelay() override;
    void releaseDelay() override;
    void ensureLock() override;
    bool secureLockReady() const override;
    void quiesce() override;
    bool authQuiescent() const override;
    void resumeInput() override;
    void coordinatedReady() override;
private:
    static int signal(sd_bus_message*, void*, sd_bus_error*);
    static int ownerChanged(sd_bus_message*, void*, sd_bus_error*);
    void process();
    void failure();
    WaylandOwner& owner_;
    SleepPolicy policy_;
    sd_bus* bus_ = nullptr;
    sd_bus_slot* signal_ = nullptr;
    sd_bus_slot* ownerSlot_ = nullptr;
    int fd_ = -1;
    QTimer poll_, deadline_;
};
}
