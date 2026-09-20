
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../theme" as MagiTheme
import "../../../services" as MagiServices

Rectangle {
    id: root

    implicitWidth: 28
    implicitHeight: 28

    radius: MagiTheme.Theme.radiusSmall

    color: batteryMouse.containsMouse
        ? MagiTheme.Theme.elevated
        : MagiTheme.Theme.surface

    Text {
        anchors.centerIn: parent

        text: MagiServices.Battery.icon

        color: !MagiServices.Battery.available
            ? MagiTheme.Theme.muted
            : MagiTheme.Theme.text

        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 15
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
