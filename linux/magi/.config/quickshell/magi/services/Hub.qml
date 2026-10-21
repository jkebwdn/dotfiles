pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Presentation coordination only. Subsystems retain their own data and workers.
Scope {
    id: root
    property bool opened: false
    property string mode: "apps"
    property bool suppressed: false
    property bool synchronizing: false
    property var visited: ({})
    readonly property var modes: ["apps", "clipboard", "notifications", "emoji", "settings"]

    function available(value) {
        return modes.indexOf(value) >= 0 && !suppressed
            && (value !== "apps" || Launcher.preferences.enabled)
            && (value !== "emoji" || (Settings.ready && Emoji.preferences.enabled && !Emoji.suppressed))
            && (value !== "clipboard" || !Clipboard.fullscreen)
    }
    function publish() {
        synchronizing = true
        Launcher.opened = opened && mode === "apps"
        Notifications.centreOpen = opened && mode === "notifications"
        Emoji.opened = opened && mode === "emoji"
        Clipboard.opened = opened && mode === "clipboard"
        SettingsWindowState.shown = opened && mode === "settings"
        synchronizing = false
    }
    // Preserve legacy writable visibility properties as requests, not extra hosts.
    function requestVisibility(value, visible) {
        if (synchronizing) return
        if (visible) open(value)
        else if (opened && mode === value) close()
    }
    function open(value, screen) {
        if (!modes.includes(value)) return
        SurfaceOrigin.hubScreen = screen || (MenuController.activeMenu ? SurfaceOrigin.menuTarget() : SurfaceOrigin.hubTarget())
        if (!available(value)) { publish(); return }
        if (value !== "settings" || !SettingsWindowState.controlCentrePreview) MenuController.close()
        if (!opened) visited = ({})
        if (!visited[value]) {
            if (value === "apps") Launcher.prepare()
            else if (value === "emoji") Emoji.prepare()
            else if (value === "clipboard") Clipboard.prepare()
            visited[value] = true
        }
        if (value === "clipboard" && (!opened || mode !== value)) Clipboard.entered()
        mode = value
        opened = true
        publish()
    }
    function close() {
        opened = false
        publish()
    }
    function closeMode(value) { if (opened && mode === value) close() }
    function toggle(value, screen) { if (opened && mode === value && (!screen || SurfaceOrigin.hubTarget() === screen)) close(); else open(value, screen) }
    // Fullscreen temporarily suppresses presentation without dismissing the session.
    Connections {
        target: MenuController
        function onActiveMenuChanged() { if (MenuController.activeMenu && !(root.opened && root.mode === "settings"
                && SettingsWindowState.controlCentrePreview && MenuController.activeMenu === "controlcentre")) root.close() }
    }
    function openFromShortcut(value) { root.open(value, SurfaceOrigin.shortcutTarget()) }
    function toggleFromShortcut(value) { root.toggle(value, SurfaceOrigin.shortcutTarget()) }
    IpcHandler {
        target: "hub"
        function open(mode: string): void { root.openFromShortcut(mode) }
        function toggle(mode: string): void { root.toggleFromShortcut(mode) }
        function close(): void { root.close() }
        function status(): string { return JSON.stringify({opened:root.opened, mode:root.mode, suppressed:root.suppressed}) }
    }
}
