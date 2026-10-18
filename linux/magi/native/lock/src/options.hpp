#pragma once
#include <span>
#include <string>
#include <string_view>
#include "sleep_policy.hpp"
namespace magi {
struct Options {
    bool help = false;
    bool buildInfo = false;
    bool acquire = false;
    bool sleepIntegration = false;
    SleepCoordinator sleepCoordinator = SleepCoordinator::Native;
    bool coordinatorSpecified = false;
    bool notifyReady = false;
    bool authenticate = false;
    unsigned developmentSeconds = 0;
#if MAGI_LOCK_FAILURE_INJECTION
    std::string failureFixture;
#endif
    std::string error;
};
Options parseOptions(std::span<const std::string_view> arguments);
}
