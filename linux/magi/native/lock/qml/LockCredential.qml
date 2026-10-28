import QtQuick
Item {
    id: root
    objectName: "credentialDots"
    required property var tokens
    property int characterCount: 0
    property string style: "dots"
    readonly property int visibleCount: Math.min(16, Math.max(0, characterCount))
    implicitHeight: 26
    // Every mask uses the same bounded count feedback; no credential text enters QML.
    Row {
        objectName: "dotRow"
        visible: root.visibleCount > 0
        anchors.centerIn: parent; spacing: tokens.dotGap
        Repeater {
            model: root.visibleCount
            Item {
                width: tokens.dotSize; height: width
                Rectangle {
                    anchors.centerIn: parent
                    width: root.style === "minimal" ? 4 : tokens.dotSize
                    height: root.style === "line" ? 3 : root.style === "segments" ? 6 : width
                    radius: root.style === "segments" ? 2 : height / 2
                    color: root.style === "ring" ? "transparent" : tokens.accent
                    border.width: root.style === "ring" ? 2 : 0
                    border.color: tokens.accent
                }
            }
        }
        Text {
            visible: root.characterCount > 16
            text: "…"; color: tokens.accent; font.pixelSize: tokens.statusSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
