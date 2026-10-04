import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    UI.SettingsWindow { id: window }
    property int step: 0
    Timer {
        interval: 500; repeat: true; running: true
        onTriggered: {
            if (!Services.Settings.ready) return
            function check(ok) { if (!ok) throw new Error("Launcher settings assertion") }
            if (step++ === 0) {
                Services.SettingsWindowState.page = "Launcher"
                Services.SettingsWindowState.shown = true
                check(Services.Settings.setValue("launcher","layout","grid"))
                check(Services.Settings.setValue("launcher","gridColumns",4))
                check(!Services.Settings.setValue("launcher","layout","invalid"))
            } else if (step === 2) {
                check(Services.Settings.data.launcher.layout === "grid")
                check(Services.Settings.saveState === "saved")
                Services.Settings.discardAndReload()
            } else if (step === 3) {
                check(Services.Settings.data.launcher.layout === "grid")
                check(Services.Settings.data.launcher.gridColumns === 4)
                check(Services.Settings.resetSection("launcher"))
            } else {
                check(Services.Settings.data.launcher.layout === "list")
                console.log("Launcher settings page, validation, persistence, reload and reset PASS")
                Qt.quit()
            }
        }
    }
}
