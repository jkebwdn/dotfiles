
import QtQuick
import "../../../components/bar" as Bar
import Quickshell
import "../../../theme" as MagiTheme
import "../../../services" as MagiServices

Bar.BatteryPillContent {
    id: root
    available: MagiServices.Battery.available
    charging: MagiServices.Battery.charging
    percentage: MagiServices.Battery.percentage
    hovered: batteryMouse.containsMouse

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
