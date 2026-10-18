#pragma once
#include "auth_controller.hpp"
#include <array>
#include <span>
#include <xkbcommon/xkbcommon.h>
#include <xkbcommon/xkbcommon-compose.h>
namespace magi {
class NativeInput {
public:
    explicit NativeInput(AuthController& auth);
    ~NativeInput();
    NativeInput(const NativeInput&) = delete;
    NativeInput& operator=(const NativeInput&) = delete;
    bool keymap(std::span<const char> text);
    // Preserve only for output focus routing; seat/keymap/teardown use cancellation.
    void focus(bool focused, std::span<const unsigned> held = {}, bool preserveAuth = false);
    void modifiers(unsigned depressed, unsigned latched, unsigned locked, unsigned group);
    void key(unsigned evdev, bool pressed);
    void blockForSleep(bool blocked);
    bool ready() const { return state_ != nullptr; }
private:
    bool mod(const char* name) const;
    AuthController& auth_;
    xkb_context* context_ = nullptr;
    xkb_keymap* keymap_ = nullptr;
    xkb_state* state_ = nullptr;
    xkb_compose_table* table_ = nullptr;
    xkb_compose_state* compose_ = nullptr;
    bool sleepBlocked_ = false;
    bool focused_ = false, haveModifiers_ = false;
    std::array<bool, 768> down_{};
};
}
