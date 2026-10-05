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
            function check(ok) { if (!ok) throw new Error("Emoji settings assertion") }
            if (step++ === 0) {
                Services.SettingsWindowState.page = "Emoji"
                Services.SettingsWindowState.shown = true
                check(Services.Settings.setValue("emoji","emojiSize",32))
                check(Services.Settings.setValue("emoji","gridColumns",4))
                check(!Services.Settings.setValue("emoji","emojiSize",0))
            } else if (step === 2) {
                check(Services.Settings.data.emoji.emojiSize === 32)
                check(Services.Settings.saveState === "saved")
                Services.Settings.discardAndReload()
            } else if (step === 3) {
                check(Services.Settings.data.emoji.emojiSize === 32)
                check(Services.Settings.data.emoji.gridColumns === 4)
                check(Services.Settings.setValue("emoji", "recents", ["1F600","1F525"]))
                check(Services.Settings.setValue("emoji", "recentLimit", 1))
                check(Services.Settings.data.emoji.recents.length === 1)
                check(Services.Settings.setValue("emoji", "recentLimit", 24))
                check(Services.Settings.data.emoji.recents.length === 1)
                check(Services.Settings.setValue("emoji", "recentLimit", 0))
                check(Services.Settings.data.emoji.recents.length === 0)
                check(Services.Settings.resetSection("emoji"))
            } else {
                check(Services.Settings.data.emoji.emojiSize === 28)
                console.log("Emoji settings page, validation, persistence, reload and reset PASS")
                Qt.quit()
            }
        }
    }
}
