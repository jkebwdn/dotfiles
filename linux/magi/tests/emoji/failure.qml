import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    property int step: 0
    Timer {
        interval: 350; repeat: true; running: true
        onTriggered: {
            if (!Services.Settings.ready || !Services.Emoji.entries.length) return
            if (step++ === 0) { Services.Emoji.open(); Services.Emoji.query = "fire"; Services.Emoji.choose(0) }
            else {
                if (Services.Emoji.busy) { step--; return }
                if (!Services.Emoji.opened || !Services.Emoji.error || Services.Settings.data.emoji.recents.length)
                    throw new Error("Copy failure must stay open and never promote Recents")
                Services.Emoji.close()
                console.log("Emoji clipboard failure stays open, reports error, preserves Recents PASS")
                Qt.quit()
            }
        }
    }
}
