#pragma once
#include <cstdint>
namespace magi {
// Deliberate two-click confirmation, never a key binding. Double clicks do not
// confirm; a pending intent expires and is cancelled by typing/sleep/topology.
class PowerIntent {
public:
    enum Action { None, Reboot, Suspend };
    Action pending() const { return pending_; }
    void cancel() { pending_ = None; }
    bool click(Action action, std::uint64_t now) {
        if (action == None) { cancel(); return false; }
        if (pending_ == action && now >= armed_+800 && now <= armed_+10000) { cancel(); return true; }
        if (pending_ != action || now > armed_+10000) { pending_ = action; armed_ = now; }
        return false;
    }
private:
    Action pending_ = None;
    std::uint64_t armed_ = 0;
};
}
