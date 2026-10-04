pragma Singleton
import QtQuick
import Quickshell
QtObject {
    // Layouts consume this presentation contract, not desktop icon lookup rules.
    // Future user/pack overrides can resolve by app.id before the theme fallback.
    function resolve(app) {
        return {source: app.icon ? Quickshell.iconPath(app.icon, true) : "",
            fallbackText: (app.name || "?").charAt(0).toUpperCase()}
    }
}
