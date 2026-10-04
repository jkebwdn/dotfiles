pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../../services" as Services
Scope {
    id: root
    property bool readyToOpen: false
    property bool created: false
    property real outputWidth: 1920
    function present() {
        if (!readyToOpen || !Services.SettingsWindowState.requested) return
        created = true
        Services.SettingsWindowState.shown = true
        Services.SettingsWindowState.requested = false
    }
    onReadyToOpenChanged: Qt.callLater(present)
    Connections {
        target: Services.SettingsWindowState
        function onRequestedChanged() { Qt.callLater(root.present) }
    }
    Loader {
        active: root.created
        sourceComponent: Component { SettingsWindow { outputWidth: root.outputWidth } }
    }
    IpcHandler {
        target: "settingsWindow"
        function open(): void { Services.SettingsWindowState.open() }
        function close(): void { Services.SettingsWindowState.requested = false; Services.SettingsWindowState.shown = false }
        function page(id: string): bool {
            if (["Appearance", "Profile", "Bar", "Control Centre", "Icons", "Launcher"].indexOf(id) < 0) return false
            Services.SettingsWindowState.page = id
            return true
        }
        function status(): string {
            return JSON.stringify({visible:Services.SettingsWindowState.shown,
                pending:Services.SettingsWindowState.requested, page:Services.SettingsWindowState.page})
        }
    }
}
