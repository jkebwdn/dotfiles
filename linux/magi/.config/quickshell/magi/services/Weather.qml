pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    readonly property var preferences: Settings.data.weather
    readonly property string configuration: JSON.stringify(preferences)
    readonly property string summary: eligible && observationKey === configuration
        && Date.now() - observed * 1000 <= 3 * 60 * 60 * 1000 ? observation : ""
    readonly property bool eligible: Settings.ready && preferences.enabled && preferences.location.trim().length > 0
    property string diagnostic: ""
    property string resolvedLocation: ""
    property bool activated: false
    property string activeKey: ""
    property string observationKey: ""
    property string observation: ""
    property real observed: 0
    property string response: ""
    property bool pending: false
    readonly property bool refreshing: worker.running
    function activate() { activated = true; schedule() }
    function schedule() {
        if (!activated || !Settings.ready) return
        if (!eligible) {
            pending = false; debounce.stop(); refresh.stop()
            observation = ""; resolvedLocation = ""
            diagnostic = preferences.enabled ? "Set a weather location" : "Weather is disabled"
            return
        }
        pending = true
        debounce.restart()
    }
    function start() {
        if (!pending || worker.running || !eligible) return
        pending = false; activeKey = configuration; response = ""
        worker.exec(["python3", Qt.resolvedUrl("weather.py").toString().replace(/^file:\/\//, "")])
    }
    onConfigurationChanged: Qt.callLater(schedule)
    onEligibleChanged: Qt.callLater(schedule)
    Connections { target: Settings; function onReadyChanged() { root.schedule() } }
    Timer { id: debounce; interval: 750; onTriggered: root.start() }
    Timer { id: refresh; interval: 30 * 60 * 1000; onTriggered: root.schedule() }
    Timer { id: timeout; interval: 20000; onTriggered: worker.running = false }
    Process {
        id: worker
        stdinEnabled: true
        onStarted: { write(root.activeKey + "\n"); timeout.restart() }
        stdout: StdioCollector { onStreamFinished: root.response = text }
        onExited: {
            timeout.stop()
            if (root.activeKey === root.configuration && root.eligible) {
                try {
                    const result = JSON.parse(root.response)
                    root.observation = result.summary || ""
                    root.observed = result.observed || 0
                    root.observationKey = root.activeKey
                    root.resolvedLocation = result.resolvedLocation || ""
                    root.diagnostic = result.error || ""
                } catch (_) {
                    root.diagnostic = "Weather refresh unavailable"
                    if (Date.now() - root.observed * 1000 > 3 * 60 * 60 * 1000) root.observation = ""
                }
                refresh.restart()
            }
            if (root.pending) debounce.restart()
        }
    }
}
