import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    property int step: 0
    Timer {
        interval: 350; running: true; repeat: true
        onTriggered: {
            if (!Services.Settings.ready) return
            function check(ok) { if (!ok) throw new Error("Launcher service assertion at " + step) }
            switch (step++) {
            case 0: Services.Launcher.open(); break
            case 1:
                check(Services.Launcher.opened && Services.Launcher.results.length > 0)
                Services.Launcher.query = "no-match-fixture-string"
                check(Services.Launcher.results.length === 0)
                Services.Launcher.launch(0); check(!Services.Launcher.busy)
                Services.Launcher.close(); Services.Launcher.open()
                check(Services.Launcher.query === "" && Services.Launcher.selected === 0)
                break
            case 2:
                Services.Settings.setValue("launcher","enabled",false)
                check(!Services.Launcher.opened)
                Services.Launcher.open(); check(!Services.Launcher.opened)
                Services.Settings.setValue("launcher","enabled",true)
                Services.Launcher.open()
                break
            case 3:
                Services.Launcher.query = "MAGI Launch Fixture"
                check(Services.Launcher.results.length === 1)
                Services.Launcher.launch(0)
                break
            case 4:
                check(!Services.Launcher.opened && !Services.Launcher.error)
                check(Services.Launcher.history["magi-test.desktop"] === 1)
                console.log("Launcher service discovery, reset, disable, desktop launch and history PASS")
                Qt.quit()
            }
        }
    }
}
