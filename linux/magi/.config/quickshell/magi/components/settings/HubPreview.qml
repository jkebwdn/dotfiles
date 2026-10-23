pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme
import "../hub" as HubUI
import "../controls" as Controls

Item {
    id: root
    property string mode: "apps"
    property string selectedKey: ""
    signal selected(string key)
    readonly property real sceneWidth: 400
    readonly property real sceneHeight: 620
    readonly property real fitScale: Math.min(1.3, width / sceneWidth, height / sceneHeight)
    property alias selector: selector
    property alias surface: surface
    readonly property real selectorAnchorY: above ? Math.max(64, Math.min(sceneHeight - 60 - 240, sceneHeight * Services.Settings.data.hub.verticalPosition)) : Math.max(64 + 240, Math.min(sceneHeight - 60, sceneHeight * Services.Settings.data.hub.verticalPosition))
    readonly property real contentHeight: Math.min(392, above ? sceneHeight - 16 - selectorAnchorY - 56 : selectorAnchorY - 64)
    readonly property bool above: Services.Settings.data.hub.selectorPosition === "above"
    clip: true
    Item {
        id: scene
        width: root.sceneWidth
        height: root.sceneHeight
        scale: root.fitScale
        transformOrigin: Item.TopLeft
        x: (root.width - width * scale) / 2
        y: (root.height - height * scale) / 2
        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Theme.Theme.background
            border.width: 1
            border.color: Theme.Theme.border
            MouseArea {
                anchors.fill: parent
                onClicked: root.selected("")
            }
        }
        Label {
            x: 20
            y: 16
            text: "HUB · " + root.mode.toUpperCase()
            color: Theme.Theme.subtext
            font.pixelSize: 12
        }
        Item {
            id: composition
            x: 16
            width: parent.width - 32
            height: root.contentHeight + 56
            // Same selector anchor and bounded content geometry as production HubWindow.
            y: root.above ? root.selectorAnchorY : root.selectorAnchorY - height + 44
            HubUI.HubSurface {
                id: surface
                objectName: "hubPreviewSurface"
                y: root.above ? 56 : 0
                width: parent.width
                height: root.contentHeight
                clip: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 16
                    Label {
                        text: ({
                                apps: "Applications",
                                clipboard: "Clipboard",
                                notifications: "Notifications",
                                emoji: "Emoji",
                                settings: "Settings"
                            })[root.mode]
                        font.pixelSize: 24
                        font.bold: true
                        color: Theme.Theme.text
                    }
                    Label {
                        text: "Representative content · editor only"
                        color: Theme.Theme.subtext
                        font.pixelSize: 12
                    }
                    GridLayout {
                        visible: root.mode === "apps" || root.mode === "emoji"
                        columns: 3
                        columnSpacing: 18
                        rowSpacing: 20
                        Layout.fillWidth: true
                        Repeater {
                            model: root.mode === "emoji" ? ["emoji", "favorite", "profile", "emoji", "favorite", "profile"] : ["apps", "profile", "image", "file", "calendar", "settings"]
                            ColumnLayout {
                                required property string modelData
                                Layout.fillWidth: true
                                Controls.Icon {
                                    role: parent.modelData
                                    size: 34
                                    color: Theme.Theme.subtext
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Label {
                                    text: root.mode === "emoji" ? "Sample" : parent.modelData
                                    color: Theme.Theme.text
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                    CardStylePreview {
                        compact: true
                        visible: root.mode === "clipboard" || root.mode === "notifications"
                        clipboard: root.mode === "clipboard"
                        Layout.fillWidth: true
                    }
                    ColumnLayout {
                        visible: root.mode === "settings"
                        Layout.fillWidth: true
                        Label {
                            text: "Appearance     Bar     Control Centre     Hub"
                            color: Theme.Theme.subtext
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                        SettingsToggle {
                            text: "Sample enabled preference"
                            checked: true
                            focusPolicy: Qt.NoFocus
                        }
                        SettingsToggle {
                            text: "Sample disabled preference"
                            checked: false
                            focusPolicy: Qt.NoFocus
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    z: 20
                    onClicked: root.selected(root.mode === "settings" ? "toggles" : "")
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    z: 25
                    color: "transparent"
                    radius: surface.radius + 3
                    border.color: Theme.Theme.focus
                    border.width: root.selectedKey === "" || root.selectedKey === "toggles" ? 2 : 0
                }
            }
            HubUI.HubSelector {
                id: selector
                objectName: "hubPreviewSelector"
                x: (parent.width - width) / 2
                y: root.above ? 0 : root.contentHeight + 12
                mode: root.mode
                onModeRequested: mode => {
                    root.mode = mode;
                    root.selected("selector");
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    color: "transparent"
                    radius: selector.radius + 3
                    border.color: Theme.Theme.focus
                    border.width: root.selectedKey === "selector" ? 2 : 0
                }
            }
        }
        Label {
            x: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            text: "Select framing or navigation · sample content is inert"
            font.pixelSize: 11
            color: Theme.Theme.subtext
        }
    }
}
