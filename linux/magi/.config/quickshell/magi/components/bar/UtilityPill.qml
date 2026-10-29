import QtQuick
import QtQuick.Controls.Basic
import "../controls" as Controls
import "../../services" as Services
import "../../theme" as Theme
AbstractButton {
    id: root
    property bool interactive: true
    property var outputScreen: null
    required property string mode
    objectName: "utilityPill-" + mode
    required property string label
    implicitWidth: 30
    implicitHeight: Theme.Theme.barPillHeight
    Accessible.name: label
    onClicked: if (interactive) Services.Hub.toggle(mode, outputScreen)
    background: Rectangle {
        radius: Theme.Theme.barPillRadius
        color: root.hovered ? Theme.Theme.barItemHoverBackground(root.mode) : Theme.Theme.barItemBackground(root.mode)
        border.width: root.visualFocus ? 3 : 0
        border.color: Theme.Theme.background
        Rectangle {
            anchors.fill: parent; anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: "transparent"
            border.width: root.visualFocus ? 1 : 0
            border.color: Theme.Theme.text
        }
    }
    contentItem: Item { Controls.Icon { anchors.centerIn: parent; role: root.mode; moduleId: root.mode; size: Theme.Theme.statusIconSize; color: Theme.Theme.barItemForeground(root.mode, Theme.Theme.text) } }
    ToolTip.visible: hovered
    ToolTip.text: label
}
