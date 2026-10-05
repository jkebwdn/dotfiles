import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    property int step: 0
    Timer {
        interval: 350; repeat: true; running: true
        onTriggered: {
            if (!Services.Settings.ready || !Services.Emoji.entries.length) return
            if (step++ === 0) {
                Services.Emoji.open(); Services.Emoji.query = "fire"; Services.Emoji.choose(0)
                Services.Emoji.close(); Services.Emoji.open(); Services.Emoji.query = "heart"
                // A new selection cannot overwrite the in-flight sequence.
                Services.Emoji.choose(0)
            } else {
                if (Services.Emoji.busy) { step--; return }
                if (!Services.Emoji.opened || Services.Emoji.query !== "heart" || Services.Emoji.error
                        || Services.Settings.data.emoji.recents[0] !== "1F525")
                    throw new Error("Stale copy completion changed the new picker session")
                console.log("Emoji in-flight selection snapshot and reopen race PASS")
                Qt.quit()
            }
        }
    }
}
