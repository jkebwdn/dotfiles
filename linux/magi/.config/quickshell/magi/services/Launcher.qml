pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "LauncherSearch.js" as Search
Scope {
    id: root
    readonly property var preferences: Settings.data.launcher
    property bool opened: false
    property string query: ""
    property string error: ""
    property var applications: []
    property var history: ({})
    readonly property var results: Search.rank(applications, query, history, preferences.hiddenIds)
    readonly property var hiddenApplications: preferences.hiddenIds.map(id => {
        const app = applications.find(entry => entry.id === id)
        return app || {id: id, name: id, unavailable: true}
    })
    function refresh() { if (!discovery.running) discovery.running = true }
    function hide(id) {
        if (!applications.some(app => app.id === id)) return false
        if (preferences.hiddenIds.indexOf(id) >= 0) return true
        const saved = Settings.setValue("launcher", "hiddenIds", preferences.hiddenIds.concat([id]))
        if (!saved) error = "Could not hide this application. Check Settings for details."
        return saved
    }
    function restore(id) {
        return Settings.setValue("launcher", "hiddenIds", preferences.hiddenIds.filter(hidden => hidden !== id))
    }
    property int selected: 0
    readonly property bool busy: launchProcess.running
    property string pendingId: ""
    readonly property string helper: Qt.resolvedUrl("launcher_backend.py").toString().replace(/^file:\/\//, "")
    onResultsChanged: selected = 0
    onPreferencesChanged: { if (!preferences.enabled) close() }
    onOpenedChanged: Hub.requestVisibility("apps", opened)
    function prepare() {
        query = ""; selected = 0; error = ""
        refresh()
    }
    function open() { Hub.open("apps") }
    function close() { Hub.closeMode("apps") }
    function toggle() { Hub.toggle("apps") }
    function move(delta) { selected = Math.max(0, Math.min(results.length - 1, selected + delta)) }
    function launch(index) {
        if (busy || index < 0 || index >= results.length) return
        pendingId = results[index].id
        error = ""
        launchProcess.command = ["python3", helper, "--launch", pendingId]
        launchProcess.running = true
    }
    Process {
        id: discovery
        command: ["python3", root.helper, "--list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.applications = JSON.parse(text) }
                catch (e) { root.error = "Could not read installed applications." }
            }
        }
        onExited: (code, status) => { if (code !== 0) root.error = "Application discovery failed. Check python-gobject is installed." }
    }
    Process {
        id: launchProcess
        onExited: (code, status) => {
            if (code === 0) {
                const next = Object.assign({}, root.history)
                next[root.pendingId] = (next[root.pendingId] || 0) + 1
                root.history = next
                root.close()
            } else root.error = "Could not launch this application. It may have been removed or its terminal may be unavailable."
        }
    }
    IpcHandler {
        target: "launcher"
        function open(): void { root.open() }
        function close(): void { root.close() }
        function toggle(): void { root.toggle() }
        function status(): string { return JSON.stringify({opened:root.opened, count:root.results.length, query:root.query, selected:root.selected, error:root.error}) }
    }
}
