import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/emoji" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    property int step: 0
    property var service: Services.Emoji
    FloatingWindow {
        visible: true; implicitWidth: 448; implicitHeight: 408
        UI.EmojiContent { id: content; anchors.fill: parent; service: test.service }
    }
    Timer {
        interval: 400; repeat: true; running: true
        onTriggered: {
            if (!Services.Settings.ready || !test.service.entries.length) return
            function check(ok, label) { if (!ok) throw new Error("Emoji fixture: " + label + " step " + test.step) }
            switch (test.step++) {
            case 0:
                test.service.open(); content.focusSearch()
                check(content.searchField.activeFocus, "focus")
                check(test.service.results.length === 3944, "loading")
                test.service.query = "fire"
                check(test.service.results[0].emoji === "🔥", "filter")
                content.navigate(Qt.Key_Down, 0); check(test.service.selected === content.columns, "down")
                content.navigate(Qt.Key_Up, 0); check(test.service.selected === 0, "up")
                content.navigate(Qt.Key_Right, 0); check(test.service.selected === 1, "right")
                content.navigate(Qt.Key_Left, 0); check(test.service.selected === 0, "left")
                content.navigate(Qt.Key_Right, Qt.ControlModifier)
                check(test.service.category === "Recently Used" && test.service.query === "", "category")
                test.service.query = "woman technologist medium skin tone"
                check(test.service.results[0].emoji === "👩🏽‍💻", "complex match")
                content.navigate(Qt.Key_Return, 0)
                break
            case 1:
                if (test.service.busy) { test.step--; return }
                check(!test.service.opened && !test.service.error, "copy close")
                check(Services.Settings.data.emoji.recents[0] === "1F469-1F3FD-200D-1F4BB", "recent")
                test.service.open(); content.focusSearch()
                check(content.searchField.activeFocus && test.service.category === "Recently Used", "reopen")
                check(test.service.results[0].emoji === "👩🏽‍💻", "recent results")
                Services.Settings.setValue("emoji", "closeOnSelect", false)
                test.service.query = "fire"; test.service.choose(0)
                break
            case 2:
                if (test.service.busy) { test.step--; return }
                check(test.service.opened && test.service.message.length > 0, "keep open")
                test.service.choose(0)
                break
            case 3:
                if (test.service.busy) { test.step--; return }
                check(Services.Settings.data.emoji.recents.length === 2, "deduplicate")
                content.navigate(Qt.Key_Escape, 0); check(!test.service.opened, "escape")
                test.service.open(); test.service.suppressed = true
                check(!test.service.opened, "fullscreen closes")
                test.service.open(); check(!test.service.opened, "fullscreen prevents open")
                test.service.suppressed = false; test.service.open()
                Services.Settings.setValue("emoji", "enabled", false)
                check(!test.service.opened, "disable closes")
                test.service.open(); check(!test.service.opened, "disabled")
                Services.Settings.setValue("emoji", "enabled", true)
                break
            case 4:
                if (["pending", "saving"].indexOf(Services.Settings.saveState) >= 0) { test.step--; return }
                check(Services.Settings.saveState === "saved", "saved")
                Services.Settings.discardAndReload()
                break
            case 5:
                check(Services.Settings.data.emoji.recents.length === 2, "persist reload")
                Services.Settings.resetSection("emoji")
                check(Services.Settings.data.emoji.recents.length === 0, "reset recents")
                check(Services.Settings.data.emoji.closeOnSelect, "reset preferences")
                console.log("Emoji real service/content focus, navigation, exact copy, close, Recents persistence/reset and fullscreen PASS")
                const preview = Quickshell.env("MAGI_EMOJI_PREVIEW")
                if (preview) {
                    test.service.open(); test.service.query = "heart"
                    Qt.callLater(() => content.grabToImage(image => { image.saveToFile(preview); Qt.quit() }))
                } else Qt.quit()
            }
        }
    }
}
