import QtQuick
import Quickshell

import "components/bar" as Bar
import "components/settings" as SettingsUI
import "components/notifications" as NotificationsUI
import "components/hub" as HubUI
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
    Binding { target: Services.Calendar; property: "suppressed"; value: fullscreen.suppressed }
    Binding { target: Services.Clipboard; property: "fullscreen"; value: fullscreen.suppressed }
    Binding { target: Services.Notifications; property: "outputToastLimit"; value: Math.max(1, Math.floor(((bar.screen ? bar.screen.height : 1080) - 76) / 300)) }
    NotificationsUI.ToastHost { screen: bar.screen; service: Services.Notifications; suppressed: fullscreen.suppressed }
    Binding { target: Services.Hub; property: "suppressed"; value: fullscreen.suppressed }
    // Shared utility host; backend lifetimes remain above.
    HubUI.HubWindow { screen: bar.screen; readyToOpen: bar.settingsReady }
    SettingsUI.SettingsApplication { readyToOpen: bar.settingsReady; outputWidth: bar.width }
    Bar.Bar {
        id: bar
        // Change to "anchored" to use the PopupWindow fallback.
        expandableHostMode: "combined"
    }
}
