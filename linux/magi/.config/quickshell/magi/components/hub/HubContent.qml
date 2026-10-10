pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../services" as Services
import "../../theme" as Theme
import "../controls" as Controls
import "../launcher" as LauncherUI
import "../notifications" as NotificationsUI
import "../emoji" as EmojiUI
import "../clipboard" as ClipboardUI

Rectangle {
    id: root
    property var controller: Services.Hub
    readonly property string mode: controller.mode
    readonly property var launcherPreferences: Services.Launcher.preferences
    readonly property int preferredWidth: mode === "apps"
        ? (launcherPreferences.layout === "grid" ? launcherPreferences.gridWidth : launcherPreferences.panelWidth)
        : mode === "emoji" ? Services.Emoji.preferences.gridColumns * (Services.Emoji.preferences.emojiSize + 24) + 32
        : mode === "clipboard" ? 540 : 410
    readonly property int preferredHeight: 48 + (mode === "apps" ? apps.desiredHeight
        : mode === "emoji" ? emoji.desiredHeight : mode === "clipboard" ? 660 : 640)
    readonly property var currentContent: mode === "apps" ? apps : mode === "notifications" ? notifications : mode === "emoji" ? emoji : clipboard
    property alias modeButtons: selector
    color: Qt.rgba(Theme.Theme.background.r, Theme.Theme.background.g, Theme.Theme.background.b, 1)
    radius: Theme.Theme.radius("surface", 22, width, height)
    border.width: 1; border.color: Theme.Theme.border
    function focusMode() {
        if (!visible || !controller.opened) return
        if (mode === "notifications") notifications.focusContent()
        else currentContent.focusSearch()
    }
    onModeChanged: Qt.callLater(focusMode)
    onVisibleChanged: { if (visible) Qt.callLater(focusMode) }
    Keys.onEscapePressed: controller.close()
    // F6 reaches the compact selector from any mode; Tab/Shift+Tab remain usable.
    Keys.onPressed: event => {
        if (event.key === Qt.Key_F6) {
            selector.itemAt(controller.modes.indexOf(mode)).forceActiveFocus()
            event.accepted = true
        }
    }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton } // Consume interior clicks; outside catcher is behind us.
    Row {
        anchors { top: parent.top; right: parent.right; topMargin: 8; rightMargin: 12 }
        spacing: 4
        Repeater {
            id: selector
            model: [
                {mode: "apps", label: "Applications", icon: "apps"},
                {mode: "notifications", label: "Notifications", icon: "notifications"},
                {mode: "emoji", label: "Emoji", icon: "emoji"},
                {mode: "clipboard", label: "Clipboard", icon: "clipboard"}
            ]
            Button {
                id: button
                required property var modelData
                objectName: "hubMode_" + modelData.mode
                width: 32; height: 32
                enabled: root.controller.available(modelData.mode)
                checked: root.mode === modelData.mode
                Accessible.name: modelData.label
                ToolTip.visible: hovered
                ToolTip.delay: 400
                ToolTip.text: modelData.label
                onClicked: { root.controller.open(modelData.mode); Qt.callLater(root.focusMode) }
                background: Rectangle {
                    radius: 8
                    color: button.checked ? Theme.Theme.elevated : button.hovered ? Theme.Theme.surface : "transparent"
                    border.width: button.checked || button.activeFocus ? 1 : 0
                    border.color: button.activeFocus ? Theme.Theme.focus : Theme.Theme.accent
                }
                contentItem: Item {
                    Controls.Icon {
                        anchors.centerIn: parent; width: 18; height: 18
                        role: button.modelData.icon; size: 18
                        color: button.checked ? Theme.Theme.accent : Theme.Theme.text
                        opacity: button.enabled ? 1 : .4
                    }
                }
            }
        }
    }
    Item {
        x: 0; y: 48; width: parent.width; height: Math.max(0, parent.height - y)
        // Four persistent content items, exactly one visible. No backend loaders.
        LauncherUI.LauncherContent { id: apps; anchors.fill: parent; embedded: true; service: Services.Launcher; visible: root.mode === "apps" }
        NotificationsUI.NotificationContent { id: notifications; anchors.fill: parent; embedded: true; service: Services.Notifications; visible: root.mode === "notifications" }
        EmojiUI.EmojiContent { id: emoji; anchors.fill: parent; embedded: true; service: Services.Emoji; visible: root.mode === "emoji" }
        ClipboardUI.ClipboardContent { id: clipboard; anchors.fill: parent; embedded: true; service: Services.Clipboard; visible: root.mode === "clipboard" }
    }
}
