import QtQuick
import Quickshell

import "components/bar" as Bar
import "components/settings" as SettingsUI
import "components/notifications" as NotificationsUI
import "services" as Services

ShellRoot {
    // MAGI is the session notification daemon. Activate with the shell itself,
    // without a delayed IPC command or a persisted temporary approval flag.
    Component.onCompleted: Services.Notifications.activateServer()
    NotificationsUI.FullscreenMonitor { id: fullscreen; screen: bar.screen }
    Binding { target: Services.Notifications; property: "fullscreen"; value: fullscreen.suppressed }
    Binding { target: Services.Notifications; property: "outputToastLimit"; value: Math.max(1, Math.floor(((bar.screen ? bar.screen.height : 1080) - 76) / 300)) }
    NotificationsUI.ToastHost { screen: bar.screen; service: Services.Notifications; suppressed: fullscreen.suppressed }
    NotificationsUI.NotificationCentre { screen: bar.screen; service: Services.Notifications; suppressed: fullscreen.suppressed }
    Connections {
        target: Services.MenuController
        function onActiveMenuChanged() { if (Services.MenuController.activeMenu) Services.Notifications.centreOpen = false }
    }
    Connections {
        target: Services.SettingsWindowState
        function onRequestedChanged() { if (Services.SettingsWindowState.requested) Services.Notifications.centreOpen = false }
    }
    SettingsUI.SettingsApplication { readyToOpen: bar.settingsReady; outputWidth: bar.width }
    Bar.Bar {
        id: bar
        // Change to "anchored" to use the PopupWindow fallback.
        expandableHostMode: "combined"
    }
}
