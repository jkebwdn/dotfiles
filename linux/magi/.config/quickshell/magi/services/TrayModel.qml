import QtQuick
QtObject {
    id: root
    // Keep QObject references, not property snapshots. Delegates bind to updates.
    // Session-only shortcut override; never written to Settings.
    property var presentationOverride: null
    property var sourceItems: []
    property var items: []
    function reconcile() {
        const incoming = sourceItems.filter(item => item !== null && item !== undefined)
        const retained = items.filter(item => incoming.includes(item))
        const added = incoming.filter(item => !retained.includes(item))
        added.sort((a, b) => String(a.id || a.title || "").localeCompare(String(b.id || b.title || "")))
        const next = retained.concat(added)
        if (next.length !== items.length || next.some((item, i) => item !== items[i])) items = next
    }
    onSourceItemsChanged: reconcile()
    Component.onCompleted: reconcile()
}
