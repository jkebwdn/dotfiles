pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
import "../controls" as Controls
import "../settings" as SettingsUI
Item {
    id: root
    required property var entry
    readonly property bool previewReady: preview.status === Image.Ready
    property bool current: false
    property bool selected: false
    property bool keyboardFocused: false
    signal chosen()
    Rectangle {
        anchors.fill: parent; anchors.margins: 5
        color: root.current ? Theme.Theme.overlay : Theme.Theme.elevated
        radius: Theme.Theme.radius("surface", 8, width, height)
        border.width: root.current ? 3 : 1
        border.color: root.current ? Theme.Theme.accent : mouse.containsMouse ? Theme.Theme.subtext : Theme.Theme.border
        Rectangle { anchors.fill: parent; anchors.margins: 5; radius: Math.max(0,parent.radius-3); color:"transparent"; border.width: root.keyboardFocused ? 1 : 0; border.color: Theme.Theme.focus; z: 2 }
        Controls.RoundedArtwork {
            id: preview
            objectName: "wallpaperThumbnail"
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 5 }
            height: Math.max(0, parent.height - 38)
            source: root.entry.url
            sourceSize: Qt.size(320, 200)
            asynchronous: true; cache: false
            borderWidth: 0
            radius: Theme.Theme.radius("surface", 6, width, height)
            placeholder: "image"
        }
        MouseArea {
            id: mouse; anchors.fill: parent; hoverEnabled: true
            onClicked: root.chosen()
        }
        Label {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 }
            text: (root.current ? "Current · " : "") + (preview.status === Image.Error ? "Image unavailable" : preview.status === Image.Loading ? "Loading…" : root.entry.name)
            color: Theme.Theme.text; elide: Text.ElideMiddle
            font.pixelSize: 11; textFormat: Text.PlainText
        }
        ToolTip.visible: mouse.containsMouse
        ToolTip.delay: 600
        ToolTip.text: root.entry.name + (root.current ? " · Current wallpaper" : "")
    }
}
