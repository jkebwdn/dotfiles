pragma Singleton
import QtQuick
import "../services" as Services
import "../icons" as Icons
QtObject {
    readonly property var definitions: [
        {id:"wifi", label:"Wi-Fi", icon:"wifi", accent:"teal", detail:"wifi"},
        {id:"battery", label:"Battery status", icon:"battery", accent:"red", detail:""},
        {id:"volume", label:"Mute / sound", icon:"volume", accent:"peach", detail:"volume"},
        {id:"bluetooth", label:"Bluetooth", icon:"bluetooth", accent:"blue", detail:"bluetooth"},
        {id:"settings", label:"Settings", icon:"settings", accent:"lavender", detail:""},
        {id:"volume-down", label:"Volume down", icon:"volume-low", accent:"peach", detail:"volume"},
        {id:"volume-up", label:"Volume up", icon:"volume", accent:"peach", detail:"volume"},
        {id:"brightness-down", label:"Brightness down", icon:"brightness", accent:"yellow", detail:""},
        {id:"brightness-up", label:"Brightness up", icon:"brightness", accent:"yellow", detail:""}
    ]
    function definition(id) { return definitions.find(d => d.id === id) || null }
    function state(id) {
        if (id === "wifi") return {available:Services.Network.wifiHardwareEnabled,
            active:Services.Network.wifiEnabled, icon:Services.Network.wifiEnabled ? "wifi" : "wifi-off",
            status:Services.Network.connected ? Services.Network.ssid : Services.Network.wifiEnabled ? "On" : "Off"}
        if (id === "bluetooth") return {available:Services.Bluetooth.available,
            active:Services.Bluetooth.enabled, icon:Services.Bluetooth.enabled ? "bluetooth" : "bluetooth-off",
            status:Services.Bluetooth.connectedCount + " connected"}
        if (id === "battery") return {available:Services.Battery.available, active:Services.Battery.available,
            icon:Icons.IconRegistry.batteryRole(Services.Battery.available, Services.Battery.charging, Services.Battery.percentage),
            status:Services.Battery.percentage + "%"}
        if (id.indexOf("volume") === 0) return {available:Services.Audio.available, active:!Services.Audio.muted,
            icon:id === "volume" ? Icons.IconRegistry.volumeRole(Services.Audio.available,Services.Audio.muted,Services.Audio.volumePercent) : definition(id).icon,
            status:Services.Audio.muted ? "Muted" : Services.Audio.volumePercent + "%"}
        if (id.indexOf("brightness") === 0) return {available:Services.Brightness.available, active:Services.Brightness.available,
            icon:"brightness", status:Services.Brightness.percent + "%"}
        return {available:true, active:true, icon:"settings", status:"Open Settings"}
    }
    function primary(id) {
        if (id === "wifi") Services.Network.setWifiEnabled(!Services.Network.wifiEnabled)
        else if (id === "bluetooth") Services.Bluetooth.setEnabled(!Services.Bluetooth.enabled)
        else if (id === "volume") Services.Audio.toggleMute()
        else if (id === "volume-down" || id === "volume-up")
            Services.Audio.setVolume(Math.max(0, Math.min(1, Services.Audio.volume + (id === "volume-up" ? .05 : -.05))))
        else if (id === "brightness-down" || id === "brightness-up")
            Services.Brightness.setPercent(Math.max(0, Math.min(100, Services.Brightness.percent + (id === "brightness-up" ? 5 : -5))))
        else if (id === "settings") Services.SettingsWindowState.open()
    }
    function secondary(id) {
        const d = definition(id)
        if (d && d.detail) Services.MenuController.navigate(d.detail)
    }
}
