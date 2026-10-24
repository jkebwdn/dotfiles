import QtQuick
Column {
    required property var tokens
    property string alignment: "center"
    property string timeLabel
    property string dateLabel
    spacing: 4
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.alignment === "center" ? implicitWidth : parent.width
        horizontalAlignment: parent.alignment === "right" ? Text.AlignRight : Text.AlignLeft
        text: parent.timeLabel; textFormat: Text.PlainText
        color: tokens.ink; font.family: tokens.family
        font.pixelSize: Math.min(tokens.clockSize, parent.width / 5.5); font.weight: Font.Light
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.alignment === "center" ? implicitWidth : parent.width
        horizontalAlignment: parent.alignment === "right" ? Text.AlignRight : Text.AlignLeft
        text: parent.dateLabel; textFormat: Text.PlainText
        color: tokens.secondary; font.family: tokens.family; font.pixelSize: tokens.dateSize
    }
}
