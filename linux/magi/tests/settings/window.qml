import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    function check(ok,label) { if (!ok) { failures++; console.error("FAIL: " + label) } }
    UI.SettingsApplication { id: app; readyToOpen: true }
    Timer {
        interval: 600; running: true; repeat: true
        onTriggered: {
            if (!Services.Settings.ready) return
            switch (test.step++) {
            case 0: Services.SettingsWindowState.open(); break
            case 1:
                test.check(Services.SettingsWindowState.shown, "window opens")
                Services.Settings.setTheme("catppuccin-latte")
                Services.Settings.setRoundness("surface",.5)
                break
            case 2: Services.SettingsWindowState.page = "Bar"; break
            case 3:
                Services.Settings.placeBar("bluetooth","hidden")
                Services.SettingsWindowState.page = "Control Centre"
                break
            case 4:
                Services.Settings.addControl("settings")
                Services.Settings.setValue("controlCentre","columns",5)
                Services.SettingsWindowState.shown = false
                break
            case 5:
                test.check(Services.Settings.saveState === "saved", "save completes after close")
                Services.Settings.discardAndReload()
                break
            case 6: Services.SettingsWindowState.open(); break
            case 7:
                test.check(Services.SettingsWindowState.shown && Services.Settings.data.appearance.theme === "catppuccin-latte"
                    && Services.Settings.data.appearance.roundness.roles.surface === .5
                    && Services.Settings.data.controlCentre.columns === 5, "reopen preserves saved edits")
                Services.SettingsWindowState.page = "Appearance"
                break
            case 8:
                Services.SettingsWindowState.shown = false
                app.readyToOpen = false
                Services.SettingsWindowState.open()
                break
            case 9:
                test.check(Services.SettingsWindowState.requested && !Services.SettingsWindowState.shown, "busy interaction defers window")
                app.readyToOpen = true
                break
            case 10:
                test.check(Services.SettingsWindowState.shown, "deferred request opens when safe")
                console.log("RESULT: " + test.failures + " failures; Settings window integration")
                Qt.quit()
            }
        }
    }
}
