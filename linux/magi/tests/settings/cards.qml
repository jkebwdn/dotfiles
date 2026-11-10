import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    UI.SettingsWindow { id: window }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        id: test
        name: "SettingsCards"
        when: Services.Settings.ready
        function inspect(item, cardAncestor) {
            if (!item.visible) return 0
            let total = 0
            if (item.settingsSection === true && item.carded) {
                if (cardAncestor) throw new Error("Nested card: " + item.title + " inside " + cardAncestor.title)
                verify(item.width > 0 && item.height > 0, "Positive card geometry")
                compare(item.activeFocusOnTab, false)
                const background = findChild(item, "settingsSectionBackground")
                compare(background.color, Theme.Theme.elevated)
                compare(background.radius, Theme.Theme.radius("surface", 12, background.width, background.height))
                total++; cardAncestor = item
            }
            if (cardAncestor && item !== cardAncestor && item.activeFocusOnTab) {
                const at = item.mapToItem(cardAncestor, 0, 0)
                verify(at.x >= -1 && at.x + item.width <= cardAncestor.width + 1, "Bounded control: " + item.objectName)
            }
            for (const child of item.children) total += inspect(child, cardAncestor)
            return total
        }
        function test_pages() {
            try {
            Services.SettingsWindowState.shown = true
            for (const theme of ["one-light", "nord"]) {
                Services.Settings.setTheme(theme)
                for (const size of [[720,560],[1000,760],[1400,900]]) {
                    window.contentItem.Window.window.width = size[0]; window.contentItem.Window.window.height = size[1]
                    tryCompare(window, "width", size[0]); tryCompare(window, "height", size[1])
                    for (const name of ["Appearance", "Bar", "Control Centre", "Lock Screen", "Power & Idle"]) {
                        Services.SettingsWindowState.page = name
                        wait(100)
                        const page = findChild(window.contentItem, "settingsPage-" + name)
                        verify(page !== null)
                        if (name === "Bar" || name === "Control Centre") page.mode = "Appearance"
                        if (name === "Control Centre") findChild(page, "decorationSettings").expanded = true
                        wait(100)
                        verify(inspect(page, null) > 0, "Page has grouped options: " + name)
                        const folder = Quickshell.env("MAGI_SETTINGS_CARD_CAPTURES")
                        if (folder) {
                            grabImage(window.contentItem).save(folder + "/" + theme + "-" + size[0] + "-" + name.replace(/ /g, "-") + ".png")
                        }
                    }
                }
            }
            console.log("Settings cards PASS")
            finish.start()
            } catch (e) { console.error("FAIL: " + e + " " + e.stack); throw e }
        }
    }
}
