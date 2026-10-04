import QtQuick
import Quickshell

import "components/bar" as Bar
import "components/settings" as SettingsUI
import "components/notifications" as NotificationsUI
import "components/launcher" as LauncherUI
import "components/clipboard" as ClipboardUI
import "services" as Services

ShellRoot {
    // MAGI is the session notification daemon. Activate with the shell itself,
    // without a delayed IPC command or a persisted temporary approval flag.
    Component.onCompleted: {
        Services.Notifications.activateServer()
        Services.Clipboard.activate()
    }
    NotificationsUI.FullscreenMonitor { id: fullscreen; screen: bar.screen }
    Binding { target: Services.Notifications; property: "fullscreen"; value: fullscreen.suppressed }
    Binding { target: Services.Clipboard; property: "fullscreen"; value: fullscreen.suppressed }
    Binding { target: Services.Notifications; property: "outputToastLimit"; value: Math.max(1, Math.floor(((bar.screen ? bar.screen.height : 1080) - 76) / 300)) }
    NotificationsUI.ToastHost { screen: bar.screen; service: Services.Notifications; suppressed: fullscreen.suppressed }
    NotificationsUI.NotificationCentre { screen: bar.screen; service: Services.Notifications; suppressed: fullscreen.suppressed }
    LauncherUI.LauncherWindow { screen: bar.screen; service: Services.Launcher }
    ClipboardUI.ClipboardWindow { screen: bar.screen; service: Services.Clipboard }
    Connections {
        target: Services.MenuController
        function onActiveMenuChanged() {
            if (Services.MenuController.activeMenu) {
                Services.Notifications.centreOpen = false
                Services.Clipboard.opened = false
                Services.Launcher.close()
            }
        }
    }
    Connections {
        target: Services.SettingsWindowState
        function onRequestedChanged() {
            if (Services.SettingsWindowState.requested) {
                Services.Notifications.centreOpen = false
                Services.Clipboard.opened = false
                Services.Launcher.close()
            }
        }
    }
    Connections {
        target: Services.Notifications
        function onCentreOpenChanged() {
            if (Services.Notifications.centreOpen) { Services.Clipboard.opened = false; Services.Launcher.close() }
        }
    }
    Connections {
        target: Services.Clipboard
        function onOpenedChanged() { if (Services.Clipboard.opened) Services.Launcher.close() }
    }
    SettingsUI.SettingsApplication { readyToOpen: bar.settingsReady; outputWidth: bar.width }
    Bar.Bar {
        id: bar
        // Change to "anchored" to use the PopupWindow fallback.
        expandableHostMode: "combined"
    }
}
