pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as Services
import "IconResolver.js" as Resolver
Scope {
    id: root
    readonly property var builtInRegistry: JSON.parse(data.text())
    property var managedPacks: []
    readonly property var registry: ({formatVersion: builtInRegistry.formatVersion,
        packs: builtInRegistry.packs.concat(managedPacks)})
    readonly property var packs: registry.packs
    property string packResponse: ""
    function resolve(role, moduleId) {
        return Resolver.resolve(registry, Services.Settings.data.icons, role, moduleId || "")
    }
    function signalRole(strength) {
        return strength >= 75 ? "wifi-high" : strength >= 50 ? "wifi-medium"
            : strength >= 25 ? "wifi-low" : "wifi-weak"
    }
    function volumeRole(available, muted, percent) {
        return !available || muted || percent === 0 ? "volume-muted"
            : percent < 34 ? "volume-low" : percent < 67 ? "volume-medium" : "volume"
    }
    function batteryRole(available, charging, percent) {
        return !available ? "battery-unknown" : charging ? "battery-charging"
            : percent >= 95 ? "battery" : "battery-" + Math.max(0, Math.min(90, Math.floor((percent + 5) / 10) * 10))
    }
    FileView { id: data; path: Qt.resolvedUrl("packs/registry.json"); blockLoading: true }
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
                root.managedPacks = result.ok ? result.packs : []
            } catch (exception) { root.managedPacks = [] }
        }
    }
}
