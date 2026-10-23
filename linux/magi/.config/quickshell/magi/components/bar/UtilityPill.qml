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
        color: root.hovered ? Theme.Theme.statusPillHoverBackground : Theme.Theme.statusPillBackground
        border.width: root.visualFocus ? 1 : 0
        border.color: Theme.Theme.focus
    }
    contentItem: Item { Controls.Icon { anchors.centerIn: parent; role: root.mode; moduleId: root.mode; size: Theme.Theme.statusIconSize; color: Theme.Theme.text } }
    ToolTip.visible: hovered
    ToolTip.text: label
}
