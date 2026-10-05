pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "EmojiSearch.js" as Search
Scope {
    id: root
    readonly property var preferences: Settings.data.emoji
    property bool opened: false
    property bool suppressed: false
    property string query: ""
    property string category: "All"
    property string error: ""
    property string dataError: ""
    property string message: ""
    property var entries: []
    property int selected: 0
    property int session: 0
    property int pendingSession: -1
    property string pendingId: ""
    property string pendingSequence: ""
    property bool busy: false
    readonly property var categories: ["All", "Recently Used"].concat(Search.categories(entries))
    readonly property var results: Search.rank(entries, query, category, preferences.recents.slice(0, preferences.recentLimit))
    onResultsChanged: selected = 0
    onQueryChanged: message = ""
    onPreferencesChanged: { if (!preferences.enabled) close() }
    onSuppressedChanged: { if (suppressed) close() }
    function open() {
        if (!Settings.ready || !preferences.enabled || suppressed) return
        MenuController.close()
        Notifications.centreOpen = false
        Clipboard.opened = false
        Launcher.close()
        session++
        query = ""; selected = 0; error = ""; message = ""
        category = preferences.recentLimit && preferences.recents.some(id => entries.some(e => e.id === id)) ? "Recently Used" : "All"
        opened = true
    }
    function close() { opened = false; session++ }
    function toggle() { if (opened) close(); else open() }
    function move(delta) { selected = Math.max(0, Math.min(results.length - 1, selected + delta)) }
    function chooseCategory(value) { category = value; query = "" }
    function choose(index) {
        const sequence = Search.sequenceAt(results, index)
        if (!opened || busy || !sequence) return
        pendingSequence = sequence; pendingId = results[index].id; pendingSession = session
        error = ""; message = ""
        // Process.running becomes true asynchronously; guard same-turn selections now.
        busy = true
        copyProcess.running = true
    }
    FileView {
        path: Qt.resolvedUrl("../data/emoji/emoji.json").toString().replace(/^file:\/\//, "")
        onLoaded: {
            try { root.entries = Search.prepare(JSON.parse(text())); root.dataError = "" }
            catch (e) { root.dataError = "Could not load the Emoji dataset." }
        }
        onLoadFailed: root.dataError = "Emoji dataset is unavailable."
    }
    Process {
        id: copyProcess
        command: ["python3", Qt.resolvedUrl("clipboard_backend.py").toString().replace(/^file:\/\//, ""), "--copy-text"]
        stdinEnabled: true
        onStarted: write(JSON.stringify({text:root.pendingSequence}) + "\n")
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (code === 0) {
                if (root.preferences.recentLimit > 0)
                    Settings.setValue("emoji", "recents", Search.promote(root.preferences.recents, root.pendingId, root.preferences.recentLimit))
                if (root.session === root.pendingSession) {
                    root.message = "Copied — paste in your application"
                    if (root.preferences.closeOnSelect) root.close()
                }
            } else if (root.session === root.pendingSession) root.error = "Could not copy emoji. Try again."
            root.busy = false
        }
    }
    IpcHandler {
        target: "emoji"
        function open(): void { root.open() }
        function close(): void { root.close() }
        function toggle(): void { root.toggle() }
        function status(): string { return JSON.stringify({opened:root.opened, count:root.results.length, selected:root.selected, busy:root.busy, error:root.error || root.dataError}) }
    }
}
