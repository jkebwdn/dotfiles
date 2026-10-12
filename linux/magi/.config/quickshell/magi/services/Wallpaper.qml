pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root
    readonly property var preferences: Settings.data.wallpaper
    readonly property string directoriesKey: JSON.stringify(preferences.directories)
    onDirectoriesKeyChanged: { scanPending = true; Qt.callLater(drain) }
    readonly property bool enabled: preferences.enabled
    onEnabledChanged: {
        if (!enabled) close()
        else if (initialized) { restorePending = true; Qt.callLater(drain) }
    }
    property bool opened: false
    property bool initialized: false
    property bool startupRetryAvailable: true
    property bool busy: false
    property bool scanPending: false
    property bool restorePending: false
    property bool libraryLoaded: false
    property string error: ""
    property string message: ""
    property var warnings: []
    property var entries: []
    property var monitors: []
    property var currentByMonitor: ({})
    property bool currentKnown: false
    property var state: ({shared:null, monitors:{}, favourites:[], recents:[]})
    property string scope: ""
    onScopeChanged: {
        const saved = state.monitors[scope] || state.shared
        mode = saved ? saved.mode : "cover"
    }
    property string mode: "cover"
    property string filter: "All"
    property var pending: null
    property var pendingSelection: null
    readonly property string currentPath: {
        if (!currentKnown) return ""
        if (scope) return currentByMonitor[scope] || ""
        const paths = Object.values(currentByMonitor)
        return paths.length && paths.every(p => p === paths[0]) ? paths[0] : ""
    }
    readonly property var results: {
        if (filter === "Favourites" || filter === "Recents") {
            const paths = filter === "Favourites" ? state.favourites : state.recents
            return paths.map(p => entries.find(e => e.path === p)
                || {path:p, name:p.split("/").pop(), url:"file://" + p.split("/").map(encodeURIComponent).join("/"), outsideLibrary:true})
        }
        return entries
    }
    // Future Theme Orchestrator entry point: confirmed state only, no theme coupling.
    signal selectionChanged(string path, string monitor, var assignments)

    function open() {
        if (!Settings.ready || !preferences.enabled) return
        Hub.close(); MenuController.close()
        const saved = scope ? state.monitors[scope] : state.shared
        mode = saved ? saved.mode : "cover"
        opened = true
        if (!libraryLoaded) scanPending = true
        if (!busy) start({op:"status"})
    }
    function close() { opened = false }
    function refresh() { scanPending = true; drain() }
    function restore() { restorePending = true; drain() }
    function start(request) {
        if (busy) return false
        busy = true; pending = request; message = ""
        if (request.op !== "scan" && request.op !== "load") error = ""
        worker.running = true
        return true
    }
    function drain() {
        if (busy || !initialized || !Settings.ready || !preferences.enabled) return
        if (restorePending) { restorePending = false; start({op:"restore"}); return }
        if (scanPending) {
            scanPending = false
            start({op:"scan", directories:preferences.directories})
        }
    }
    function choose(path) {
        if (busy || !preferences.enabled) return
        busy = true; error = ""; message = ""
        pendingSelection = {op:"apply", path:path, monitor:scope, mode:mode}
        // Decode at a bounded size before handing a potentially corrupt file to hyprpaper.
        preflight.source = ""
        preflight.source = "file://" + path.split("/").map(encodeURIComponent).join("/")
    }
    function favourite(path) { if (!busy) start({op:"favourite", path:path}) }
    function random() {
        const candidates = results.filter(e => !e.outsideLibrary)
        if (candidates.length) choose(candidates[Math.floor(Math.random() * candidates.length)].path)
    }
    function initialize() {
        if (!Settings.ready || initialized || busy) return
        start({op:"load"})
    }
    onMonitorsChanged: { if (scope && !monitors.some(m => m.name === scope)) scope = "" }
    Component.onCompleted: Qt.callLater(initialize)
    Connections { target: Settings; function onReadyChanged() { root.initialize() } }
    Connections { target: SettingsWindowState; function onRequestedChanged() { if (SettingsWindowState.requested) root.close() } }
    Connections { target: Hub; function onOpenedChanged() { if (Hub.opened) root.close() } }
    Connections { target: MenuController; function onActiveMenuChanged() { if (MenuController.activeMenu) root.close() } }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["monitoradded", "monitoraddedv2", "monitorremoved"].indexOf(event.name) >= 0) topology.restart()
        }
    }
    Timer { id: topology; interval: 700; onTriggered: root.restore() }
    // A single delayed startup retry accommodates daemon startup ordering.
    Timer { id: startupRetry; interval: 3000; onTriggered: root.restore() }
    Image {
        id: preflight
        visible: false; asynchronous: true; cache: false; sourceSize: Qt.size(32, 32)
        onStatusChanged: {
            if (!root.pendingSelection) return
            if (status === Image.Ready) {
                const request = root.pendingSelection; root.pendingSelection = null
                root.busy = false
                if (root.preferences.enabled) root.start(request)
                else root.drain()
            } else if (status === Image.Error) {
                root.pendingSelection = null; root.busy = false
                root.error = "This image is missing or Qt could not decode it. The wallpaper was not changed."
            }
        }
    }
    Process {
        id: worker
        command: ["python3", "-B", Qt.resolvedUrl("wallpaper_state.py").toString().replace(/^file:\/\//, "")]
        stdinEnabled: true
        onStarted: { write(JSON.stringify(root.pending) + "\n"); stdinEnabled = false }
        stdout: StdioCollector { id: output }
        stderr: StdioCollector { id: errors }
        onExited: (code, status) => {
            const request = root.pending
            try {
                if (code !== 0) throw new Error(errors.text || "Wallpaper worker failed")
                const result = JSON.parse(output.text)
                if (result.state) root.state = result.state
                if (result.monitors) root.monitors = result.monitors
                if (result.current) { root.currentByMonitor = result.current; root.currentKnown = !result.currentUnknown }
                if (result.entries) { root.entries = result.entries; root.libraryLoaded = true }
                if (result.warnings) root.warnings = result.warnings
                if (!result.ok) {
                    if (!result.current && ["status", "restore", "apply"].indexOf(request.op) >= 0) root.currentKnown = false
                    root.error = result.error
                } else if (request.op === "apply") {
                    root.message = "Wallpaper applied and saved"
                    root.selectionChanged(request.path, request.monitor, root.currentByMonitor)
                }
            } catch (exception) { root.error = String(exception) }
            root.busy = false; root.pending = null; stdinEnabled = true
            if (request.op === "load") {
                root.initialized = true
                if (root.preferences.enabled) { root.restorePending = true; root.scanPending = true }
            }
            if (request.op === "restore" && root.startupRetryAvailable) {
                root.startupRetryAvailable = false
                if (root.error) startupRetry.start()
            }
            Qt.callLater(root.drain)
        }
    }
    IpcHandler {
        target: "wallpaper"
        function open(): void { root.open() }
        function close(): void { root.close() }
        function toggle(): void { if (root.opened) root.close(); else root.open() }
        function refresh(): void { root.refresh() }
        function restore(): void { root.restore() }
        function status(): string {
            return JSON.stringify({opened:root.opened, busy:root.busy, current:root.currentByMonitor,
                currentKnown:root.currentKnown, state:root.state, count:root.entries.length, error:root.error})
        }
    }
}
