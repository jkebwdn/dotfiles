import QtQuick
Rectangle {
    property string outputLabel: "Output"
    property string nativeState: "Acquiring"
    property string developmentNotice: "NO AUTHENTICATION — PROTOCOL PROOF ONLY"
    property int characterCount: 0
    property bool inputActive: false
    property bool capsLock: false
    property string authStatus: "Locked"
    color: "#181825"
    Text {
        anchors.centerIn: parent
        width: Math.max(0, parent.width - 32)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        color: "#cdd6f4"
        font.pixelSize: 24
        text: "MAGI LOCK\n" + parent.nativeState
            + "\n" + "•".repeat(Math.max(0, Math.min(511, parent.characterCount)))
            + "\n" + parent.authStatus + (parent.inputActive ? "\nKeyboard input active" : "")
            + (parent.capsLock ? "\nCaps Lock" : "") + "\n" + parent.developmentNotice
    }
}
