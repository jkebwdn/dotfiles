import QtQuick
Column {
    id: root
    objectName: "displayStatus"
    required property var tokens
    property string authStatus
    property bool capsLock: false
    property bool capsKnown: true
    property bool inputActive: false
    property int characterCount: 0
    readonly property bool failed: authStatus === "Authentication failed"
    readonly property bool unavailable: authStatus === "Authentication unavailable" || authStatus === "Unsupported PAM conversation"
    readonly property string message: authStatus.startsWith("Keyboard state unavailable") ? authStatus
        : failed ? "That didn’t match. Try again."
        : unavailable ? "Authentication unavailable"
        : authStatus === "Authenticating" ? "Verifying…"
        : authStatus === "Authentication succeeded" ? "Welcome back"
        : !inputActive ? "Waiting for keyboard input"
        : characterCount > 0 ? "Press Enter to unlock" : "Enter your password"
    spacing: 12
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.message; textFormat: Text.PlainText
        color: root.failed || root.unavailable ? tokens.danger : tokens.secondary
        font.family: tokens.family; font.pixelSize: tokens.statusSize
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: !root.capsKnown ? "Caps Lock state pending" : root.capsLock ? "⇧ Caps Lock" : ""
        color: tokens.warning; font.family: tokens.family; font.pixelSize: tokens.statusSize - 3
    }
}
