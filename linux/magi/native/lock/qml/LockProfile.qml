import QtQuick
Column {
    id: root
    required property var tokens
    property string displayName
    property bool artworkAvailable: false
    property string treatment: "plain"
    spacing: 18
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: tokens.avatarSize; height: width
        radius: root.treatment === "frame" ? 4 : tokens.avatarRadius; color: tokens.surface
        Rectangle {
            anchors.fill: parent; anchors.margins: root.treatment === "glow" ? -7 : -3
            radius: parent.radius+3; color: "transparent"; border.color: tokens.accent
            border.width: root.treatment === "glow" ? 7 : 2
            opacity: root.treatment === "glow" ? .22 : 1
            visible: root.treatment !== "plain"
        }
        // The provider supplies a bounded, predecoded image. Rounded native
        // masking avoids a GPU effect dependency in the software renderer.
        Image { anchors.fill: parent; source: root.artworkAvailable ? "image://visual/avatar" : ""; fillMode: Image.PreserveAspectFit }
        Text {
            anchors.centerIn: parent; visible: !root.artworkAvailable
            text: root.displayName.slice(0,1).toUpperCase(); textFormat: Text.PlainText
            color: tokens.accent; font.family: tokens.family; font.pixelSize: 36
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(420, root.width); horizontalAlignment: Text.AlignHCenter
        text: root.displayName; textFormat: Text.PlainText; elide: Text.ElideRight
        color: tokens.ink; font.family: tokens.family; font.pixelSize: tokens.nameSize
    }
}
