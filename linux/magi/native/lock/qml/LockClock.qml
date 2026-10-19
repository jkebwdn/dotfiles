import QtQuick
Column {
    required property var tokens
    property string timeLabel
    property string dateLabel
    spacing: 4
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: parent.timeLabel; textFormat: Text.PlainText
        color: tokens.ink; font.family: tokens.family
        font.pixelSize: Math.min(tokens.clockSize, parent.width / 5.5); font.weight: Font.Light
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: parent.dateLabel; textFormat: Text.PlainText
        color: tokens.secondary; font.family: tokens.family; font.pixelSize: tokens.dateSize
    }
}
