
import QtQuick
import "../../../theme" as MagiTheme

Rectangle {
    id: root

    implicitWidth: label.implicitWidth + 14
    implicitHeight: MagiTheme.Theme.barPillHeight

    radius: MagiTheme.Theme.barPillRadius
    color: MagiTheme.Theme.surface

    function updateTime() {
        var now = new Date()

        var hours = now.getHours()
        var minutes = now.getMinutes()

        label.text =
            (hours < 10 ? "0" : "") + hours +
            ":" +
            (minutes < 10 ? "0" : "") + minutes
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: ""

        color: MagiTheme.Theme.text

        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 12
        font.bold: true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: root.updateTime()
    }

    Component.onCompleted: root.updateTime()
}
