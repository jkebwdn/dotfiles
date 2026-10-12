pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
Item {
    id: root
    required property var entry
    readonly property bool previewReady: preview.status === Image.Ready
    property bool current: false
    property bool favourite: false
    property bool selected: false
    signal chosen()
    signal favouriteRequested()
    Rectangle {
        anchors.fill: parent; anchors.margins: 5
        color: Theme.Theme.surface; radius: 10
        border.width: root.current || root.selected || mouse.containsMouse ? 3 : 1
        border.color: root.current ? Theme.Theme.accent : root.selected || mouse.containsMouse ? Theme.Theme.text : Theme.Theme.border
        Image {
            id: preview
            anchors.fill: parent; anchors.margins: 5
            source: root.entry.url
            sourceSize: Qt.size(320, 200)
            fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false
        }
        Label { anchors.centerIn: parent; text: preview.status === Image.Error ? "Image unavailable" : ""; color: Theme.Theme.subtext }
        MouseArea {
            id: mouse; anchors.fill: parent; hoverEnabled: true
            onClicked: root.chosen()
        }
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 30; color: "#bf11111b"
            visible: mouse.containsMouse || root.selected || root.current || preview.status === Image.Error
            Label {
                anchors.fill: parent; anchors.margins: 6
                text: (root.current ? "✓  " : "") + root.entry.name
                color: "white"; elide: Text.ElideMiddle
                textFormat: Text.PlainText
            }
        }
        ToolButton {
            anchors.top: parent.top; anchors.right: parent.right
            text: root.favourite ? "★" : "☆"
            Accessible.name: root.favourite ? "Remove favourite" : "Add favourite"
            onClicked: root.favouriteRequested()
        }
    }
}
