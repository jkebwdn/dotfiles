pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services" as Services
import "OutputPolicy.js" as Policy
Scope {
    id: root
    property var screens: Quickshell.screens
    property var mainScreen: null
    // Sample focus only when selecting a main output; focus changes never resync.
    property var focusedMonitor: Hyprland.focusedMonitor
    readonly property var eligibleScreens: Policy.eligible(screens)
    onEligibleScreensChanged: syncOutputs()
    readonly property var enabledScreens: Policy.selected(eligibleScreens, mainScreen, Services.Settings.data.bar.externalDisplays)
    readonly property var presentations: variants.instances
    function syncOutputs() { mainScreen = Policy.main(eligibleScreens, mainScreen, focusedMonitor ? focusedMonitor.name : "") }
    onScreensChanged: syncOutputs()
    Component.onCompleted: { syncOutputs(); Hyprland.refreshWorkspaces() }
    function barFor(screen) { return presentations.find(bar => bar.outputScreen === screen) || null }
    function openFromShortcut(view) {
        const target = view === "tray" ? mainBar : barFor(Services.SurfaceOrigin.shortcutTarget())
        return target ? target.open(view) : false
    }
    function toggleFromShortcut(view) {
        const target = view === "tray" ? mainBar : barFor(Services.SurfaceOrigin.shortcutTarget())
        if (target) target.toggle(view)
    }
    readonly property var mainBar: barFor(mainScreen)
    readonly property var menuBar: barFor(Services.SurfaceOrigin.menuTarget())
    readonly property var hubBar: barFor(Services.SurfaceOrigin.hubTarget())
    Binding { target: Services.SurfaceOrigin; property: "focusedScreen"; value: root.enabledScreens.find(s => root.focusedMonitor && s.name === root.focusedMonitor.name) || null }
    Binding { target: Services.SurfaceOrigin; property: "mainScreen"; value: root.mainScreen }
    Binding { target: Services.SurfaceOrigin; property: "enabledScreens"; value: root.enabledScreens }
    Binding { target: Services.Caffeine; property: "bound"; value: !!root.mainBar }
    IdleInhibitor { enabled: Services.Caffeine.requested && !!root.mainBar; window: root.mainBar }
    Variants {
        id: variants
        model: root.enabledScreens
        Bar {
            required property var modelData
            screen: modelData
            expandableHostMode: "combined"
        }
    }
    IpcHandler {
        target: "magi"
        function status(): string { return root.mainBar ? root.mainBar.status() : "{}" }
        function open(view: string): bool { return root.openFromShortcut(view) }
        function toggle(view: string): void { root.toggleFromShortcut(view) }
        function close(): void { for (const bar of root.presentations) bar.closeTray(); Services.MenuController.close() }
    }
}
