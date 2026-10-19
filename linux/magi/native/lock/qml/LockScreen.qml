import QtQuick
Item {
    id: root
    property string outputLabel: ""
    property string nativeState: "Acquiring"
    property string developmentNotice: ""
    property int characterCount: 0
    property bool inputActive: false
    property bool capsLock: false
    property bool capsKnown: true
    property string authStatus: "Locked"
    property var visual: ({})
    property string timeLabel: ""
    property string dateLabel: ""
    property bool wallpaperAvailable: false
    property bool avatarAvailable: false
    LockTokens { id: design; palette: root.visual; artworkAvailable: root.wallpaperAvailable; logicalWidth: root.width; logicalHeight: root.height }
    LockBackground { anchors.fill: parent; tokens: design; artworkAvailable: root.wallpaperAvailable }
    Item {
        anchors.centerIn: parent
        scale: design.visualScale
        width: Math.min(600, (root.width - 32) / scale); height: Math.min(650, (root.height - 80) / scale)
        LockClock { anchors.top: parent.top; width: parent.width; tokens: design; timeLabel: root.timeLabel; dateLabel: root.dateLabel }
        Column {
            anchors.top: parent.top; anchors.topMargin: parent.height * 0.36
            width: parent.width; spacing: design.gap
            LockProfile { width: parent.width; tokens: design; displayName: root.visual.displayName || ""; artworkAvailable: root.avatarAvailable }
            LockCredential { width: parent.width; tokens: design; characterCount: root.characterCount }
            LockStatus { width: parent.width; tokens: design; authStatus: root.authStatus; capsLock: root.capsLock; capsKnown: root.capsKnown; inputActive: root.inputActive; characterCount: root.characterCount }
        }
    }
    Text {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 28; anchors.horizontalCenter: parent.horizontalCenter
        text: root.developmentNotice || "M A G I"; textFormat: Text.PlainText
        width: parent.width-32; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
        font.family: design.family; font.pixelSize: 11; color: design.secondary; opacity: 0.7
    }
}
