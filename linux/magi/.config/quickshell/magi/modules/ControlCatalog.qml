pragma Singleton
import QtQuick
import "../services" as Services
import "../icons" as Icons
import "../settings/SettingsSchema.js" as Schema

QtObject {
    property Connections wifiObserver: Connections {
        target: Services.Network
        function onWifiEnabledChanged() {
            if (Services.AirplaneMode.active && Services.Network.wifiEnabled)
                Services.AirplaneMode.cancel()
        }
    }
    property Connections bluetoothObserver: Connections {
        target: Services.Bluetooth
        function onEnabledChanged() {
            if (Services.AirplaneMode.active && Services.Bluetooth.enabled)
                Services.AirplaneMode.cancel()
        }
    }
    readonly property var definitions: Schema.controlDefinitions()
    function isToggle(id) { return ["wifi", "bluetooth", "power-saver", "airplane-mode", "vpn", "dnd", "caffeine"].indexOf(id) >= 0 }
    function definition(id) { return definitions.find(d => d.id === id) || null }
    function supports(id, presentation) {
        const item = definition(id)
        return !!item && item.presentations.indexOf(presentation) >= 0
    }
    function forPresentation(presentation) {
        return definitions.filter(item => item.presentations.indexOf(presentation) >= 0)
    }
    function state(id) {
        const descriptor = definition(id)
        if (!descriptor) return {available:false, active:false, icon:"missing", status:"Unavailable"}
        if (descriptor.route === "hub") return {available:Services.Hub.available(descriptor.mode),
            active:false, icon:descriptor.icon, status:"Open in MAGI Hub"}
        if (descriptor.route === "system") return {
            available:Services.QuickActions.actionAvailable(id),
            active:Services.ActionConfirmation.armedAction === id, icon:descriptor.icon,
            status:Services.ActionConfirmation.armedAction === id ? "Click again to confirm" : ""}
        if (id === "wifi") return {available:Services.Network.wifiHardwareEnabled,
            active:Services.Network.wifiEnabled, icon:Services.Network.wifiEnabled ? "wifi" : "wifi-off",
            status:Services.Network.connected ? Services.Network.ssid : Services.Network.wifiEnabled ? "On" : "Off"}
        if (id === "bluetooth") return {available:Services.Bluetooth.available,
            active:Services.Bluetooth.enabled, icon:Services.Bluetooth.enabled ? "bluetooth" : "bluetooth-off",
            status:Services.Bluetooth.connectedCount + " connected"}
        if (id === "power-saver") return {available:Services.QuickActions.powerAvailable,
            active:Services.QuickActions.powerSaver, icon:"power-saver",
            status:Services.QuickActions.powerAvailable ? Services.QuickActions.powerProfile : "Unavailable"}
        if (id === "airplane-mode") return {available:Services.Network.wifiHardwareEnabled || Services.Bluetooth.available,
            active:Services.AirplaneMode.active, icon:"airplane-mode",
            status:Services.AirplaneMode.active ? "On" : "Off"}
        if (id === "vpn") return {available:Services.QuickActions.vpnAvailable,
            active:Services.QuickActions.vpnActive, icon:"vpn",
            status:Services.QuickActions.vpnAvailable ? Services.QuickActions.vpnName : "No profile"}
        if (id === "dnd") return {available:Services.QuickActions.dndAvailable,
            active:Services.QuickActions.dndActive, icon:"dnd",
            status:Services.QuickActions.dndAvailable ? (Services.QuickActions.dndActive ? "On" : "Off") : "Unavailable"}
        if (id === "caffeine") return {available:Services.Caffeine.bound,
            active:Services.Caffeine.active, icon:"caffeine", status:Services.Caffeine.active ? "On" : "Off"}
        if (id === "battery") return {available:Services.Battery.available, active:Services.Battery.available,
            icon:Icons.IconRegistry.batteryRole(Services.Battery.available, Services.Battery.charging, Services.Battery.percentage),
            status:Services.Battery.percentage + "%"}
        if (id === "volume") return {available:Services.Audio.available, active:!Services.Audio.muted,
            icon:Icons.IconRegistry.volumeRole(Services.Audio.available,Services.Audio.muted,Services.Audio.volumePercent),
            status:Services.Audio.muted ? "Muted" : Services.Audio.volumePercent + "%"}
        if (id === "brightness") return {available:Services.Brightness.available, active:Services.Brightness.available,
            icon:"brightness", status:Services.Brightness.percent + "%"}
        return {available:true, active:true, icon:"settings", status:"Open Settings"}
    }
    function primary(id) {
        const descriptor = definition(id)
        if (!descriptor || !state(id).available) return
        if (descriptor.route === "hub") { Services.Hub.open(descriptor.mode); return }
        if (descriptor.route === "settings") { Services.SettingsWindowState.open(); return }
        if (descriptor.route === "system") {
            if (!descriptor.confirmation || Services.ActionConfirmation.request(id))
                Services.QuickActions.execute(id)
            return
        }
        if (id === "wifi") Services.Network.setWifiEnabled(!Services.Network.wifiEnabled)
        else if (id === "bluetooth") Services.Bluetooth.setEnabled(!Services.Bluetooth.enabled)
        else if (id === "power-saver") Services.QuickActions.setPowerSaver(!Services.QuickActions.powerSaver)
        else if (id === "airplane-mode") {
            if (!Services.AirplaneMode.active) {
                Services.AirplaneMode.begin(Services.Network.wifiEnabled, Services.Bluetooth.enabled)
                if (Services.Network.wifiEnabled) Services.Network.setWifiEnabled(false)
                if (Services.Bluetooth.enabled) Services.Bluetooth.setEnabled(false)
            } else {
                const restore = Services.AirplaneMode.end()
                if (restore.wifi && Services.Network.wifiHardwareEnabled) Services.Network.setWifiEnabled(true)
                if (restore.bluetooth && Services.Bluetooth.available) Services.Bluetooth.setEnabled(true)
            }
        }
        else if (id === "vpn") Services.QuickActions.toggleVpn()
        else if (id === "dnd") Services.QuickActions.setDnd(!Services.QuickActions.dndActive)
        else if (id === "caffeine") Services.Caffeine.setRequested(!Services.Caffeine.requested)
    }
    function secondary(id) {
        const descriptor = definition(id)
        if (descriptor && descriptor.detail) Services.MenuController.navigate(descriptor.detail)
    }
}
