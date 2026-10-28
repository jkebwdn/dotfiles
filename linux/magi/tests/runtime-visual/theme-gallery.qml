import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    FloatingWindow {
        visible: true; implicitWidth: 1000; implicitHeight: 720
        color: Theme.Theme.background
        UI.SettingsContent { id: content; anchors.fill: parent }
    }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "ThemeGallery"; when: Services.Settings.ready
        function test_gallery() { try {
            Services.SettingsWindowState.page = "Appearance"
            const gallery = findChild(content, "themeGallery")
            const page = findChild(content, "settingsPage-Appearance")
            verify(gallery !== null); verify(page !== null)
            const original = Services.Settings.data.appearance.theme
            const originalData = JSON.stringify(Services.Settings.data)
            const all = Theme.ThemeRegistry.themes
            compare(gallery.expanded, false, "Gallery starts with a family preview")
            const disclosure = findChild(gallery, "themeGalleryDisclosure")
            verify(!findChild(gallery, "themeFilter-Light").visible)
            verify(gallery.visibleThemes.some(theme => theme.id === original))
            verify(gallery.count <= gallery.columns)
            if (gallery.count > 1) {
                const first = gallery.itemAt(0), second = gallery.itemAt(1)
                mouseClick(second)
                compare(gallery.itemAt(0), first, "Selecting a visible variant retains card instances")
                verify(second.activeFocus)
                Services.Settings.setTheme(original)
            }
            const disclosureRevision = Services.Settings.revision
            disclosure.forceActiveFocus(); keyClick(Qt.Key_Space)
            compare(gallery.expanded, true)
            compare(Services.Settings.revision, disclosureRevision, "Expansion does not save Settings")
            compare(gallery.count, all.length)
            compare(gallery.groups.map(group => group.family), all.map(theme => theme.family).filter((family, index, list) => list.indexOf(family) === index))
            verify(gallery.contentX === undefined, "No nested horizontal viewport")
            const columnCounts = []
            for (const width of [720, 1000, 1280]) {
                content.Window.window.width = width
                tryCompare(content, "width", width)
                waitForPolish(content.Window.window)
                columnCounts.push(gallery.columns)
                verify(page.contentWidth <= page.width)
                for (let i = 0; i < gallery.count; ++i) {
                    const card = gallery.itemAt(i), theme = all[i]
                    verify(card !== null)
                    compare(card.modelData.id, theme.id)
                    compare(card.modelData.roles, theme.roles)
                    const point = card.mapToItem(gallery, 0, 0)
                    verify(point.x >= 0 && point.x + card.width <= gallery.width + .1, "No horizontal overflow")
                }
            }
            gallery.expanded = false
            for (const width of [720, 1000, 1280]) {
                content.Window.window.width = width; tryCompare(content, "width", width)
                waitForPolish(content.Window.window)
                for (const definition of all) {
                    Services.Settings.setTheme(definition.id)
                    waitForPolish(content.Window.window)
                    verify(gallery.visibleThemes.some(theme => theme.id === definition.id), "Current theme always remains in collapsed row")
                    verify(gallery.visibleThemes.every(theme => theme.family === definition.family))
                    verify(gallery.count <= gallery.columns)
                    for (let i = 0; i < gallery.count; ++i) {
                        compare(gallery.itemAt(i).y, 0, "Exactly one preview row")
                        verify(gallery.itemAt(i).x + gallery.itemAt(i).width <= gallery.width + .1)
                    }
                }
            }
            gallery.expanded = true
            verify(columnCounts[0] < columnCounts[1] && columnCounts[1] < columnCounts[2], "Responsive columns")
            content.Window.window.width = 1000; waitForPolish(content.Window.window)
            for (let i = 0; i < gallery.count; ++i) {
                gallery.reveal(i); waitForPolish(content.Window.window)
                const card = gallery.itemAt(i)
                mouseClick(card)
                compare(Services.Settings.data.appearance.theme, all[i].id)
                verify(card.selected)
                compare(Theme.Theme.effectiveTheme, all[i].id)
            }
            const chosen = Services.Settings.data.appearance.theme
            gallery.focusIndex(0)
            keyClick(Qt.Key_Right)
            verify(gallery.itemAt(1).activeFocus)
            compare(Services.Settings.data.appearance.theme, chosen, "Focus does not apply")
            keyClick(Qt.Key_Space)
            compare(Services.Settings.data.appearance.theme, all[1].id)
            gallery.focusIndex(0)
            const down = gallery.verticalIndex(0, 1)
            keyClick(Qt.Key_Down); verify(gallery.itemAt(down).activeFocus)
            keyClick(Qt.Key_Up); verify(gallery.itemAt(0).activeFocus)
            keyClick(Qt.Key_Right)
            keyClick(Qt.Key_Return); compare(Services.Settings.data.appearance.theme, all[1].id)
            const filteringRevision = Services.Settings.revision
            for (const option of ["Dark", "Light", "All"]) {
                page.contentY = 0; waitForPolish(content.Window.window)
                const button = findChild(gallery, "themeFilter-" + option)
                mouseClick(button); waitForPolish(content.Window.window)
                const expected = all.filter(theme => option === "All" || theme.dark === (option === "Dark"))
                compare(gallery.visibleThemes.map(theme => theme.id), expected.map(theme => theme.id))
                compare(gallery.groups.map(group => group.family), expected.map(theme => theme.family).filter((family, index, list) => list.indexOf(family) === index))
                compare(Services.Settings.data.appearance.theme, all[1].id, "Filtering does not apply")
            }
            compare(Services.Settings.revision, filteringRevision, "Filters do not persist")
            // One tab stop for the cards, then normal page traversal. Focus is
            // independent of selection and Escape is left to the Settings host.
            const light = findChild(gallery, "themeFilter-Light")
            page.contentY = 0; light.forceActiveFocus(); keyClick(Qt.Key_Space)
            waitForPolish(content.Window.window); keyClick(Qt.Key_Tab)
            verify(gallery.itemAt(0).activeFocus)
            keyClick(Qt.Key_Backtab)
            verify(light.activeFocus)
            const toggleRevision = Services.Settings.revision
            page.contentY = 0; disclosure.forceActiveFocus(); keyClick(Qt.Key_Space)
            compare(gallery.expanded, false)
            verify(gallery.visibleThemes.some(theme => theme.id === Services.Settings.data.appearance.theme), "Collapsed row ignores browse filter")
            verify(!light.visible)
            keyClick(Qt.Key_Space); compare(gallery.expanded, true); compare(gallery.filter, 2)
            compare(Services.Settings.revision, toggleRevision)
            Services.SettingsWindowState.page = "Profile"
            waitForPolish(content.Window.window)
            Services.SettingsWindowState.page = "Appearance"
            waitForPolish(content.Window.window)
            compare(findChild(content, "themeGallery"), gallery, "Retained Settings page owns view state")
            compare(gallery.expanded, true); compare(gallery.filter, 2)
            compare(Services.Settings.revision, toggleRevision, "Navigation retains local view state without saving")
            gallery.filter = 0; waitForPolish(content.Window.window)
            gallery.focusIndex(0); keyClick(Qt.Key_Tab)
            const nextControl = findChild(content, "settingsButton-Install icon pack…")
            tryVerify(() => nextControl.activeFocus)
            tryVerify(() => nextControl.mapToItem(page, 0, 0).y >= 0 && nextControl.mapToItem(page, 0, 0).y + nextControl.height <= page.height)
            keyClick(Qt.Key_Backtab); verify(gallery.itemAt(0).activeFocus)
            const directory = Quickshell.env("MAGI_THEME_GALLERY_CAPTURES")
            for (const theme of ["one-light", "gruvbox-light", "rose-pine-dawn", "everforest-dark-hard", "kanagawa-wave", "dracula"]) {
                Services.Settings.setTheme(theme); tryCompare(Theme.Theme, "effectiveTheme", theme)
                tryCompare(Services.Settings, "saveState", "saved")
                const first = gallery.itemAt(0)
                tryCompare(first.background, "color", first.hovered ? Theme.Theme.elevated : Theme.Theme.surface)
                for (const width of [720, 1000]) {
                    content.Window.window.width = width; tryCompare(content, "width", width); page.contentY = 0
                    waitForPolish(content.Window.window)
                    if (directory) {
                        gallery.expanded = false; waitForPolish(content.Window.window)
                        grabImage(content).save(directory + "/" + theme + "-" + width + "-collapsed.png")
                        gallery.expanded = true; waitForPolish(content.Window.window)
                        grabImage(content).save(directory + "/" + theme + "-" + width + "-settings.png")
                        if (width === 1000 && ["one-light", "kanagawa-wave"].includes(theme)) {
                            for (const family of ["Catppuccin", "Everforest", "Gruvbox", "Kanagawa", "Dracula", "One"]) {
                                const section = findChild(gallery, "themeFamily-" + family)
                                page.contentY = Math.max(0, Math.min(page.contentHeight - page.height, section.mapToItem(page, 0, 0).y + page.contentY))
                                waitForPolish(content.Window.window)
                                waitForRendering(content)
                                grabImage(content).save(directory + "/" + theme + "-family-" + family.toLowerCase() + ".png")
                            }
                        }
                    }
                }
            }
            Services.Settings.setTheme(original); tryCompare(Theme.Theme, "effectiveTheme", original)
            tryCompare(Services.Settings, "saveState", "saved")
            compare(Services.Settings.data, JSON.parse(originalData), "Only theme selection changes preferences, and restores fully")
            console.log("Theme gallery PASS: registry/families, filters, selection, keyboard, responsive geometry and theme restoration")
            finish.start()
        } catch (error) { console.error("FAIL:", error, error.stack); finish.start(); throw error } }
    }
}
