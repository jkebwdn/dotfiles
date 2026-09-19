
import QtQuick
import "../../../theme" as MagiTheme
import "../../../services" as MagiServices

Rectangle {
    id: root

    implicitWidth: 26
    implicitHeight: 26

    radius: MagiTheme.Theme.radiusMedium
    color: mouseArea.containsMouse
        ? MagiTheme.Theme.elevated
        : MagiTheme.Theme.surface

    Text {
        anchors.centerIn: parent

        text: MagiServices.Network.icon
        color: MagiServices.Network.connected
            ? MagiTheme.Theme.text
            : MagiTheme.Theme.muted

        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 14
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
