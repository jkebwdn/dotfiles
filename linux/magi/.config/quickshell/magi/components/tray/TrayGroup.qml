pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../bar" as Bar
import "../../theme" as Theme
import "TrayActions.js" as Actions
Bar.StatusPill {
    id: root
    styleId: "tray"
    property var items: []
    property bool showEmpty: false
    property real maximumWidth: 240
    property bool interactive: true
    property bool bottomUp: false
    property bool nativeMenus: true
    readonly property real cellWidth: Math.max(30, Theme.Theme.statusIconSize + 8)
    readonly property var partition: Actions.partition(items, maximumWidth, cellWidth)
    readonly property var overflowItems: partition.overflow
    readonly property var delegates: repeater
    signal overflowRequested()
    implicitWidth: items.length || showEmpty ? 8 + (partition.visible.length + (overflowItems.length || !items.length ? 1 : 0)) * cellWidth : 0
    Row {
        anchors.centerIn: parent
        Repeater {
            id: repeater
            model: root.partition.visible
            TrayItem {
                required property var modelData
                trayItem: modelData
                interactive: root.interactive
                bottomUp: root.bottomUp
                nativeMenus: root.nativeMenus
                width: root.cellWidth; height: root.height
            }
        }
        Button {
            objectName: "trayOverflowButton"
            visible: root.overflowItems.length > 0 || (root.showEmpty && !root.items.length)
            enabled: root.interactive
            width: root.cellWidth; height: root.height
            Accessible.name: root.items.length ? "More background applications (" + root.overflowItems.length + ")" : "Open System Tray"
            text: "•••"
            onClicked: root.overflowRequested()
            background: Rectangle { radius: Theme.Theme.barPillRadius; color: parent.hovered || parent.activeFocus ? Theme.Theme.overlay : "transparent" }
            contentItem: Text { text: parent.text; color: Theme.Theme.text; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
    }
}
