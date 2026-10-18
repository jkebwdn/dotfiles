#include "native_input.hpp"
#include <xkbcommon/xkbcommon-keysyms.h>
namespace magi {
NativeInput::NativeInput(AuthController& auth) : auth_(auth) {
    context_ = xkb_context_new(XKB_CONTEXT_NO_ENVIRONMENT_NAMES);
    if (context_) {
        // Never print keymap/compose contents through xkb diagnostics.
        xkb_context_set_log_fn(context_, [](xkb_context*, xkb_log_level, const char*, va_list) {});
        table_ = xkb_compose_table_new_from_locale(context_, "C.UTF-8", XKB_COMPOSE_COMPILE_NO_FLAGS);
        if (table_) compose_ = xkb_compose_state_new(table_, XKB_COMPOSE_STATE_NO_FLAGS);
    }
}
NativeInput::~NativeInput() {
    focus(false);
    if (compose_) xkb_compose_state_unref(compose_);
    if (table_) xkb_compose_table_unref(table_);
    if (state_) xkb_state_unref(state_);
    if (keymap_) xkb_keymap_unref(keymap_);
    if (context_) xkb_context_unref(context_);
}
bool NativeInput::keymap(std::span<const char> text) {
    focus(false);
    if (state_) xkb_state_unref(state_);
    if (keymap_) xkb_keymap_unref(keymap_);
    state_ = nullptr; keymap_ = nullptr;
    if (!context_ || text.empty() || text.size() > 1024*1024 || text.back() != '\0') return false;
    keymap_ = xkb_keymap_new_from_string(context_, text.data(), XKB_KEYMAP_FORMAT_TEXT_V1, XKB_KEYMAP_COMPILE_NO_FLAGS);
    if (keymap_) state_ = xkb_state_new(keymap_);
    return state_ != nullptr;
}
void NativeInput::focus(bool focused, std::span<const unsigned> held, bool preserveAuth) {
    focused_ = focused && ready(); haveModifiers_ = false; down_.fill(false);
    for (auto key : held) if (key < down_.size()) down_[key] = true;
    if (compose_) xkb_compose_state_reset(compose_);
    auth_.setInputActive(focused_, preserveAuth);
}
bool NativeInput::mod(const char* name) const {
    return state_ && xkb_state_mod_name_is_active(state_, name, XKB_STATE_MODS_EFFECTIVE) > 0;
}
void NativeInput::modifiers(unsigned depressed, unsigned latched, unsigned locked, unsigned group) {
    if (!state_) return;
    // Wayland supplies authoritative serialized state; do not update_key as a server.
    haveModifiers_ = true;
    xkb_state_update_mask(state_, depressed, latched, locked, 0, 0, group);
    auth_.setCaps(xkb_state_mod_name_is_active(state_, XKB_MOD_NAME_CAPS, XKB_STATE_MODS_LOCKED) > 0);
}
void NativeInput::key(unsigned code, bool pressed) {
    if (code >= down_.size()) return;
    const bool wasDown = down_[code]; down_[code] = pressed;
    if (!pressed || wasDown || !focused_ || !haveModifiers_ || !state_) return;
    const auto key = code + 8; // wl_keyboard uses Linux evdev codes, XKB adds eight.
    const auto sym = xkb_state_key_get_one_sym(state_, key);
    if (sym == XKB_KEY_Escape) { if (compose_) xkb_compose_state_reset(compose_); auth_.clear(); return; }
    if (!auth_.presentation().active) return;
    if (mod(XKB_MOD_NAME_CTRL)) {
        if (sym == XKB_KEY_u || sym == XKB_KEY_U) { if (compose_) xkb_compose_state_reset(compose_); auth_.clear(); }
        return; // Includes Ctrl+V; no clipboard interfaces are bound.
    }
    if (mod(XKB_MOD_NAME_ALT) || mod(XKB_MOD_NAME_LOGO) || sym == XKB_KEY_Insert) return;
    if (sym == XKB_KEY_Return || sym == XKB_KEY_KP_Enter) {
        if (compose_) xkb_compose_state_reset(compose_);
        auth_.submit(); return;
    }
    if (sym == XKB_KEY_BackSpace) {
        if (compose_) xkb_compose_state_reset(compose_);
        auth_.backspace(); return;
    }
    struct Text { char bytes[64]{}; ~Text() { explicit_bzero(bytes, sizeof(bytes)); } } text;
    int size = 0;
    if (compose_) {
        xkb_compose_state_feed(compose_, sym);
        switch (xkb_compose_state_get_status(compose_)) {
        case XKB_COMPOSE_COMPOSING: return;
        case XKB_COMPOSE_CANCELLED: xkb_compose_state_reset(compose_); return;
        case XKB_COMPOSE_COMPOSED:
            size = xkb_compose_state_get_utf8(compose_, text.bytes, sizeof(text.bytes));
            xkb_compose_state_reset(compose_); break;
        case XKB_COMPOSE_NOTHING:
            size = xkb_state_key_get_utf8(state_, key, text.bytes, sizeof(text.bytes)); break;
        }
    } else size = xkb_state_key_get_utf8(state_, key, text.bytes, sizeof(text.bytes));
    if (size > 0 && size < int(sizeof(text.bytes))) auth_.append({text.bytes, std::size_t(size)});
}
}
