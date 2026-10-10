pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io

NotificationModel {
    id: root
    preferences: Settings.data.notifications
    // The production ShellRoot activates this idempotently at process startup.
    // Keeping construction explicit prevents non-shell fixtures/importers from
    // claiming the notification bus as a side effect.
    property bool serverActivated: false
    property var backend: null
    Component { id: backendComponent; NotificationBackend { owner: root } }
    onCentreOpenChanged: Hub.requestVisibility("notifications", centreOpen)
    function open() { Hub.open("notifications") }
    function close() { Hub.closeMode("notifications") }
    function toggle() { Hub.toggle("notifications") }
    function activateServer() {
        if (serverActivated) return
        backend = backendComponent.createObject(root)
        serverActivated = backend !== null
    }
    IpcHandler {
        target: "notifications"
        function activate(): void { root.activateServer() }
        function open(): void { root.open() }
        function toggle(): void { root.toggle() }
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
