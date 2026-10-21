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
        Services.ThemeOrchestrator.activate()
        // Keep restore/topology ownership alive without a standalone manager window.
        Services.Wallpaper.initialize()
        Services.Weather.activate()
    }
    NotificationsUI.FullscreenMonitor { id: fullscreen; screen: bars.mainScreen }
    Binding { target: Services.Notifications; property: "fullscreen"; value: fullscreen.suppressed }
    NotificationsUI.FullscreenMonitor { id: menuFullscreen; screen: Services.SurfaceOrigin.menuTarget() }
    Binding { target: Services.Calendar; property: "suppressed"; value: menuFullscreen.suppressed }
    Binding { target: Services.Clipboard; property: "fullscreen"; value: hubFullscreen.suppressed }
    Binding { target: Services.Notifications; property: "outputToastLimit"; value: Math.max(1, Math.floor(((bars.mainScreen ? bars.mainScreen.height : 1080) - 76) / 300)) }
    NotificationsUI.ToastHost { screen: bars.mainScreen; service: Services.Notifications; suppressed: fullscreen.suppressed }
    NotificationsUI.FullscreenMonitor { id: hubFullscreen; screen: Services.SurfaceOrigin.hubTarget() }
    Binding { target: Services.Hub; property: "suppressed"; value: hubFullscreen.suppressed }
    // Shared utility host; backend lifetimes remain above.
    HubUI.HubWindow {
        readyToOpen: !bars.hubBar || bars.hubBar.settingsReady
        previewSurface: bars.hubBar ? bars.hubBar.activeCombinedRegion : null
    }
    SettingsUI.SettingsApplication {}
    Bar.BarFleet { id: bars }
}
