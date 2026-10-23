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
import "../settings" as SettingsUI

FocusScope {
    id: root
    property real outputWidth: 1920
    readonly property bool selectorAbove: Services.Settings.data.hub.selectorPosition === "above"
    readonly property int selectorHeight: 44
    readonly property int contentSelectorGap: 12
    readonly property real contentHeight: Math.max(0, height - selectorHeight - contentSelectorGap)
    property alias selectorPill: pill
    property alias surface: surface
    property var controller: Services.Hub
    readonly property string mode: controller.mode
    readonly property var launcherPreferences: Services.Launcher.preferences
    readonly property int preferredWidth: mode === "apps"
        ? (launcherPreferences.layout === "grid" ? launcherPreferences.gridWidth : launcherPreferences.panelWidth)
        : mode === "emoji" ? Services.Emoji.preferences.gridColumns * (Services.Emoji.preferences.emojiSize + 24) + 32
        : mode === "settings" ? 1000 : mode === "clipboard" ? 540 : 430
    readonly property int preferredHeight: selectorHeight + contentSelectorGap + (mode === "apps" ? apps.desiredHeight
        : mode === "emoji" ? emoji.desiredHeight : mode === "settings" ? 720 : mode === "clipboard" ? Math.min(660, Math.ceil(clipboard.implicitHeight) + 16) : Math.min(640, Math.ceil(notifications.implicitHeight) + 16))
    readonly property var currentContent: mode === "apps" ? apps : mode === "notifications" ? notifications
        : mode === "emoji" ? emoji : mode === "settings" ? settings.item : clipboard
    property alias modeButtons: pill.modeButtons
    function focusMode() {
        if (!visible || !controller.opened || !currentContent) return
        if (mode === "notifications" || mode === "settings") currentContent.focusContent()
        else currentContent.focusSearch()
    }
    onModeChanged: Qt.callLater(focusMode)
    onVisibleChanged: { if (visible) Qt.callLater(focusMode) }
    Keys.priority: Keys.AfterItem
    Keys.onEscapePressed: controller.close()
    // F6 reaches the compact selector from any mode; Tab/Shift+Tab remain usable.
    Keys.onPressed: event => {
        if (event.key === Qt.Key_F6) {
            pill.modeButtons.itemAt(controller.modes.indexOf(mode)).forceActiveFocus()
            event.accepted = true
        }
    }
    HubSelector {
        id: pill
        x: (parent.width - width) / 2
        y: root.selectorAbove ? 0 : root.contentHeight + root.contentSelectorGap
        mode: root.mode
        available: mode => root.controller.available(mode)
        onModeRequested: mode => { root.controller.open(mode); Qt.callLater(root.focusMode) }
    }
    HubSurface {
        id: surface
        objectName: "hubActiveSurface"
        width: parent.width; height: root.contentHeight
        y: root.selectorAbove ? root.selectorHeight + root.contentSelectorGap : 0
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton }
        // Retained content instances; backend state remains independently owned.
        LauncherUI.LauncherContent { id: apps; anchors.fill: parent; anchors.margins: 8; enabled: visible; embedded: true; service: Services.Launcher; visible: root.mode === "apps" }
        NotificationsUI.NotificationContent { id: notifications; anchors.fill: parent; anchors.margins: 8; enabled: visible; embedded: true; service: Services.Notifications; visible: root.mode === "notifications" }
        EmojiUI.EmojiContent { id: emoji; anchors.fill: parent; anchors.margins: 8; enabled: visible; embedded: true; service: Services.Emoji; visible: root.mode === "emoji" }
        ClipboardUI.ClipboardContent { id: clipboard; anchors.fill: parent; anchors.margins: 8; enabled: visible; embedded: true; service: Services.Clipboard; visible: root.mode === "clipboard" }
        Loader {
            id: settings
            property bool visited: false
            anchors.fill: parent; anchors.margins: 8
            visible: root.mode === "settings"; enabled: visible
            active: visited || visible
            onVisibleChanged: if (visible) visited = true
            onLoaded: Qt.callLater(root.focusMode)
            sourceComponent: SettingsUI.SettingsContent { outputWidth: root.outputWidth }
        }
    }
}
