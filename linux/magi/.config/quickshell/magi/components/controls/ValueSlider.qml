import QtQuick

import "../../theme" as MagiTheme

Item {
    id: root

    property real value: 0
    property bool interactive: true
    property color fillColor: MagiTheme.Theme.accent
    property color trackColor: MagiTheme.Theme.background
    property int trackHeight: 6
    property int handleSize: 16

    signal valueMoved(real value)

    implicitHeight: 30

    Rectangle {
        id: track

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: root.trackHeight
        radius: MagiTheme.Theme.radius("slider", height / 2, width, height)
        color: root.trackColor

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: root.fillColor
        }

        Rectangle {
            x: Math.max(0, Math.min(parent.width - width,
                parent.width * root.value - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: root.handleSize
            height: root.handleSize
            radius: MagiTheme.Theme.radius("slider", width / 2, width, height)
            color: root.interactive
                ? MagiTheme.Theme.text
                : MagiTheme.Theme.muted
            border.width: 2
            border.color: root.fillColor
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        function applyPosition(mouseX) {
            root.valueMoved(Math.max(0, Math.min(1, mouseX / width)))
        }

        onPressed: mouse => applyPosition(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                applyPosition(mouse.x)
        }
    }
}
