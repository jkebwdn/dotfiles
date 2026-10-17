#pragma once
#include <span>
#include <string>
#include <string_view>
namespace magi {
struct Options {
    bool help = false;
    bool buildInfo = false;
    bool acquire = false;
    unsigned developmentSeconds = 0;
    std::string error;
};
Options parseOptions(std::span<const std::string_view> arguments);
}
