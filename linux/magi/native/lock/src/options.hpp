#pragma once
#include <span>
#include <string>
#include <string_view>
namespace magi {
struct Options {
    bool help = false;
    bool buildInfo = false;
    bool acquire = false;
    bool authenticate = false;
    unsigned developmentSeconds = 0;
#if MAGI_LOCK_FAILURE_INJECTION
    std::string failureFixture;
#endif
    std::string error;
};
Options parseOptions(std::span<const std::string_view> arguments);
}
