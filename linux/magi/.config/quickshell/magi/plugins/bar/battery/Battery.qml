
import QtQuick
import "../../../components/bar" as Bar
import Quickshell
import "../../../theme" as MagiTheme
import "../../../services" as MagiServices

Bar.StatusPill {
    id: root

    property real sharedExpansion: 0

    implicitWidth: batteryLabel.implicitWidth + 18
    implicitHeight: MagiTheme.Theme.barPillHeight

    radius: MagiTheme.Theme.barPillRadius

    color: batteryMouse.containsMouse
        ? MagiTheme.Theme.statusPillHoverBackground
        : Qt.alpha(MagiTheme.Theme.statusPillBackground, MagiTheme.Theme.statusPillBackground.a * (1 - sharedExpansion))

    Bar.BatteryPillContent {
        id: batteryLabel
        anchors.centerIn: parent
        available: MagiServices.Battery.available
        charging: MagiServices.Battery.charging
        percentage: MagiServices.Battery.percentage
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
