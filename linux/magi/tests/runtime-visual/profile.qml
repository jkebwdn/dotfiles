import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/components/hub" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    Bar.Bar { id: bar; expandableHostMode: "combined" }
    UI.HubWindow { id: hub; readyToOpen: bar.settingsReady; previewSurface: bar.activeCombinedRegion }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "ProfileLayout"
        when: Services.Settings.ready
        function collect(item, predicate) {
            let result = predicate(item) ? [item] : []
            for (const child of item.children || []) result = result.concat(collect(child, predicate))
            return result
        }
        function test_navigation() {
            try {
                // Reproduce first creation with long values, before a short-text
                // page can establish stable row geometry in the retained host.
                Services.Settings.setValue("profile", "displayName", "A long display name ".repeat(4).trim())
                Services.Settings.setValue("profile", "subtitleMode", "custom")
                Services.Settings.setValue("profile", "subtitle", "A long optional profile line ".repeat(4))
                Services.SettingsWindowState.page = "Control Centre"
                Services.SettingsWindowState.open()
                tryVerify(() => hub.visible)
                Services.SettingsWindowState.toggleControlCentrePreview()
                tryCompare(bar.expandablePillRegistry.controlcentre, "phase", 3)
                Services.SettingsWindowState.page = "Appearance"
                tryVerify(() => findChild(hub.contentItem, "settingsPage-Appearance") !== null)
                verify(waitForRendering(findChild(hub.contentItem, "settingsPage-Appearance")))
                const firstNavigation = findChild(hub.contentItem, "settingsNav-Profile")
                firstNavigation.forceActiveFocus()
                mouseClick(firstNavigation)
                tryVerify(() => findChild(hub.contentItem, "settingsPage-Profile") !== null)
                verify(waitForRendering(findChild(hub.contentItem, "settingsPage-Profile")))
                const captures = Quickshell.env("MAGI_PROFILE_CAPTURES")
                for (const theme of ["catppuccin-mocha", "rose-pine-dawn"]) {
                    Services.Settings.setTheme(theme)
                    for (const width of [800, 1280, 1920]) {
                        hub.contentItem.Window.window.width = width
                        hub.contentItem.Window.window.height = 900
                        for (const name of ["Operator", "A long display name ".repeat(4).trim()]) {
                            for (const message of ["", "A long optional personal message ".repeat(4)]) {
                                Services.SettingsWindowState.page = "Appearance"
                                tryVerify(() => findChild(hub.contentItem, "settingsPage-Appearance") !== null)
                                verify(waitForRendering(findChild(hub.contentItem, "settingsPage-Appearance")))
                                Services.Settings.setValue("profile", "displayName", name)
                                Services.Settings.setValue("profile", "subtitleMode", "custom")
                                Services.Settings.setValue("profile", "subtitle", message)
                                const navigation = findChild(hub.contentItem, "settingsNav-Profile")
                                navigation.forceActiveFocus()
                                mouseClick(navigation)
                                tryVerify(() => findChild(hub.contentItem, "settingsPage-Profile") !== null)
                                const page = findChild(hub.contentItem, "settingsPage-Profile")
                                verify(waitForRendering(page))
                                const fields = collect(page, item => item.maximumLength !== undefined
                                    && item.parent.children[0]?.text !== undefined
                                    && ["Display name", "Message"].includes(item.parent.children[0].text))
                                compare(fields.length, 2)
                                for (const field of fields) {
                                    verify(field.visible && field.width > 0 && field.height > 0)
                                    const row = field.parent
                                    compare(row.columns, row.parent.width < 420 ? 1 : 2)
                                    verify(row.width <= page.body.width + 1, "row does not overflow")
                                    verify(field.x >= 0 && field.x + field.width <= row.width + 1, "field does not overflow")
                                    verify(field.mapToItem(page, 0, 0).y + field.height <= page.height, "identity fields remain in view")
                                    if (row.columns === 2) compare(field.width, 240)
                                }
                                compare(fields[0].width, fields[1].width, "identity fields align")
                                verify(bar.previewPinned)
                                if (captures && name.length > 20 && message.length > 20)
                                    grabImage(hub.contentItem).save(captures + "/profile-" + theme + "-" + width + ".png")
                                Services.Settings.setValue("profile", "subtitleMode", "greeting")
                                tryCompare(fields[1].parent, "visible", false)
                                Services.Settings.setValue("profile", "subtitleMode", "custom")
                                tryCompare(fields[1].parent, "visible", true)
                            }
                        }
                    }
                }
                console.log("Profile responsive pinned navigation PASS")
            } catch (error) { console.error("FAIL:", error, error.stack) }
            finally { finish.start() }
        }
    }
}
