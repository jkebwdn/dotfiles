pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme

// A transient, keyed arrangement preview. Only the owning page may write Settings.
Item {
    id: root
    required property Flickable viewport
    required property var entries // [{key, label, lane, position, data?}]; data stays canonical
    property var lanes: [{id: "items", label: ""}]
    required property Component rowContent
    property real rowHeight: 100
    property real gap: 8
    readonly property bool multiLane: lanes.length > 1
    readonly property int laneColumns: multiLane && width >= 620 ? 3 : 1
    readonly property real inset: multiLane ? 10 : 0
    readonly property real headingHeight: multiLane ? 30 : 0
    property var stableKeys: []
    property string candidate: ""
    property string dragKey: ""
    readonly property bool dragging: dragKey.length > 0
    property var preview: null
    property var heldHeights: ({})
    property real dragWidth: 0
    property string dragBaseline: ""
    property point pointerPosition: Qt.point(0, 0) // viewport coordinates, unchanged by scrolling
    property point pressPosition: Qt.point(0, 0)
    property point offset: Qt.point(0, 0)
    property point boardPointer: Qt.point(0, 0)
    property string targetLane: ""
    property int targetIndex: -1
    signal moveRequested(string key, string lane, int position)
    Layout.fillWidth: true
    implicitHeight: geometry.reduce((height, lane) => Math.max(height, lane.y + lane.height), 0)
    readonly property var geometry: layout()

    function canonicalKeys(lane) {
        return entries.filter(e => e.lane === lane).sort((a,b) => a.position - b.position).map(e => e.key)
    }
    function order(lane) { return preview ? (preview[lane] || []) : canonicalKeys(lane) }
    function fingerprint() { return JSON.stringify(lanes.map(l => [l.id, canonicalKeys(l.id)])) }
    function entryFor(key) { return entries.find(e => e.key === key) || null }
    function synchronize() {
        if ((dragging || candidate) && dragBaseline !== fingerprint()) cancel()
        const keys = entries.map(e => e.key).sort()
        // Keep delegate identity and pointer grab across every reorder and lane crossing.
        if (JSON.stringify(keys) !== JSON.stringify(stableKeys)) stableKeys = keys
    }
    onEntriesChanged: synchronize()
    onLanesChanged: { cancel(); synchronize() }
    Component.onCompleted: synchronize()
    onVisibleChanged: if (!visible) cancel()
    onWidthChanged: if (dragging) cancel()
    Connections {
        target: root.Window.window
        function onActiveChanged() { if (target && !target.active) root.cancel() }
    }
    function layout() {
        const result = []
        let y = 0
        for (let start = 0; start < lanes.length; start += laneColumns) {
            const count = Math.min(laneColumns, lanes.length - start)
            const laneWidth = (width - (count - 1) * 12) / count
            let height = 0
            for (let i = 0; i < count; ++i) {
                const lane = lanes[start + i]
                const keys = order(lane.id)
                const natural = inset * 2 + headingHeight + Math.max(1, keys.length) * (rowHeight + gap) - gap
                height = Math.max(height, natural, dragging ? (heldHeights[lane.id] || 0) : 0)
                result.push({id:lane.id, label:lane.label, x:i * (laneWidth + 12), y:y,
                    width:laneWidth, height:natural, keys:keys})
            }
            for (let i = result.length - count; i < result.length; ++i) result[i].height = height
            y += height + 16
        }
        return result
    }
    function location(key) {
        for (const lane of geometry) {
            const index = lane.keys.indexOf(key)
            if (index >= 0) return {lane:lane, index:index, x:lane.x + inset,
                y:lane.y + inset + headingHeight + index * (rowHeight + gap), width:lane.width - inset * 2}
        }
        return {lane:{id:""}, index:-1, x:0, y:0, width:0}
    }
    function rowFor(key) {
        for (let i = 0; i < rows.count; ++i) if (rows.itemAt(i).entryKey === key) return rows.itemAt(i)
        return null
    }
    function begin(key, handle, px, py) {
        cancel()
        if (!entryFor(key)) return
        candidate = key
        dragBaseline = fingerprint()
        pointerPosition = handle.mapToItem(viewport, px, py)
        pressPosition = pointerPosition
        const row = rowFor(key)
        dragWidth = row.width
        const heights = {}
        for (const lane of geometry) heights[lane.id] = lane.height
        heldHeights = heights
        const top = row.mapToItem(viewport, 0, 0)
        offset = Qt.point(pointerPosition.x - top.x, pointerPosition.y - top.y)
    }
    function motion(handle, px, py) {
        if (!candidate && !dragging) return
        pointerPosition = handle.mapToItem(viewport, px, py)
        if (!dragging && Math.hypot(pointerPosition.x - pressPosition.x, pointerPosition.y - pressPosition.y) >= 6) {
            const initial = {}
            for (const lane of lanes) initial[lane.id] = canonicalKeys(lane.id)
            preview = initial
            dragKey = candidate
            candidate = ""
        }
        if (dragging) updateTarget()
    }
    function updateTarget() {
        boardPointer = viewport.mapToItem(root, pointerPosition.x, pointerPosition.y)
        targetLane = ""; targetIndex = -1
        if (pointerPosition.x < 0 || pointerPosition.x > viewport.width
                || pointerPosition.y < 0 || pointerPosition.y > viewport.height) return
        const lane = geometry.find(l => boardPointer.x >= l.x && boardPointer.x <= l.x + l.width
            && boardPointer.y >= l.y && boardPointer.y <= l.y + l.height)
        if (!lane) return
        const others = lane.keys.filter(key => key !== dragKey)
        let index = 0
        for (const key of others) {
            const slot = location(key)
            if (boardPointer.y > slot.y + rowHeight / 2) ++index
        }
        if (lanes.find(l => l.id === lane.id).ordered === false)
            index = others.concat(dragKey).sort((a,b) => entryFor(a).label.localeCompare(entryFor(b).label)).indexOf(dragKey)
        targetLane = lane.id; targetIndex = index
        const current = location(dragKey)
        if (current.lane.id === lane.id && current.index === index) return
        const next = {}
        for (const l of lanes) next[l.id] = order(l.id).filter(key => key !== dragKey)
        next[lane.id].splice(index, 0, dragKey)
        preview = next
    }
    function release(handle, px, py) {
        motion(handle, px, py)
        const key = dragKey, lane = targetLane, index = targetIndex
        const valid = dragging && lane !== "" && fingerprint() === dragBaseline
        cancel()
        if (valid) request(key, lane, index)
    }
    function cancel() {
        candidate = ""; dragKey = ""; preview = null; heldHeights = ({}); targetLane = ""; targetIndex = -1
    }
    function request(key, lane, index, keyboard) {
        const source = entryFor(key)
        if (!source || !lanes.some(l => l.id === lane)) return
        if (source.lane === lane && lanes.find(l => l.id === lane).ordered === false) return
        const max = canonicalKeys(lane).length - (source.lane === lane ? 1 : 0)
        index = Math.max(0, Math.min(max, index))
        if (source.lane !== lane || source.position !== index) moveRequested(key, lane, index)
        if (keyboard) { focusReveal.key = key; focusReveal.restart() }
    }
    function moveKey(key, delta) {
        if (dragging || candidate) return
        const source = entryFor(key)
        if (source) request(key, source.lane, source.position + delta, true)
    }
    function moveEdge(key, last) {
        if (dragging || candidate) return
        const source = entryFor(key)
        if (source) request(key, source.lane, last ? canonicalKeys(source.lane).length - 1 : 0, true)
    }
    function moveLane(key, delta) {
        if (dragging || candidate) return
        const source = entryFor(key)
        if (!source) return
        const i = lanes.findIndex(l => l.id === source.lane) + delta
        if (i >= 0 && i < lanes.length) request(key, lanes[i].id, canonicalKeys(lanes[i].id).length, true)
    }
    Timer {
        id: focusReveal
        property string key: ""
        interval: 140
        onTriggered: {
            const row = root.rowFor(key)
            if (!row || !root.visible) return
            const view = root.viewport
            const y = row.mapToItem(view.contentItem, 0, 0).y
            if (y < view.contentY + 8) view.contentY = Math.max(0, y - 8)
            else if (y + row.height > view.contentY + view.height - 8)
                view.contentY = Math.max(0, Math.min(view.contentHeight - view.height, y + row.height - view.height + 8))
        }
    }
    Timer {
        interval: 16; repeat: true; running: root.dragging
        onTriggered: {
            const p = root.pointerPosition, view = root.viewport
            if (p.x >= 0 && p.x <= view.width && p.y >= 0 && p.y <= view.height) {
                const direction = p.y < 32 ? -1 : p.y > view.height - 32 ? 1 : 0
                if (direction) view.contentY = Math.max(0, Math.min(view.contentHeight - view.height, view.contentY + direction * 8))
            }
            root.updateTarget()
        }
    }
    Repeater {
        model: root.geometry
        Rectangle {
            required property var modelData
            objectName: root.objectName + "-lane-" + modelData.id
            x: modelData.x; y: modelData.y; width: modelData.width; height: modelData.height
            radius: Theme.Theme.radius("surface", 10, width, height)
            color: root.multiLane ? Theme.Theme.surface : "transparent"
            border.width: root.dragging && root.targetLane === modelData.id && root.multiLane ? 1 : 0
            border.color: Theme.Theme.accent
            Label {
                x: 10; y: 8; width: parent.width - 20
                text: modelData.label; visible: root.multiLane
                font.pixelSize: 11; font.bold: true; color: Theme.Theme.text
                elide: Text.ElideRight
            }
            Label {
                x: root.inset + 8; y: root.inset + root.headingHeight
                width: parent.width - root.inset * 2 - 16; height: root.rowHeight
                visible: modelData.keys.length === 0
                text: root.multiLane ? "Drop a module here" : "No items configured"
                color: Theme.Theme.text; font.pixelSize: 12; wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    Repeater {
        id: rows
        model: root.stableKeys
        Rectangle {
            id: row
            required property string modelData
            readonly property string entryKey: modelData
            readonly property var entry: root.entryFor(entryKey)
            readonly property var slot: root.location(entryKey)
            readonly property bool moving: root.dragKey === entryKey
            objectName: root.objectName + "-row-" + entryKey
            x: moving ? Math.max(0, Math.min(root.width - width, root.boardPointer.x - root.offset.x)) : slot.x
            y: moving ? root.boardPointer.y - root.offset.y : slot.y
            width: moving ? root.dragWidth : slot.width; height: root.rowHeight
            z: moving ? 10 : 1
            opacity: moving ? 0.92 : 1
            color: root.multiLane ? Theme.Theme.background : Theme.Theme.surface
            radius: Theme.Theme.radius("action", 8, width, height)
            border.width: moving ? 1 : 0; border.color: Theme.Theme.accent
            Behavior on x { enabled: !row.moving; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !row.moving; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Loader {
                readonly property var entry: row.entry
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: handle.left; margins: 8 }
                sourceComponent: root.rowContent
            }
            SettingsDragHandle {
                id: handle
                objectName: root.objectName + "-handle-" + row.entryKey
                x: parent.width - width - 4; y: 8
                width: 28; height: 28
                label: row.entry ? row.entry.label : ""
                hasLanes: root.multiLane
                cancellingDrag: root.dragging || root.candidate.length > 0
                onDragPressed: (px, py) => root.begin(row.entryKey, handle, px, py)
                onDragMoved: (px, py) => root.motion(handle, px, py)
                onDragReleased: (px, py) => root.release(handle, px, py)
                onDragCancelled: root.cancel()
                onMoveRequested: delta => root.moveKey(row.entryKey, delta)
                onEdgeRequested: last => root.moveEdge(row.entryKey, last)
                onLaneRequested: delta => root.moveLane(row.entryKey, delta)
            }
        }
    }
    Rectangle {
        objectName: root.objectName + "-insertion"
        visible: root.dragging && root.targetLane !== ""
        readonly property var slot: root.location(root.dragKey)
        x: slot.x; y: slot.y - 3; width: slot.width; height: 2; radius: 1
        color: Theme.Theme.accent; z: 20
    }
}
