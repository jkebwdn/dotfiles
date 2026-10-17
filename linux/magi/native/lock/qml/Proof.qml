import QtQuick
Rectangle {
    property string outputLabel: "Output"
    property string nativeState: "Acquiring"
    property string developmentNotice: "NO AUTHENTICATION — PROTOCOL PROOF ONLY"
    color: "#181825"
    Text {
        anchors.centerIn: parent
        width: Math.max(0, parent.width - 32)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        color: "#cdd6f4"
        font.pixelSize: 24
        text: "MAGI LOCK PROTOCOL PROOF\n" + parent.outputLabel
            + "\nFrame created while: " + parent.nativeState + "\n" + parent.developmentNotice
    }
}
