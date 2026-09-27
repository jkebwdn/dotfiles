pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as Services
import "IconResolver.js" as Resolver
Scope {
    readonly property var registry: JSON.parse(data.text())
    readonly property var packs: registry.packs
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
}
