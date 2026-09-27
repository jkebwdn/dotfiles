
import QtQuick
import "../../../icons" as Icons
import "../../../components/controls" as Controls
import Quickshell
import "../../../theme" as MagiTheme
import "../../../services" as MagiServices

Rectangle {
    id: root

    property real sharedExpansion: 0

    implicitWidth: batteryLabel.implicitWidth + 18
    implicitHeight: MagiTheme.Theme.barPillHeight

    radius: MagiTheme.Theme.barPillRadius

    color: batteryMouse.containsMouse
        ? MagiTheme.Theme.elevated
        : Qt.alpha(MagiTheme.Theme.surface, 1 - sharedExpansion)

    Row {
        id: batteryLabel
        anchors.centerIn: parent
        spacing: 4
        Controls.Icon {
            anchors.verticalCenter: parent.verticalCenter
            role: Icons.IconRegistry.batteryRole(MagiServices.Battery.available, MagiServices.Battery.charging, MagiServices.Battery.percentage)
            moduleId: "battery"; size: 11
        }
        Text {
            text: MagiServices.Battery.available ? MagiServices.Battery.percentage + "%" : ""
            color: MagiTheme.Theme.text
            font.family: MagiTheme.Theme.fontFamily
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: batteryMouse

        anchors.fill: parent
        hoverEnabled: true
    }

    PopupWindow {
        id: batteryPopup

        anchor.item: root
        anchor.rect.x: root.width / 2 - width / 2
        anchor.rect.y: root.height + 6

        implicitWidth: tooltipText.implicitWidth + 20
        implicitHeight: 28

        visible: batteryMouse.containsMouse
        color: "transparent"

        Rectangle {
            anchors.fill: parent

            radius: MagiTheme.Theme.radiusSmall
            color: MagiTheme.Theme.elevated

            Text {
                id: tooltipText

                anchors.centerIn: parent

                text: MagiServices.Battery.statusText
                color: MagiTheme.Theme.text

                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 12
            }
        }
    }
}
