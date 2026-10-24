import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
Rectangle {
    id: root
    property real backgroundOpacity: 1
    property bool blurEnabled: true
    readonly property color detailA: Qt.tint(Theme.Theme.background, Qt.rgba(Theme.Theme.blue.r, Theme.Theme.blue.g, Theme.Theme.blue.b, .35))
    readonly property color detailB: Qt.tint(Theme.Theme.background, Qt.rgba(Theme.Theme.teal.r, Theme.Theme.teal.g, Theme.Theme.teal.b, .35))
    implicitWidth: 360; implicitHeight: 340
    color: Theme.Theme.background
    radius: Theme.Theme.radius("surface", 12, width, height)
    clip: true
    Accessible.role: Accessible.Graphic
    Accessible.name: "Application preview: translucent background with opaque text and content"
    // Fine detail behind the mock app. The in-app sample substitutes a soft
    // gradient for these stripes when blur is on. No opacity on the app parent.
    Repeater {
        model: 24
        Rectangle { required property int index; x: index * 24 - 90; y: -30; width: 9; height: 430; rotation: 25; color: index % 2 ? root.detailA : root.detailB }
    }
    Item {
        id: app
        objectName: "applicationPreviewFrame"
        x: 22; y: 36; width: parent.width - 44; height: 246
        clip: true
        Rectangle {
            objectName: "previewBlurSample"
            anchors.fill: parent
            visible: root.blurEnabled
            gradient: Gradient {
                GradientStop { position: 0; color: root.detailA }
                GradientStop { position: .5; color: root.detailB }
                GradientStop { position: 1; color: root.detailA }
            }
        }
        Rectangle {
            objectName: "applicationBackground"
            anchors.fill: parent
            color: Qt.rgba(Theme.Theme.surface.r, Theme.Theme.surface.g, Theme.Theme.surface.b, root.backgroundOpacity)
        }
        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: Theme.Theme.accent; radius: 10 }
        Item {
            id: foreground
            objectName: "applicationForeground"
            anchors.fill: parent
            Label { x: 16; y: 15; text: "Application"; color: Theme.Theme.text; font.bold: true }
            Rectangle { x: parent.width - 35; y: 18; width: 12; height: 12; radius: 6; color: Theme.Theme.accent }
            Label { x: 16; y: 56; text: "Clear text. Full colour."; color: Theme.Theme.text }
            Label { x: 16; y: 84; text: "Only the background changes."; color: Theme.Theme.subtext; font.pixelSize: 11 }
            Rectangle {
                objectName: "previewOpaqueImage"
                x: 16; y: 119; width: 74; height: 76; color: Theme.Theme.blue; radius: 6
                Rectangle { x: 12; y: 16; width: 18; height: 18; radius: 9; color: Theme.Theme.yellow }
                Rectangle { x: 23; y: 40; width: 48; height: 24; rotation: -22; color: Theme.Theme.teal }
            }
            Repeater {
                model: 3
                Rectangle { required property int index; x: 106; y: 126 + index * 22; width: Math.max(30, foreground.width - 128 - index * 12); height: 5; radius: 2; color: Theme.Theme.text }
            }
            Rectangle { x: 16; y: 210; width: 100; height: 23; radius: 6; color: Theme.Theme.accent
                Label { anchors.centerIn: parent; text: "Opaque controls"; color: Theme.Theme.background; font.pixelSize: 10 }
            }
        }
    }
    Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: 35; color: Theme.Theme.background }
    Label { anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 16 }
        text: root.blurEnabled ? "Blur on · illustrative preview" : "Blur off · illustrative preview"
        color: Theme.Theme.text; font.pixelSize: 11
    }
}
