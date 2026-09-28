pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property int sequence: 0
    property var queue: []
    property var active: null
    property string response: ""
    readonly property string dataRoot: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/magi"
    readonly property string cacheRoot: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation) + "/magi"
    signal completed(int requestId, string operation, string assetId, string url, string error)

    function enqueue(operation, url, context) {
        const request = {id: ++sequence, op: operation, url: String(url), context: context || {}}
        queue = queue.concat([request])
        Qt.callLater(startNext)
        return request.id
    }
    function importAvatar(url) { return enqueue("avatar", url, {}) }
    function importIcon(url, role, moduleId) { return enqueue("icon", url, {role:role, moduleId:moduleId || ""}) }
    function cacheArtwork(url, token) { return enqueue("artwork", url, {token:token || ""}) }
    function assetUrl(assetId) {
        if (!assetId) return ""
        const parts = String(assetId).split(":")
        if (parts.length !== 2 || !/^[a-f0-9]{64}\.(png|jpg|webp|svg)$/.test(parts[1])) return ""
        const directory = parts[0] === "avatar" ? "avatars" : parts[0] === "icon" ? "icons" : ""
        return directory ? dataRoot + "/" + directory + "/" + parts[1] : ""
    }
    function startNext() {
        if (worker.running || active || !queue.length) return
        active = queue[0]
        queue = queue.slice(1)
        response = ""
        worker.exec(["python3", Qt.resolvedUrl("assets.py").toString().replace(/^file:\/\//, "")])
    }
    Process {
        id: worker
        stdinEnabled: true
        onStarted: write(JSON.stringify(root.active) + "\n")
        stdout: StdioCollector { onStreamFinished: root.response = text }
        onExited: {
            const request = root.active
            root.active = null
            try {
                const result = JSON.parse(root.response)
                root.completed(request.id, request.op, result.assetId || "", result.url || "", result.ok ? "" : result.error)
            } catch (error) {
                root.completed(request.id, request.op, "", "", "Asset helper failed: " + String(error))
            }
            Qt.callLater(root.startNext)
        }
    }
}
