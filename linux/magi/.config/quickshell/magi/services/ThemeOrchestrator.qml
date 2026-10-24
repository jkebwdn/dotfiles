pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme" as Palette

Scope {
    id: root
    property bool active: false
    property bool busy: false
    property var targets: []
    property var plan: null
    property string error: ""
    property string summary: ""
    property var request: null
    property bool applyPending: false
    readonly property string selectedTheme: Palette.ThemeRegistry.resolve(Settings.data.appearance.theme).id
    readonly property string zenWorkspaceColor: Palette.ThemeRegistry.resolve(selectedTheme).roles.background
    property bool copyingZenColor: false
    property string copiedZenColor: ""
    property string copyMessage: ""
    onSelectedThemeChanged: {
        copyMessage = ""
        if (active) { applyPending = true; settle.restart() }
    }
    function copyZenWorkspaceColor() {
        if (copyingZenColor) return
        copiedZenColor = zenWorkspaceColor
        copyMessage = ""
        copyingZenColor = true
        copyColor.running = true
    }
    Process {
        id: copyColor
        // Reuse the same bounded stdin-only clipboard helper as Emoji.
        command: ["python3", Qt.resolvedUrl("clipboard_backend.py").toString().replace(/^file:\/\//, ""), "--copy-text"]
        stdinEnabled: true
        onStarted: write(JSON.stringify({text:root.copiedZenColor}) + "\n")
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (root.copiedZenColor === root.zenWorkspaceColor)
                root.copyMessage = code === 0 ? "Copied" : "Copy failed — try again"
            root.copyingZenColor = false
        }
    }

    readonly property var starshipTarget: targets.find(t => t.id === "starship" && t.enabled)
    FileView {
        path: root.starshipTarget ? root.starshipTarget.path : ""
        watchChanges: true
        printErrors: false
        onFileChanged: { root.applyPending = true; settle.restart() }
    }

    function activate() { active = true; applyPending = true; settle.restart() }
    // Settle external activation; the internal MAGI palette stays reactive.
    Timer { id: settle; interval: 450; onTriggered: root.drain() }
    function drain() {
        if (!active || !Settings.ready || busy || !applyPending || settle.running) return
        applyPending = false
        start({op:"apply"})
    }
    function start(value) {
        if (busy || !Settings.ready) return
        value.theme = selectedTheme
        request = value; busy = true; error = ""
        worker.running = true
    }
    function targetError(id, message) {
        targets = targets.map(t => t.id === id ? Object.assign({}, t, {error:message}) : t)
    }
    function follow(id) {
        const row = targets.find(t => t.id === id)
        if (!row || busy) return
        if (row.installed) { start({op:"resume", target:id}); return }
        preview(id, row.confirmedProfile || "")
    }
    function preview(id, profile) {
        if (busy) return
        targetError(id, "")
        plan = null
        start({op:"plan", target:id, options:id === "zen" ? {confirmedProfile:profile} : {}})
    }
    function enable() {
        if (!plan) return
        start({op:"enable", target:plan.target, token:plan.token, options:plan.options})
        plan = null
    }
    function disable(id) { plan = null; start({op:"disable", target:id}) }
    function retry(id) { start({op:"retry", target:id}) }
    function refresh() { start({op:"status"}) }
    Connections { target: Settings; function onReadyChanged() { root.drain() } }
    Process {
        id: worker
        command: ["python3", "-B", Qt.resolvedUrl("theme_backend.py").toString().replace(/^file:\/\//, "")]
        stdinEnabled: true
        onStarted: { write(JSON.stringify(root.request) + "\n"); stdinEnabled = false }
        stdout: StdioCollector { id: output }
        stderr: StdioCollector { id: errors }
        onExited: (code, status) => {
            try {
                if (code !== 0) throw new Error(errors.text || "Theme worker failed")
                const result = JSON.parse(output.text)
                if (!result.ok) throw new Error(result.error)
                // Never display an old palette result as the latest selection.
                if (root.request.theme === root.selectedTheme) {
                    if (result.targets) root.targets = result.targets
                    if (result.summary) root.summary = result.summary
                    if (result.plan) root.plan = result.plan
                } else root.applyPending = true
            } catch (exception) {
                if (root.request.theme === root.selectedTheme) {
                    root.error = String(exception)
                    if (root.request.target) root.targetError(root.request.target, root.error)
                    root.plan = null
                } else root.applyPending = true
            }
            root.busy = false; root.request = null; stdinEnabled = true
            Qt.callLater(root.drain)
        }
    }
    IpcHandler {
        target: "systemTheme"
        function status(): string { return JSON.stringify({targets:root.targets, busy:root.busy, error:root.error}) }
        function refresh(): void { root.refresh() }
        function retry(id: string): void { root.retry(id) }
        function disable(id: string): void { root.disable(id) }
    }
}
