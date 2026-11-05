import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/hub" as UI
ShellRoot {
    UI.HubWindow { id: window }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "HubSearchFocus"
        when: Services.Settings.ready && Services.Emoji.entries.length > 0
        function search(mode) {
            Services.Hub.open(mode)
            tryCompare(window, "visible", true)
            verify(window.ownsSearchKeyboard)
            const field = window.content.currentContent.searchField
            tryCompare(field, "activeFocus", true)
            return field
        }
        function typeAbc(field) {
            keyClick(Qt.Key_A); keyClick(Qt.Key_B); keyClick(Qt.Key_C)
            compare(field.text, "abc")
        }
        function test_search_lifecycle() {
            // Production item routing; layer-shell arbitration/previous-app leakage
            // must also pass the real compositor acceptance sequence.
            for (const mode of ["apps", "clipboard", "emoji"]) {
                for (let i = 0; i < 3; i++) {
                    const field = search(mode)
                    compare(field.text, "")
                    typeAbc(field)
                    keyClick(Qt.Key_Escape)
                    tryCompare(window, "visible", false)
                    verify(!window.ownsSearchKeyboard)
                }
            }
            const navigation = search("emoji")
            tryVerify(() => Services.Emoji.results.length > 10)
            keyClick(Qt.Key_Down)
            verify(Services.Emoji.selected > 0)
            keyClick(Qt.Key_Up)
            compare(Services.Emoji.selected, 0)
            keyClick(Qt.Key_Escape)
            search("apps")
            tryVerify(() => Services.Launcher.applications.length > 0)
            Services.Launcher.query = "MAGI Hub launch fixture"
            tryVerify(() => Services.Launcher.results.length === 1)
            keyClick(Qt.Key_Return)
            tryCompare(Services.Hub, "opened", false)
            compare(Services.Launcher.error, "")
            const apps = search("apps")
            typeAbc(apps)
            search("clipboard")
            const emoji = search("emoji")
            typeAbc(emoji)
            compare(search("apps"), apps)
            compare(apps.text, "abc") // Existing within-session query retained.
            compare(emoji.activeFocus, false)
            const selector = window.content.modeButtons.itemAt(0)
            selector.forceActiveFocus()
            Services.Launcher.query = "changed outside input"
            wait(30)
            compare(selector.activeFocus, true) // No polling/refocus on model updates.
            Services.Hub.open("notifications")
            tryCompare(window, "ownsSearchKeyboard", false)
            tryVerify(() => window.content.currentContent.activeFocus)
            Services.Hub.open("settings")
            tryCompare(window, "ownsSearchKeyboard", false)
            Services.Hub.close()
            search("apps")
            Services.Hub.suppressed = true
            tryCompare(window, "visible", false)
            verify(!window.ownsSearchKeyboard)
            Services.Hub.suppressed = false
            tryCompare(window.content.currentContent.searchField, "activeFocus", true)
            Services.Hub.close()
            console.log("Hub search focus PASS: immediate item typing, repeated opens, mode handoff, query policy, deliberate focus and Escape; native keyboard arbitration still required")
            finish.start()
        }
    }
}
