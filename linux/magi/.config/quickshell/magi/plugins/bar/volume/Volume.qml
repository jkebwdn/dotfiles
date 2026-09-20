
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../services" as MagiServices
import "../../../theme" as MagiTheme

Rectangle {
    id: root

    readonly property int volume: MagiServices.Audio.volumePercent
    readonly property bool muted: MagiServices.Audio.muted
    readonly property bool available: MagiServices.Audio.available

    readonly property string volumeIcon: {
        if (!available)
            return "󰖁"

        if (muted || volume === 0)
            return "󰖁"

        if (volume < 34)
            return "󰕿"

        if (volume < 67)
            return "󰖀"

        return "󰕾"
    }

    implicitWidth: 28
    implicitHeight: 28

    radius: MagiTheme.Theme.radiusSmall
    color: MagiTheme.Theme.surface

    // Volume icon

    Text {
        anchors.centerIn: parent

        text: root.volumeIcon

        color: root.available && !root.muted
               ? MagiTheme.Theme.text
               : MagiTheme.Theme.muted

        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 15
    }

    // Mouse controls

    MouseArea {
        id: volumeMouse

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: MagiServices.Audio.toggleMute()

        onWheel: wheel => {
            const steps = wheel.angleDelta.y / 120

            if (steps !== 0)
                MagiServices.Audio.adjustVolume(steps)

            wheel.accepted = true
        }
    }

    // Hover tooltip — separate surface to avoid bar clipping

    PopupWindow {
        id: volumePopup

        anchor.item: root
        anchor.rect.x: root.width / 2 - width / 2
        anchor.rect.y: root.height + 6

        implicitWidth: tooltipText.implicitWidth + 20
        implicitHeight: 28

        visible: volumeMouse.containsMouse
        color: "transparent"

        Rectangle {
            anchors.fill: parent

            radius: MagiTheme.Theme.radiusSmall
            color: MagiTheme.Theme.elevated

            Text {
                id: tooltipText

                anchors.centerIn: parent

                text: !root.available
                      ? "Audio unavailable"
                      : root.muted
                        ? "Muted · " + root.volume + "%"
                        : "Volume · " + root.volume + "%"

                color: MagiTheme.Theme.text

                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 12
            }
        }
    }
}
