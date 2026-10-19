#pragma once
namespace magi {
enum class AuthState { Idle, Editing, Authenticating, Failed, WorkerError, Unsupported, Cancelled, Succeeded };
// Only this value object crosses the presentation boundary, never the controller.
struct AuthPresentation { unsigned count = 0; bool active = false; bool caps = false; AuthState state = AuthState::Idle; bool capsKnown = true; bool keyboardUnavailable = false; };
inline const char* authStateName(AuthState s) {
    switch (s) {
    case AuthState::Idle: return "Locked";
    case AuthState::Editing: return "Enter password, then Enter";
    case AuthState::Authenticating: return "Authenticating";
    case AuthState::Failed: return "Authentication failed";
    case AuthState::WorkerError: return "Authentication unavailable";
    case AuthState::Unsupported: return "Unsupported PAM conversation";
    case AuthState::Cancelled: return "Cancelled";
    case AuthState::Succeeded: return "Authentication succeeded";
    }
    return "Authentication unavailable";
}
}
