#include "options.hpp"
#include <charconv>
namespace magi {
Options parseOptions(std::span<const std::string_view> args) {
    Options result;
    for (const auto arg : args) {
        if (arg == "--help" && !result.help) result.help = true;
        else if (arg == "--build-info" && !result.buildInfo) result.buildInfo = true;
        else if (arg == "--sleep-integration" && !result.sleepIntegration) result.sleepIntegration = true;
        else if (arg.starts_with("--sleep-coordinator=") && !result.coordinatorSpecified) {
            result.coordinatorSpecified = true;
            auto mode = arg.substr(sizeof("--sleep-coordinator=") - 1);
            if (mode == "native") result.sleepCoordinator = SleepCoordinator::Native;
            else if (mode == "hypridle") result.sleepCoordinator = SleepCoordinator::Hypridle;
            else { result.error = "Invalid sleep coordinator"; return result; }
        }
        else if (arg == "--notify-ready" && !result.notifyReady) result.notifyReady = true;
        else if (arg == "--authenticate" && !result.authenticate) result.authenticate = true;
        else if (arg == "--acquire-session-lock" && !result.acquire) result.acquire = true;
#if MAGI_LOCK_FAILURE_INJECTION
        else if (arg.starts_with("--development-auth-failure=") && result.failureFixture.empty()) {
            auto mode = arg.substr(sizeof("--development-auth-failure=") - 1);
            if (mode != "crash" && mode != "hang") { result.error = "Unsupported failure fixture"; return result; }
            result.failureFixture = mode;
        }
#endif
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
        else if (arg.starts_with("--unsafe-development-unlock-after=")) {
            const auto value = arg.substr(sizeof("--unsafe-development-unlock-after=") - 1);
            unsigned seconds = 0;
            const auto parsed = std::from_chars(value.data(), value.data() + value.size(), seconds);
            if (result.developmentSeconds || parsed.ec != std::errc{}
                || parsed.ptr != value.data() + value.size() || seconds < 10 || seconds > 300) {
                result.error = "Development timer must be specified once, between 10 and 300 seconds";
                return result;
            }
            result.developmentSeconds = seconds;
        }
#endif
        else { result.error = "Unknown or duplicate argument"; return result; }
    }
    if (result.coordinatorSpecified && !result.sleepIntegration)
        result.error = "Explicit sleep coordinator requires sleep integration";
    else if ((result.sleepIntegration || result.notifyReady) && (!result.acquire || !result.authenticate || result.help || result.buildInfo))
        result.error = "Integration requires explicit acquisition and authentication";
    else if ((result.help || result.buildInfo) && (result.acquire || result.developmentSeconds || result.authenticate))
        result.error = "Informational arguments cannot be combined with acquisition";
    else if (result.authenticate && !result.acquire)
        result.error = "Authentication requires explicit acquisition";
    else if (result.developmentSeconds && !result.acquire)
        result.error = "Development timer requires explicit acquisition";
    else if (!result.help && !result.buildInfo && !result.acquire)
        result.error = "No action: use --help; acquisition requires --acquire-session-lock";
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    else if (result.acquire && !result.developmentSeconds)
        result.error = "Development build requires the explicit unsafe unlock timer";
#endif
#if MAGI_LOCK_FAILURE_INJECTION
    if (!result.failureFixture.empty() && (!result.authenticate || !result.acquire || !result.developmentSeconds))
        result.error = "Failure injection requires authentication, acquisition and emergency timer";
#endif
    return result;
}
}
