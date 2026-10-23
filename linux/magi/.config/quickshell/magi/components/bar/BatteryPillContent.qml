import QtQuick
import "../controls" as Controls
import "../../icons" as Icons
import "../../theme" as MagiTheme
Row {
    id: root
    property bool available: true
    property bool charging: false
    property int percentage: 72
    spacing: 4
    Controls.Icon {
        anchors.verticalCenter: parent.verticalCenter
        role: Icons.IconRegistry.batteryRole(root.available, root.charging, root.percentage)
        moduleId: "battery"; size: MagiTheme.Theme.statusIconSize
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.available ? root.percentage + "%" : ""
        color: MagiTheme.Theme.text
        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 11
    }
}
