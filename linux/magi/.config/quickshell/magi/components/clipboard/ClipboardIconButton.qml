import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
import "../controls" as Controls
Button {
    id: root
    property string role: "close"
    property string label: ""
    property bool highlightedState: false
    implicitWidth: 30; implicitHeight: 30
    Accessible.name: label
    ToolTip.visible: hovered
    ToolTip.delay: 500
    ToolTip.text: label
    background: Rectangle {
        radius: Theme.Theme.radius("action", 7, width, height)
        color: root.hovered || root.activeFocus ? Theme.Theme.overlay : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.Theme.focus
    }
    contentItem: Controls.Icon {
        role: root.role; size: 16
        color: root.highlightedState ? Theme.Theme.accent : Theme.Theme.stateColor("secondary", true)
        opacity: root.enabled ? 1 : .4
    }
}
