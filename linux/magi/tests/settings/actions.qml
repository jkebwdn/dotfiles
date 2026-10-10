import QtQuick
import Quickshell
import "../../.config/quickshell/magi/modules" as Modules
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    property int failures: 0
    function check(value, label) { if (!value) { failures++; console.error("FAIL: " + label) } }
    Timer {
      interval: 100; running: true
      onTriggered: {
        check(Modules.ControlCatalog.forPresentation("tile").length >= 8, "extensible primary catalogue")
        check(Modules.ControlCatalog.forPresentation("action").map(d => d.id).join(",")
            === "settings,vpn,dnd,caffeine,lock,hibernate,shutdown,reboot,apps,notifications,emoji,clipboard", "secondary catalogue")
        Modules.ControlCatalog.primary("unknown")
        Modules.ControlCatalog.primary("hibernate")
        check(Services.QuickActions.executed.length === 0, "unknown and unavailable actions do nothing")
        Modules.ControlCatalog.primary("reboot")
        check(Services.QuickActions.executed.length === 0 && Services.ActionConfirmation.armedAction === "reboot", "reboot only arms on first click")
        Modules.ControlCatalog.primary("reboot")
        check(Services.QuickActions.executed.join(",") === "reboot", "reboot confirmed dispatch")
        check(!Modules.ControlCatalog.state("power-saver").available, "unavailable power backend is honest")
        check(!Modules.ControlCatalog.state("vpn").available, "unavailable VPN is honest")
        Services.Bluetooth.available = true
        Services.Bluetooth.enabled = true
        Services.Network.wifiEnabled = true
        Services.Network.setWifiEnabled(false)
        check(!Services.Network.wifiEnabled, "network service test boundary")
        Services.Network.setWifiEnabled(true)
        Services.Bluetooth.setEnabled(false)
        check(!Services.Bluetooth.enabled, "Bluetooth service test boundary")
        Services.Bluetooth.setEnabled(true)
        check(Services.Network.wifiEnabled && Services.Bluetooth.enabled, "radio boundaries restore")
        Modules.ControlCatalog.primary("airplane-mode")
        check(Services.AirplaneMode.active, "airplane state active")
        check(Services.AirplaneMode.priorWifi && Services.AirplaneMode.priorBluetooth,
            "airplane snapshots radio state")
        check(!Services.Network.wifiEnabled, "airplane disables Wi-Fi")
        check(!Services.Bluetooth.enabled, "airplane disables Bluetooth")
        Modules.ControlCatalog.primary("airplane-mode")
        check(Services.Network.wifiEnabled && Services.Bluetooth.enabled,
            "airplane restores prior radio state")
        Services.Caffeine.setRequested(true)
        check(Modules.ControlCatalog.state("caffeine").active, "caffeine state")
        check(!Services.ActionConfirmation.request("shutdown")
            && Services.ActionConfirmation.armedAction === "shutdown", "destructive action arms")
        check(Services.ActionConfirmation.request("shutdown")
            && Services.ActionConfirmation.armedAction === "", "second activation confirms")
        check(Modules.ControlCatalog.supports("wifi","detail")
            && !Modules.ControlCatalog.supports("volume","tile"), "presentation filtering")
        console.log("RESULT: " + failures + " failures; catalogue and safe action state")
        Qt.quit()
      }
    }
}
