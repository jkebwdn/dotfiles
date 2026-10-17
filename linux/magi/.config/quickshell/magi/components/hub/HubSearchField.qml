import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
import "../controls" as Controls
TextField {
    id: root
    implicitHeight: 46
    color: Theme.Theme.text
    placeholderTextColor: Theme.Theme.subtext
    font.family: Theme.Theme.fontFamily; font.pixelSize: 15
    selectionColor: Theme.Theme.accent; selectedTextColor: Theme.Theme.accentText
    selectByMouse: true
    leftPadding: 42; rightPadding: 40
    background: Rectangle {
        color: Theme.Theme.elevated
        radius: Theme.Theme.radius("action", 10, width, height)
        border.width: 1
        border.color: root.activeFocus ? Theme.Theme.focus : Theme.Theme.border
    }
    Controls.Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; role: "search"; size: 18; color: Theme.Theme.subtext }
    Button {
        anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30; visible: root.text.length > 0
        Accessible.name: "Clear search"
        ToolTip.visible: hovered; ToolTip.text: "Clear search"
        onClicked: { root.clear(); root.textEdited(); root.forceActiveFocus() }
        background: Rectangle { radius: 6; color: parent.hovered ? Theme.Theme.overlay : "transparent"; border.width: parent.activeFocus ? 1 : 0; border.color: Theme.Theme.focus }
        contentItem: Controls.Icon { role: "close"; size: 14; color: Theme.Theme.subtext }
    }
}
