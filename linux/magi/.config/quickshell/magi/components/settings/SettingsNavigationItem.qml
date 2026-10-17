import QtQuick
import "../../theme" as Theme
import "../controls" as Controls
SettingsButton {
    id: root
    property string iconRole: ""
    property bool subsection: false
    implicitHeight: 34
    font.weight: checked ? Font.DemiBold : Font.Normal
    leftPadding: 10; rightPadding: 10
    contentItem: Item {
        implicitWidth: label.implicitWidth + (root.iconRole ? 26 : 0)
        implicitHeight: label.implicitHeight
        Controls.Icon {
            objectName: "settingsNavigationIcon"
            visible: root.iconRole.length > 0
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            role: root.iconRole; size: 16
            color: root.checked ? (root.subsection ? Theme.Theme.accent : Theme.Theme.navigationAccent) : Theme.Theme.subtext
        }
        Text {
            id: label
            objectName: "settingsNavigationText"
            anchors.fill: parent; anchors.leftMargin: root.iconRole ? 26 : 0
            text: root.text; font: root.font
            color: root.checked ? (root.subsection ? Theme.Theme.accent : Theme.Theme.navigationAccent) : Theme.Theme.text
            verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
        }
    }
    background: Rectangle {
        radius: Theme.Theme.radius("action", 7, width, height)
        color: root.subsection && root.checked ? Theme.Theme.elevated
            : root.down || root.hovered ? Theme.Theme.overlay : "transparent"
    }
}
