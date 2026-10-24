pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
Scope {
    id: root
    // Activated by the shell; neutral policy publishes no application override.
    property bool active: false
    property bool busy: false
    property bool pending: false
    property string status: "review"
    property string error: ""
    property var request: null
    property var outcome: null
    readonly property string desired: JSON.stringify(Settings.data.applicationAppearance)
    onDesiredChanged: if (active) schedule()
    function activate() { active = true; schedule() }
    function schedule() { pending = true; debounce.restart() }
    function reconcile() {
        if (!active || !Settings.ready || busy || !pending) return
        pending = false; busy = true
        request = {op:"application-appearance", theme:Settings.data.appearance.theme, policy:JSON.parse(desired)}
        worker.running = true
    }
    Socket {
        id: events
        path: root.active ? Hyprland.eventSocketPath : ""
        connected: root.active && path.length > 0
        parser: SplitParser { onRead: data => { if (data.split(">>")[0] === "configreloaded") root.schedule() } }
        onConnectionStateChanged: if (connected && root.active) root.schedule()
    }
    Timer { id: debounce; interval: 450; onTriggered: root.reconcile() }
    Connections { target: Settings; function onReadyChanged() { if (root.active) root.schedule() } }
    Process {
        id: worker
        command: ["python3", "-B", Qt.resolvedUrl("theme_backend.py").toString().replace(/^file:\/\//, "")]
        stdinEnabled: true
        onStarted: { write(JSON.stringify(root.request) + "\n"); stdinEnabled = false }
        stdout: StdioCollector { id: output }
        stderr: StdioCollector { id: errors }
        onExited: (code, exitStatus) => {
            try {
                if (code !== 0) throw new Error(errors.text || "Application appearance worker failed")
                const result = JSON.parse(output.text)
                root.outcome = result
                root.status = result.status || "error"; root.error = result.error || ""
            } catch (e) { root.status = "error"; root.error = String(e) }
            root.busy = false; stdinEnabled = true
            if (root.pending) debounce.restart()
        }
    }
}
