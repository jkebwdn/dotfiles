import QtQuick
Rectangle {
    required property var tokens
    property bool artworkAvailable: false
    color: tokens.background
    Image {
        anchors.fill: parent
        source: parent.artworkAvailable ? "image://visual/wallpaper" : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        smooth: true
    }
    // Semantic overlay ensures readable light and dark palettes alike.
    Rectangle { anchors.fill: parent; color: tokens.background; opacity: parent.artworkAvailable ? tokens.backgroundTint : 0 }
}
