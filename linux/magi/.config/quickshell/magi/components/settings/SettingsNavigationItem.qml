import QtQuick
import "../../theme" as Theme
SettingsButton {
    id: root
    implicitHeight: 34
    font.weight: checked ? Font.DemiBold : Font.Normal
    leftPadding: 16
    rightPadding: 10
    contentItem: Text {
        text: root.text
        font: root.font
        color: Theme.Theme.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: Theme.Theme.radius("action", 7, width, height)
        color: root.down ? Theme.Theme.elevated
            : root.hovered ? Theme.Theme.overlay : "transparent"
        Rectangle {
            x: 4; anchors.verticalCenter: parent.verticalCenter
            width: 3; height: 14; radius: 1.5
            color: Theme.Theme.accent
            visible: root.checked
        }
    }
}
