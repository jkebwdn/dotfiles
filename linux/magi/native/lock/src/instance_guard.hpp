#pragma once
#include <string>
namespace magi {
class InstanceGuard {
public:
    InstanceGuard() = default;
    InstanceGuard(const InstanceGuard&) = delete;
    InstanceGuard& operator=(const InstanceGuard&) = delete;
    ~InstanceGuard();
    bool acquire(const std::string& directory, const std::string& display);
private:
    int fd_ = -1;
};
}
