import QtQuick
import "NotificationPolicy.js" as Policy

QtObject {
    id: root
    required property var owner
    required property var notification
    readonly property int notificationId: data.id || 0
    property var data: ({})
    property double receivedAt: Date.now()
    property double updatedAt: receivedAt
    property bool read: false
    property bool dismissed: false
    property int closeReason: 0
    property double remaining: 0
    property bool hovered: false
    property bool initialized: false
    function sync() {
        if (!notification) return
        data = Policy.snapshot(notification)
        if (initialized) updatedAt = Date.now()
        owner.updated(root, initialized)
        initialized = true
    }
    function schedule() { Qt.callLater(sync) }
    property Connections observer: Connections {
        target: root.notification
        function onAppNameChanged() { root.schedule() }
        function onAppIconChanged() { root.schedule() }
        function onSummaryChanged() { root.schedule() }
        function onBodyChanged() { root.schedule() }
        function onUrgencyChanged() { root.schedule() }
        function onExpireTimeoutChanged() { root.schedule() }
        function onActionsChanged() { root.schedule() }
        function onImageChanged() { root.schedule() }
        function onResidentChanged() { root.schedule() }
        function onTransientChanged() { root.schedule() }
        function onDesktopEntryChanged() { root.schedule() }
        function onHintsChanged() { root.schedule() }
        function onClosed(reason) {
            root.notification = null
            root.closeReason = reason
            // Provider images belong to the destroyed native notification.
            root.data = Object.assign({}, root.data, {image: "", actions: []})
            root.owner.closed(root, reason)
        }
    }
}
