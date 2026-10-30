import QtQuick
Item {
    id: root
    objectName: "displayStatus"
    required property var tokens
    property string authStatus
    property bool capsLock: false
    property bool capsKnown: true
    property bool inputActive: false
    property int characterCount: 0
    property string fingerprintStatus: ""
    property bool nativeArtwork: false
    readonly property bool failed: authStatus === "Authentication failed"
    readonly property bool unavailable: authStatus === "Authentication unavailable" || authStatus === "Unsupported PAM conversation"
    readonly property string message: authStatus.startsWith("Keyboard state unavailable") ? authStatus
        : failed ? "That didn’t match. Try again."
        : unavailable ? "Authentication unavailable"
        : authStatus === "Authenticating" ? "Verifying…"
        : authStatus === "Authentication succeeded" ? "Welcome back"
        : !inputActive ? "Waiting for keyboard input"
        : characterCount > 0 ? "Press Enter to unlock" : "Enter your password"
    property string alignment: "center"
    implicitHeight: 24
    // Fixed label, icon and feedback slots: state changes cannot move the host.
    Row {
        id: prompt
        objectName: "passwordPrompt"
        x: root.alignment === "right" ? root.width-width : root.alignment === "left" ? 0 : (root.width-width)/2
        height: 24; spacing: 8
        Item {
            width: 18; height: 24
            Accessible.role: Accessible.Indicator
            Accessible.name: !root.capsKnown ? "Caps Lock state pending" : root.capsLock ? "Caps Lock enabled" : "Caps Lock disabled"
            LockCapsIcon {
                objectName: "capsIndicator"
                anchors.centerIn: parent; width: 18; height: 18
                ink: tokens.warning
                opacity: root.capsKnown && root.capsLock ? 1 : 0
            }
        }
        LockFingerprint {
            objectName: "fingerprintIndicator"
            width: 22; height: 24; tokens: root.tokens; status: root.fingerprintStatus; nativeArtwork: root.nativeArtwork
        }
        Text {
            objectName: "passwordLabel"
            text: "ENTER PASSWORD"; textFormat: Text.PlainText
            color: tokens.secondary; font.family: tokens.family; font.pixelSize: tokens.statusSize
            anchors.verticalCenter: parent.verticalCenter
        }


    }
}
