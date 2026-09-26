import QtQuick

import "../../theme" as MagiTheme

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property bool available: true
    property color activeColor: MagiTheme.Theme.accent

    signal triggered()

    implicitWidth: Math.max(50, chipContent.implicitWidth + 20)
    implicitHeight: 26
    radius: height / 2
    color: root.active
        ? root.activeColor
        : chipMouse.containsMouse
            ? MagiTheme.Theme.elevated
            : MagiTheme.Theme.background
    border.width: 0
    opacity: root.available ? 1 : 0.55

    Row {
        id: chipContent

        anchors.centerIn: parent
        spacing: root.icon.length > 0 && root.label.length > 0 ? 6 : 0

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.active
                ? MagiTheme.Theme.accentText
                : MagiTheme.Theme.text
            font.family: MagiTheme.Theme.fontFamily
            font.pixelSize: 11
        }

        Text {
            visible: root.label.length > 0
            text: root.label
            color: root.active
                ? MagiTheme.Theme.accentText
                : MagiTheme.Theme.text
            font.family: MagiTheme.Theme.fontFamily
            font.pixelSize: 10
            font.bold: root.active
        }
    }

    MouseArea {
        id: chipMouse

        anchors.fill: parent
        enabled: root.available
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.triggered()
    }
}
