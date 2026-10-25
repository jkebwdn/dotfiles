import QtQuick
Item {
    id: root
    objectName: "credentialDots"
    required property var tokens
    property int characterCount: 0
    property string style: "dots"
    readonly property int visibleCount: Math.min(16, Math.max(0, characterCount))
    implicitHeight: 26
    // Alternative styles deliberately reveal only empty/nonempty, never count.
    Row {
        anchors.centerIn: parent; spacing: 5
        visible: root.style === "segments" && root.characterCount > 0
        Repeater { model: 5; Rectangle {width:18;height:6;radius:2;color:tokens.accent} }
    }
    Rectangle {
        anchors.centerIn: parent
        visible: ["line","ring","minimal"].includes(root.style) && root.characterCount > 0
        width: root.style === "line" ? 100 : root.style === "ring" ? 22 : 9
        height: root.style === "line" ? 3 : width
        radius: height/2
        color: root.style === "ring" ? "transparent" : tokens.accent
        border.width: root.style === "ring" ? 3 : 0; border.color: tokens.accent
    }
    Row {
        objectName: "dotRow"
        visible: root.style === "dots" && root.visibleCount > 0
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
