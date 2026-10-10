import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/hub" as UI
ShellRoot {
    UI.HubWindow { id: window }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "HubPointer"
        when: Services.Settings.ready && Services.Emoji.entries.length > 0
        function test_surface() {
            Services.Launcher.open()
            tryCompare(window, "visible", true)
            wait(100)
            mouseClick(window.content.modeButtons.itemAt(2))
            compare(Services.Hub.mode, "emoji")
            tryCompare(window.content.currentContent.searchField, "activeFocus", true)
            mouseClick(window.content, 6, 46)
            verify(Services.Hub.opened, "interior padding consumes click")
            const parent = window.content.parent
            mouseClick(parent, 8, 80)
            tryCompare(Services.Hub, "opened", false)
            console.log("Hub pointer selector, interior consumption and outside dismissal PASS")
            finish.start()
        }
    }
}
