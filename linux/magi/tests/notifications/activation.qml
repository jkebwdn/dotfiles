import QtQuick
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    // Production shell binds this singleton while constructing its hosts. The
    // service must take ownership without any later IPC activation call.
    property var service: Services.Notifications
    Component.onCompleted: Services.Notifications.activateServer()
    IpcHandler {
        target: "gate"
        function ready(): bool { return Services.Settings.ready && Services.Notifications.serverActivated }
        function count(): int { return Services.Notifications.history.length }
        function active(): bool { return Services.Notifications.serverActivated }
    }
}
