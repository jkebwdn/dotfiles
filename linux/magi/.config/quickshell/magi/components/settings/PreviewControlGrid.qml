pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import "../../theme" as Theme

// Configuration-only geometry around production presenters. Motion never writes Settings.
Item {
    id: root
    required property var entries
    required property string group
    required property Component presenter
    property int columns: 4
    property real cellHeight: 68
    property real gap: 12
    property string dragKey: ""
    property var draftKeys: null
    property string dragBaseline: ""
    property point pointer: Qt.point(0, 0)
    property int targetIndex: -1
    readonly property var keys: entries.map(e => e.key)
    readonly property var order: draftKeys || keys
    property real itemWidth: -1
    readonly property real cellWidth: itemWidth >= 0 ? itemWidth : (width - (columns - 1) * gap) / columns
    implicitHeight: Math.ceil(entries.length / columns) * (cellHeight + gap) - (entries.length ? gap : 0)
    signal moveRequested(string group, string key, int position)
    Connections {
        target: root.Window.window
        function onActiveChanged() {
            if (target && !target.active)
                root.cancel();
        }
    }
    onKeysChanged: if (dragKey && JSON.stringify(keys) !== dragBaseline)
        cancel()
    onWidthChanged: cancel()
    onColumnsChanged: cancel()
    onCellHeightChanged: cancel()
    onVisibleChanged: if (!visible)
        cancel()
    function cancel() {
        dragKey = "";
        draftKeys = null;
        targetIndex = -1;
    }
    function begin(key, handle, x, y) {
        cancel();
        if (!keys.includes(key))
            return;
        dragBaseline = JSON.stringify(keys);
        dragKey = key;
        draftKeys = keys.slice();
        pointer = handle.mapToItem(root, x, y);
        targetIndex = keys.indexOf(key);
    }
    function motion(handle, x, y) {
        if (!dragKey)
            return;
        pointer = handle.mapToItem(root, x, y);
        if (pointer.x < 0 || pointer.y < 0 || pointer.x > width || pointer.y > height) {
            targetIndex = -1;
            return;
        }
        targetIndex = Math.min(keys.length - 1, Math.floor(pointer.y / (cellHeight + gap)) * columns + Math.min(columns - 1, Math.floor(pointer.x / (cellWidth + gap))));
        const next = draftKeys.filter(k => k !== dragKey);
        next.splice(targetIndex, 0, dragKey);
        draftKeys = next;
    }
    function drop(sourceGroup, key, index) {
        if (sourceGroup !== group || !keys.includes(key) || index < 0 || index >= keys.length)
            return false;
        if (keys.indexOf(key) !== index)
            moveRequested(group, key, index);
        return true;
    }
    function release(handle, x, y) {
        motion(handle, x, y);
        const key = dragKey, index = targetIndex, valid = dragBaseline === JSON.stringify(keys);
        cancel();
        if (valid)
            drop(group, key, index);
    }
    Repeater {
        model: root.entries
        Item {
            id: cell
            required property var modelData
            readonly property int slot: root.order.indexOf(modelData.key)
            readonly property bool moving: root.dragKey === modelData.key
            objectName: "preview-" + root.group + "-" + modelData.key
            x: (slot % root.columns) * (root.cellWidth + root.gap)
            y: Math.floor(slot / root.columns) * (root.cellHeight + root.gap)
            width: root.cellWidth
            height: root.cellHeight
            z: moving ? 4 : 1
            opacity: moving ? .85 : 1
            Behavior on x {
                NumberAnimation {
                    duration: 100
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 100
                }
            }
            Loader {
                anchors.fill: parent
                readonly property var entry: cell.modelData
                sourceComponent: root.presenter
                // No presenter can receive keyboard/pointer activation; handles own configuration.
                enabled: false
            }
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: Theme.Theme.radius("action", 8, width, height)
                border.width: cell.moving ? 2 : 0
                border.color: Theme.Theme.accent
            }
            SettingsDragHandle {
                id: handle
                objectName: "preview-handle-" + root.group + "-" + cell.modelData.key
                anchors.right: parent.right
                anchors.top: parent.top
                width: 26
                height: 24
                label: cell.modelData.module
                cancellingDrag: root.dragKey.length > 0
                onDragPressed: (x, y) => root.begin(cell.modelData.key, handle, x, y)
                onDragMoved: (x, y) => root.motion(handle, x, y)
                onDragReleased: (x, y) => root.release(handle, x, y)
                onDragCancelled: root.cancel()
                onMoveRequested: delta => root.drop(root.group, cell.modelData.key, root.keys.indexOf(cell.modelData.key) + delta)
                onEdgeRequested: last => root.drop(root.group, cell.modelData.key, last ? root.keys.length - 1 : 0)
            }
        }
    }
    Rectangle {
        objectName: "preview-insertion-" + root.group
        visible: root.dragKey.length > 0 && root.targetIndex >= 0
        x: (root.targetIndex % root.columns) * (root.cellWidth + root.gap)
        y: Math.floor(root.targetIndex / root.columns) * (root.cellHeight + root.gap) - 3
        width: root.cellWidth
        height: 2
        color: Theme.Theme.accent
    }
}
