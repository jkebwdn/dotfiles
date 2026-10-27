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
    width: Math.min(280, parent ? parent.width : 280)
    implicitHeight: Math.min(300, list.contentHeight + 24)
    height: implicitHeight
    visible: opened && items.length > 0
    color: Theme.Theme.surfaceBackground(Theme.Theme.surface)
    radius: Theme.Theme.radiusMedium
    border.width: Services.Settings.data.appearance.surfaceBorders.width
    border.color: Theme.Theme.roles[Services.Settings.data.appearance.surfaceBorders.role] || Theme.Theme.border
    onOpenedChanged: if (opened) Qt.callLater(() => { if (repeater.count) repeater.itemAt(0).button.forceActiveFocus() })
    Keys.onEscapePressed: event => { closeRequested(); event.accepted = true }
    Flickable {
        id: list
        anchors.fill: parent; anchors.margins: 12
        contentWidth: width; contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        Column {
            id: column
            width: list.width
            Repeater {
                id: repeater
                model: root.items
                Row {
                    required property var modelData
                    readonly property alias button: button
                    spacing: 8
                    width: column.width; height: 36
                    TrayItem {
                        id: button
                        trayItem: modelData
                        bottomUp: root.bottomUp
                        nativeMenus: root.nativeMenus
                        width: 36; height: 36
                    }
                    Text {
                        width: Math.max(0, parent.width - 44); height: 36
                        verticalAlignment: Text.AlignVCenter
                        text: button.accessibleName
                        textFormat: Text.PlainText; elide: Text.ElideRight
                        color: Theme.Theme.text; font.pixelSize: 13
                    }
                }
            }
        }
    }
}
