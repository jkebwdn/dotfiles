import QtQuick
Text {
    required property var tokens
    property string status: ""
    visible: status.length > 0
    height: visible ? implicitHeight : 0
    text: status
    textFormat: Text.PlainText
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.Wrap
    font.family: tokens.family
    font.pixelSize: 12
    color: tokens.secondary
}
