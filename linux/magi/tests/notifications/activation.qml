import QtQuick
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    // Production shell binds this singleton while constructing its hosts.
    property var service: Services.Notifications
    PersistentProperties {
        id: session
        reloadableId: "magi-notification-test-approval"
        property bool approved: false
        onLoaded: { if (approved) Services.Notifications.activateServer() }
    }
    Connections {
        target: Services.Notifications
        function onServerActivatedChanged() { if (Services.Notifications.serverActivated) session.approved = true }
    }
    IpcHandler {
        target: "gate"
        function ready(): bool { return Services.Settings.ready && !Services.Notifications.serverActivated }
        function activate(): void { Services.Notifications.activateServer() }
        function count(): int { return Services.Notifications.history.length }
        function active(): bool { return Services.Notifications.serverActivated }
    }
}
