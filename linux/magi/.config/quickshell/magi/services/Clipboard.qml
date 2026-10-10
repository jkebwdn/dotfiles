pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property bool activated: false
    property bool opened: false
    property bool fullscreen: false
    property bool monitoring: false
    property bool ready: false
    property bool restoring: false
    property string error: ""
    property string query: ""
    property string renderedQuery: ""
    property string lastPreferences: ""
    property var rows: []
    property int count: 0
    readonly property var preferences: Settings.data.clipboard

    function activate() { activated = true; start() }
    function start() {
        if (!activated || !Settings.ready || worker.running) return
        ready = false
        error = ""
        worker.exec(["python3", Qt.resolvedUrl("clipboard_backend.py").toString().replace(/^file:\/\//, "")])
    }
    function send(request) {
        if (!worker.running) return
        error = ""
        worker.write(JSON.stringify(request) + "\n")
    }
    onOpenedChanged: Hub.requestVisibility("clipboard", opened)
    function prepare() { query = ""; start() }
    function open() { Hub.open("clipboard") }
    function close() { Hub.closeMode("clipboard") }
    function toggle() { Hub.toggle("clipboard") }
    function restore(id) {
        if (!ready || restoring || query !== renderedQuery) return
        restoring = true
        send({op: "restore", id: id})
    }
    function pin(id) { if (ready && query === renderedQuery) send({op: "pin", id: id}) }
    function remove(id) { if (ready && query === renderedQuery) send({op: "delete", id: id}) }
    function clear() { send({op: "clear"}) }
    function erase() { send({op: "erase"}) }
    onFullscreenChanged: { if (fullscreen) opened = false }
    onQueryChanged: searchDelay.restart()
    Timer { id: searchDelay; interval: 70; onTriggered: root.send({op: "search", query: root.query}) }
    Connections {
        target: Settings
        function onReadyChanged() { root.start() }
        function onDataChanged() {
            const next = JSON.stringify(root.preferences)
            if (root.ready && next !== root.lastPreferences) {
                root.lastPreferences = next
                root.send({op: "configure", preferences: root.preferences})
            }
        }
    }
    Process {
        id: worker
        stdinEnabled: true
        onStarted: {
            root.lastPreferences = JSON.stringify(root.preferences)
            write(JSON.stringify({preferences: root.preferences}) + "\n")
        }
        stdout: SplitParser {
            onRead: data => {
                try {
                    const response = JSON.parse(data)
                    if (response.query === root.query) {
                        root.rows = response.rows || []
                        root.renderedQuery = response.query
                    }
                    root.count = response.count || 0
                    root.monitoring = response.monitoring === true
                    root.ready = true
                    root.error = response.error || ""
                    if (response.restored) { root.opened = false; root.restoring = false }
                    if (response.error) root.restoring = false
                } catch (exception) {
                    root.error = "Clipboard backend returned an invalid response."
                }
            }
        }
        // Consume library diagnostics locally; never forward clipboard data into logs.
        stderr: StdioCollector {}
        onExited: {
            root.ready = false
            root.monitoring = false
            root.restoring = false
            root.rows = []
            root.count = 0
            if (!root.error) root.error = "Clipboard backend stopped. Open Clipboard to retry."
        }
    }
    IpcHandler {
        target: "clipboard"
        function open(): void { root.open() }
        function toggle(): void { root.toggle() }
        function close(): void { root.opened = false }
        function status(): string {
            // Deliberately no content, filenames, IDs or hashes in diagnostics.
            return JSON.stringify({ready: root.ready, monitoring: root.monitoring,
                opened: root.opened, count: root.count, fullscreen: root.fullscreen,
                persistence: root.preferences.persistHistory, error: root.error})
        }
    }
}
