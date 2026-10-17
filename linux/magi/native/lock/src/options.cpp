#include "options.hpp"
#include <charconv>
namespace magi {
Options parseOptions(std::span<const std::string_view> args) {
    Options result;
    for (const auto arg : args) {
        if (arg == "--help" && !result.help) result.help = true;
        else if (arg == "--build-info" && !result.buildInfo) result.buildInfo = true;
        else if (arg == "--authenticate" && !result.authenticate) result.authenticate = true;
        else if (arg == "--acquire-session-lock" && !result.acquire) result.acquire = true;
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
    if ((result.help || result.buildInfo) && (result.acquire || result.developmentSeconds || result.authenticate))
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
    return result;
}
}
