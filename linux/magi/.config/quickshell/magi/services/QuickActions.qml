pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property bool powerAvailable: false
    property bool powerSaver: false
    property string powerProfile: ""
    property var powerProfiles: []
    property string previousPowerProfile: ""
    property bool vpnAvailable: false
    property bool vpnActive: false
    property string vpnName: ""
    property string vpnUuid: ""
    property bool dndAvailable: false
    property bool dndActive: false
    property bool lockAvailable: true
    property bool hibernateAvailable: false
    property bool shutdownAvailable: true
    property string error: ""
    property var queue: []
    property var activeRequest: null
    property string response: ""

    function enqueue(request) {
        if (request.op.endsWith("-status") && (activeRequest && activeRequest.op === request.op
                || queue.some(item => item.op === request.op))) return
        queue = queue.concat([request]); Qt.callLater(startNext)
    }
    function startNext() {
        if (worker.running || activeRequest || !queue.length) return
        activeRequest = queue[0]; queue = queue.slice(1); response = ""
        worker.exec(["python3", Qt.resolvedUrl("system_actions.py").toString().replace(/^file:\/\//, "")])
    }
    function refresh() {
        enqueue({op:"power-status"}); enqueue({op:"vpn-status"})
        enqueue({op:"dnd-status"}); enqueue({op:"action-status"})
    }
    function setPowerSaver(enabled) {
        if (!powerAvailable) return false
        if (enabled && !powerSaver) previousPowerProfile = powerProfile
        let target = "power-saver"
        if (!enabled) target = powerProfiles.indexOf(previousPowerProfile) >= 0 && previousPowerProfile !== "power-saver"
            ? previousPowerProfile : powerProfiles.indexOf("balanced") >= 0 ? "balanced" : "performance"
        enqueue({op:"power-set", profile:target}); return true
    }
    function toggleVpn() {
        if (!vpnAvailable || !vpnUuid) return false
        enqueue({op:"vpn-set", uuid:vpnUuid, enabled:!vpnActive}); return true
    }
    function setDnd(enabled) {
        if (!dndAvailable) return false
        enqueue({op:"dnd-set", enabled:enabled}); return true
    }
    function execute(name) {
        if (name === "lock" && !lockAvailable || name === "hibernate" && !hibernateAvailable
                || name === "shutdown" && !shutdownAvailable) return false
        enqueue({op:"action", name:name}); return true
    }
    function apply(request, result) {
        if (!result.ok) error = result.error || result.reason || "Quick action failed"
        if (request.op.indexOf("power-") === 0) {
            powerAvailable = !!result.available; powerSaver = !!result.active
            powerProfile = result.profile || ""; powerProfiles = result.profiles || []
        } else if (request.op.indexOf("vpn-") === 0) {
            vpnAvailable = !!result.available; vpnActive = !!result.active
            vpnName = result.name || ""; vpnUuid = result.uuid || ""
        } else if (request.op.indexOf("dnd-") === 0) {
            dndAvailable = !!result.available; dndActive = !!result.active
        } else if (request.op === "action-status") {
            lockAvailable = !!result.lock; hibernateAvailable = !!result.hibernate
            shutdownAvailable = !!result.shutdown
        }
    }
    Component.onCompleted: refresh()
    Timer { interval: 5000; repeat: true; running: true; onTriggered: root.refresh() }
    Process {
        id: worker
        stdinEnabled: true
        onStarted: write(JSON.stringify(root.activeRequest) + "\n")
        stdout: StdioCollector { onStreamFinished: root.response = text }
        onExited: {
            const request = root.activeRequest; root.activeRequest = null
            try { root.apply(request, JSON.parse(root.response)) }
            catch (exception) { root.error = "Quick-action adapter failed: " + String(exception) }
            Qt.callLater(root.startNext)
        }
    }
}
