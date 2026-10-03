import QtQuick
import Quickshell
import "NotificationPolicy.js" as Policy

// Window-independent owner, also instantiated against a private bus by tests.
Scope {
    id: root
    required property var preferences
    property bool fullscreen: false
    property bool centreOpen: false
    property int outputToastLimit: 4
    property var records: []
    readonly property var history: records.filter(r => !r.data.transient && !r.dismissed)
    readonly property int unread: history.filter(r => !r.read).length
    property alias toasts: toastModel
    property double lastTick: Date.now()
    property bool trimming: false
    ListModel { id: toastModel }
    Component { id: recordComponent; NotificationRecord {} }

    function find(id) { return records.find(r => r.notificationId === id) || null }
    function toastIndex(id) {
        for (let i = 0; i < toastModel.count; ++i) if (toastModel.get(i).notificationId === id) return i
        return -1
    }
    function receive(notification) {
        if (!preferences.enabled) { notification.dismiss(); return }
        notification.tracked = true
        const record = recordComponent.createObject(root, {owner: root, notification: notification})
        record.sync()
    }
    function updated(record, replacement) {
        record.remaining = Policy.timeout(record.data.timeout, record.data.urgency, preferences.fallbackTimeout)
        record.read = centreOpen
        if (!replacement) records = [record].concat(records)
        else records = [record].concat(records.filter(r => r !== record))
        const index = toastIndex(record.notificationId)
        const eligible = Policy.canToast(preferences, record.data.urgency, fullscreen, centreOpen)
            && (replacement || !record.notification.lastGeneration)
        if (!eligible) hideToast(record.notificationId)
        else if (index >= 0) {
            // A replacement can reverse an exit without creating a duplicate.
            toastModel.setProperty(index, "exiting", false)
            toastModel.setProperty(index, "exitAt", 0)
        } else if (toastModel.count < Math.min(preferences.maxVisible, outputToastLimit)) {
            toastModel.append({notificationId: record.notificationId, exiting: false, exitAt: 0})
        }
        trim()
    }
    function hideToast(id) {
        const index = toastIndex(id)
        if (index < 0 || toastModel.get(index).exiting) return
        toastModel.setProperty(index, "exiting", true)
        toastModel.setProperty(index, "exitAt", Date.now() + 180)
    }
    function closed(record, reason) {
        record.hovered = false
        if (reason === 2 || reason === 3 || record.data.transient) record.dismissed = true
        hideToast(record.notificationId)
        records = records.slice()
        Qt.callLater(collect)
    }
    function dismiss(id) {
        const record = find(id)
        if (!record) return
        record.dismissed = true
        if (record.notification) record.notification.dismiss()
        else { hideToast(id); records = records.slice(); Qt.callLater(collect) }
    }
    function clear() {
        const list = history.slice()
        for (const record of list) dismiss(record.notificationId)
    }
    function markRead() {
        for (const record of records) record.read = true
        records = records.slice()
    }
    function invoke(id, identifier) {
        const record = find(id)
        if (!record || !record.notification) return false
        const action = Array.from(record.notification.actions).find(a => a.identifier === identifier)
        if (!action) return false
        record.read = true
        action.invoke()
        records = records.slice()
        return true
    }
    function collect() {
        const removed = records.filter(r => r.dismissed && toastIndex(r.notificationId) < 0)
        if (!removed.length) return
        records = records.filter(r => removed.indexOf(r) < 0)
        for (const record of removed) record.destroy()
    }
    function trim() {
        if (trimming) return
        trimming = true
        const kept = records.filter(r => !r.dismissed)
        for (const record of kept.slice(preferences.historyLimit)) dismiss(record.notificationId)
        trimming = false
        collect()
    }
    function reconcile() {
        for (let i = 0; i < toastModel.count; ++i) {
            const record = find(toastModel.get(i).notificationId)
            if (!record || i >= Math.min(preferences.maxVisible, outputToastLimit)
                    || !Policy.canToast(preferences, record.data.urgency, fullscreen, centreOpen)) {
                if (record) record.hovered = false
                hideToast(toastModel.get(i).notificationId)
            }
        }
        if (!preferences.enabled) for (const record of records.slice()) {
            if (record.notification) dismiss(record.notificationId)
        }
        trim()
    }
    onPreferencesChanged: Qt.callLater(reconcile)
    onOutputToastLimitChanged: Qt.callLater(reconcile)
    onFullscreenChanged: reconcile()
    onCentreOpenChanged: { if (centreOpen) markRead(); reconcile() }
    Timer {
        interval: 50; repeat: true; running: true
        onTriggered: {
            const now = Date.now(), elapsed = Math.max(0, now - root.lastTick)
            root.lastTick = now
            for (let i = toastModel.count - 1; i >= 0; --i)
                if (toastModel.get(i).exiting && toastModel.get(i).exitAt <= now) toastModel.remove(i)
            for (const record of root.records.slice()) {
                if (!record.notification || record.remaining <= 0 || record.hovered) continue
                record.remaining = Math.max(0, record.remaining - elapsed)
                if (record.remaining === 0) record.notification.expire()
            }
            root.collect()
        }
    }
}
