import QtQuick
Item {
    id: root
    objectName: "credentialDots"
    required property var tokens
    property int characterCount: 0
    readonly property int visibleCount: Math.min(16, Math.max(0, characterCount))
    implicitHeight: 26
    Row {
        objectName: "dotRow"
        visible: root.visibleCount > 0
        anchors.centerIn: parent; spacing: tokens.dotGap
        Repeater {
            model: root.visibleCount
            Rectangle { width: tokens.dotSize; height: width; radius: width / 2; color: tokens.accent }
        }
        Text {
            visible: root.characterCount > 16
            text: "…"; color: tokens.accent; font.pixelSize: tokens.statusSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
