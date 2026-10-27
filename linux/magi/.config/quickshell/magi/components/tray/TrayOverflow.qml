pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
import "../../services" as Services
Rectangle {
    id: root
    property var items: []
    property bool bottomUp: false
    property bool nativeMenus: true
    property bool opened: false
    readonly property var delegates: repeater
    signal closeRequested()
    readonly property real cellWidth: Math.max(30, Theme.Theme.statusIconSize + 8)
    readonly property real cellHeight: Math.max(Theme.Theme.barPillHeight, Theme.Theme.statusIconSize + 8)
    readonly property real availableWidth: Math.min(280, parent ? parent.width : 280)
    readonly property int columns: Math.max(1, Math.min(items.length, Math.floor((availableWidth - 12) / (cellWidth + 4))))
    // Match Bar icon sizing and compact targets; keep four-pixel gaps and eight-pixel padding.
    width: Math.min(availableWidth, items.length ? columns * (cellWidth + 4) + 12 : emptyLabel.implicitWidth + 16)
    implicitHeight: Math.max(cellHeight + 16, Math.min(300, list.contentHeight + 16))
    height: implicitHeight
    visible: opened
    activeFocusOnTab: true
    color: Theme.Theme.surfaceBackground(Theme.Theme.surface)
    radius: Theme.Theme.radiusMedium
    border.width: Services.Settings.data.appearance.surfaceBorders.width
    border.color: Theme.Theme.roles[Services.Settings.data.appearance.surfaceBorders.role] || Theme.Theme.border
    onOpenedChanged: if (opened) Qt.callLater(() => { if (repeater.count) repeater.itemAt(0).button.forceActiveFocus(); else root.forceActiveFocus() })
    Keys.onEscapePressed: event => { closeRequested(); event.accepted = true }
    Text { id: emptyLabel; anchors.centerIn: parent; visible: !root.items.length; text: "No background applications"; color: Theme.Theme.subtext; font.pixelSize: 12 }
    Flickable {
        id: list
        anchors.fill: parent; anchors.margins: 8
        contentWidth: width; contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            visible: list.contentHeight > list.height
            enabled: visible
        }
        Flow {
            id: column
            spacing: 4
            width: list.width
            Repeater {
                id: repeater
                model: root.items
                Item {
                    id: cell
                    required property var modelData
                    readonly property alias button: button
                    width: root.cellWidth; height: root.cellHeight
                    TrayItem {
                        id: button
                        trayItem: cell.modelData
                        bottomUp: root.bottomUp
                        nativeMenus: root.nativeMenus
                        width: root.cellWidth; height: root.cellHeight
                    }

                }
            }
        }
    }
}
