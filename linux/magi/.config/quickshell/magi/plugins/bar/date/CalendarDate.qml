
import QtQuick
import "../../../theme" as MagiTheme

Rectangle {
    id: root

    implicitWidth: label.implicitWidth + 14
    implicitHeight: 26

    radius: MagiTheme.Theme.radiusMedium
    color: MagiTheme.Theme.surface

    function updateDate() {
        var now = new Date()

        var day = now.getDate()
        var month = now.getMonth() + 1
        var year = now.getFullYear() % 100

        label.text =
            (day < 10 ? "0" : "") + day +
            "/" +
            (month < 10 ? "0" : "") + month +
            "/" +
            (year < 10 ? "0" : "") + year
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
        interval: 60000
        running: true
        repeat: true

        onTriggered: root.updateDate()
    }

    Component.onCompleted: root.updateDate()
}
