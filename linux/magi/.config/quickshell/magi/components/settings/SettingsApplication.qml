pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../../services" as Services
Scope {
    // Compatibility IPC only: no second Settings instance or native host.
    IpcHandler {
        target: "settingsWindow"
        function open(): void { Services.SettingsWindowState.open() }
        function close(): void { Services.Hub.closeMode("settings") }
        function page(id: string): bool {
            if (["Appearance", "Profile", "Bar", "Control Centre", "Icons", "Launcher", "Date & time", "Emoji", "Wallpaper", "Notifications", "Clipboard"].indexOf(id) < 0) return false
            Services.SettingsWindowState.page = id
            return true
        }
        function status(): string {
            return JSON.stringify({visible:Services.SettingsWindowState.shown,
                pending:Services.SettingsWindowState.requested, page:Services.SettingsWindowState.page})
        }
    }
}
