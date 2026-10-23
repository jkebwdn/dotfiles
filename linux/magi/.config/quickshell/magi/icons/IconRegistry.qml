pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as Services
import "IconResolver.js" as Resolver
import "IconState.js" as State
Scope {
    id: root
    property var packs: []
    readonly property var registry: ({packs: packs})
    property string packResponse: ""
    function resolve(role, skipSelected) {
        return Resolver.resolve(registry, Services.Settings.data.icons, role, skipSelected)
    }
    function resolvePack(role, pack) {
        return Resolver.resolve(registry, {pack: pack}, role, false)
    }
    function signalRole(strength) {
        return State.signalRole(strength)
    }
    function volumeRole(available, muted, percent) {
        return State.volumeRole(available, muted, percent)
    }
    function batteryRole(available, charging, percent) {
        return State.batteryRole(available, charging, percent)
    }
    function reloadManaged() {
        if (packWorker.running) return
        packResponse = ""
        packWorker.exec(["python3", Qt.resolvedUrl("../services/assets.py").toString().replace(/^file:\/\//, "")])
    }
    Component.onCompleted: reloadManaged()
    Connections {
        target: Services.AssetManager
        function onCompleted(requestId, operation, assetId, url, error) {
            if (operation === "icon-pack" && !error) root.reloadManaged()
        }
    }
    Process {
        id: packWorker
        stdinEnabled: true
        onStarted: write('{"op":"pack-list"}\n')
        stdout: StdioCollector { onStreamFinished: root.packResponse = text }
        onExited: {
            try {
                const result = JSON.parse(root.packResponse)
                root.packs = result.ok ? result.packs : []
            } catch (exception) { root.packs = [] }
        }
    }
}
