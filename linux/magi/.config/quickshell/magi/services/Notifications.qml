pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

NotificationModel {
    id: root
    preferences: Settings.data.notifications
    // Migration gate: no NotificationServer exists until explicitly activated.
    // This is not a user preference: daemon handoff must be deliberate.
    property bool serverActivated: false
    property var backend: null
    Component { id: backendComponent; NotificationBackend { owner: root } }
    onCentreOpenChanged: { if (centreOpen) MenuController.close() }
    function activateServer() {
        if (serverActivated) return
        backend = backendComponent.createObject(root)
        serverActivated = backend !== null
    }
    IpcHandler {
        target: "notifications"
        function activate(): void { root.activateServer() }
        function toggle(): void { root.centreOpen = !root.centreOpen }
        function close(): void { root.centreOpen = false }
        function status(): string {
            return JSON.stringify({activated: root.serverActivated, count: root.history.length,
                unread: root.unread, toasts: root.toasts.count, fullscreen: root.fullscreen,
                centreOpen: root.centreOpen, dnd: root.preferences.dnd,
                entries: root.history.map(r => ({id:r.notificationId, live:r.notification !== null,
                    read:r.read, reason:r.closeReason}))})
        }
    }
}
