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
    readonly property var modes: ["apps", "notifications", "emoji", "clipboard"]

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
        synchronizing = false
    }
    // Preserve legacy writable visibility properties as requests, not extra hosts.
    function requestVisibility(value, visible) {
        if (synchronizing) return
        if (visible) open(value)
        else if (opened && mode === value) close()
    }
    function open(value) {
        if (!available(value)) { publish(); return }
        MenuController.close()
        if (!opened) visited = ({})
        if (!visited[value]) {
            if (value === "apps") Launcher.prepare()
            else if (value === "emoji") Emoji.prepare()
            else if (value === "clipboard") Clipboard.prepare()
            visited[value] = true
        }
        mode = value
        opened = true
        publish()
    }
    function close() {
        opened = false
        publish()
    }
    function closeMode(value) { if (opened && mode === value) close() }
    function toggle(value) { if (opened && mode === value) close(); else open(value) }
    onSuppressedChanged: { if (suppressed) close() }
    Connections {
        target: MenuController
        function onActiveMenuChanged() { if (MenuController.activeMenu) root.close() }
    }
    Connections {
        target: SettingsWindowState
        function onRequestedChanged() { if (SettingsWindowState.requested) root.close() }
    }
    IpcHandler {
        target: "hub"
        function open(mode: string): void { root.open(mode) }
        function toggle(mode: string): void { root.toggle(mode) }
        function close(): void { root.close() }
        function status(): string { return JSON.stringify({opened:root.opened, mode:root.mode, suppressed:root.suppressed}) }
    }
}
