import QtQuick
QtObject {
    id: root
    property var sourceNodes: []
    property var sink: null
    property var source: null
    readonly property var nodes: sourceNodes.filter(n => n && n.ready && n.audio)
    readonly property var outputs: nodes.filter(n => mediaClass(n) === "Audio/Sink")
    readonly property var inputs: nodes.filter(n => mediaClass(n) === "Audio/Source")
    readonly property var streams: nodes.filter(n => mediaClass(n) === "Stream/Output/Audio")
    readonly property var applications: {
        const groups = []
        for (const node of streams) {
            const p = node.properties || {}
            const identity = p["application.id"] ? "id:" + p["application.id"]
                : p["application.process.binary"] ? "binary:" + p["application.process.binary"]
                : p["application.name"] ? "name:" + p["application.name"] : ""
            let group = identity ? groups.find(g => g.key === identity) : null
            if (!group) {
                group = {key: identity, label: name(node), nodes: []}
                groups.push(group)
            }
            group.nodes.push(node)
        }
        return groups
    }
    function groupNodes(group) { return group ? group.nodes.filter(n => streams.includes(n) && usable(n)) : [] }
    function groupVolume(group) { return Math.max(0, ...groupNodes(group).map(n => n.audio.volume)) }
    function groupMuted(group) { const live = groupNodes(group); return live.length > 0 && live.every(n => n.audio.muted) }
    function setGroupVolume(group, value) {
        const live = groupNodes(group)
        for (const node of live) setNodeVolume(node, value)
        return live.length > 0
    }
    function toggleGroupMute(group) {
        const live = groupNodes(group), muted = !groupMuted(group)
        for (const node of live) node.audio.muted = muted
        return live.length > 0
    }
    readonly property bool available: usable(sink)
    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available ? sink.audio.muted : false
    readonly property int volumePercent: Math.round(volume * 100)
    property var pendingOutput: null
    property var pendingInput: null
    property string error: ""
    signal outputRequested(var node)
    signal inputRequested(var node)
    function mediaClass(node) { return node && node.properties ? node.properties["media.class"] || "" : "" }
    function usable(node) { return !!node && nodes.includes(node) && !!node.audio }
    function name(node) {
        if (!node) return "Unavailable"
        const p = node.properties || {}
        if (node.isStream) return p["application.name"] || node.description || node.nickname || "Playback stream"
        return node.description || node.nickname || p["device.description"] || "Audio device"
    }
    function detail(node, peers) {
        if (!node) return ""
        const p = node.properties || {}
        const text = node.isStream ? p["media.name"] : p["device.profile.description"] || node.nickname
        const duplicate = peers.filter(n => name(n) === name(node)).length > 1
        return (text && text !== name(node) ? text : "")
            + (duplicate ? (text && text !== name(node) ? " · " : "") + (node.isStream ? "Stream " : "Device ") + (peers.indexOf(node) + 1) : "")
    }
    function icon(node) {
        const p = node ? node.properties || {} : {}
        if (p["device.api"] === "bluez5" || p["api.bluez5.address"]) return "bluetooth"
        return "volume"
    }
    function appIcon(node) { return node && node.properties ? node.properties["application.icon-name"] || "" : "" }
    function selectOutput(node) {
        if (!outputs.includes(node) || sink === node || pendingOutput === node) return false
        error = ""; pendingOutput = node; outputTimeout.restart(); outputRequested(node); return true
    }
    function selectInput(node) {
        if (!inputs.includes(node) || source === node || pendingInput === node) return false
        error = ""; pendingInput = node; inputTimeout.restart(); inputRequested(node); return true
    }
    function setNodeVolume(node, value) {
        if (!usable(node) || !isFinite(value)) return false
        node.audio.volume = Math.round(Math.max(0, Math.min(1, value)) * 100) / 100
        return true
    }
    function toggleNodeMute(node) {
        if (!usable(node)) return false
        node.audio.muted = !node.audio.muted; return true
    }
    function setVolume(value) { return setNodeVolume(sink, value) }
    function toggleMute() { return toggleNodeMute(sink) }
    function adjustVolume(steps) { return setVolume(volume + steps * .05) }
    onSinkChanged: if (sink === pendingOutput) { pendingOutput = null; outputTimeout.stop() }
    onSourceChanged: if (source === pendingInput) { pendingInput = null; inputTimeout.stop() }
    onOutputsChanged: if (pendingOutput && !outputs.includes(pendingOutput)) { pendingOutput = null; outputTimeout.stop(); error = "Output unavailable" }
    onInputsChanged: if (pendingInput && !inputs.includes(pendingInput)) { pendingInput = null; inputTimeout.stop(); error = "Input unavailable" }
    property Timer outputTimeout: Timer {
        interval: 5000
        onTriggered: { root.pendingOutput = null; root.error = "Output change was not confirmed. Try again." }
    }
    property Timer inputTimeout: Timer {
        interval: 5000
        onTriggered: { root.pendingInput = null; root.error = "Input change was not confirmed. Try again." }
    }
}
