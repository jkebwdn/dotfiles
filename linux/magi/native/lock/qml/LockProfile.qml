import QtQuick
Column {
    id: root
    required property var tokens
    property bool compact: false
    property bool nativeArtwork: false
    property string alignment: "center"
    property string displayName
    property bool artworkAvailable: false
    property string treatment: "plain"
    spacing: 18
    Rectangle {
        x: root.alignment === "left" ? 0 : root.alignment === "right" ? root.width-width : (root.width-width)/2
        width: tokens.avatarSize; height: width
        antialiasing: true
        radius: root.treatment === "frame" ? 4 : tokens.avatarRadius; color: root.compact && root.nativeArtwork && root.artworkAvailable ? "transparent" : tokens.surface
        Rectangle {
            anchors.fill: parent; anchors.margins: root.compact ? 0 : root.treatment === "glow" ? -7 : -3
            antialiasing: true
            radius: root.compact ? parent.radius : parent.radius+3; color: "transparent"; border.color: tokens.accent
            border.width: root.treatment === "glow" ? 7 : root.compact ? 4 : 2
            opacity: root.treatment === "glow" ? .22 : 1
            visible: (root.compact || root.treatment !== "plain") && !(root.compact && root.nativeArtwork && root.artworkAvailable)
            z: 1
        }
        // The provider supplies a bounded, predecoded image. Rounded native
        // masking avoids a GPU effect dependency in the software renderer.
        Image { anchors.fill: parent; anchors.margins: root.compact && root.nativeArtwork ? 0 : 2; smooth: true; mipmap: true; source: root.artworkAvailable ? (root.compact && root.nativeArtwork ? "image://visual/avatar-frame" : "image://visual/avatar") : ""; fillMode: Image.PreserveAspectFit }
        Text {
            anchors.centerIn: parent; visible: !root.artworkAvailable
            text: root.displayName.slice(0,1).toUpperCase(); textFormat: Text.PlainText
            color: tokens.accent; font.family: tokens.family; font.pixelSize: 36
        }
    }
    Text {
        objectName: "profileName"
        visible: !root.compact
        x: root.alignment === "left" ? 0 : root.alignment === "right" ? root.width-width : (root.width-width)/2
        width: Math.min(420, root.width); horizontalAlignment: root.alignment === "left" ? Text.AlignLeft : root.alignment === "right" ? Text.AlignRight : Text.AlignHCenter
        text: root.displayName; textFormat: Text.PlainText; elide: Text.ElideRight
        color: tokens.ink; font.family: tokens.family; font.pixelSize: root.alignment === "center" ? tokens.nameSize : 16
    }
}
