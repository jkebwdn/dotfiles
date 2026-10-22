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
    Component {
        id: helperFixture
        UI.SettingsHelp { width: 220; text: "Long status: " + "unbroken-helper-text".repeat(35) }
    }
    Component {
        id: buttonFixture
        UI.SettingsButton { text: "State preview"; width: 180 }
    }
    TestCase {
        name: "SettingsPresentation"
        when: Services.Settings.ready
        function page(title) { return findChild(window.contentItem, "settingsPage-" + title) }
        function reveal(p, item) {
            p.contentY = Math.max(0, Math.min(p.contentHeight - p.height, item.mapToItem(p.contentItem, 0, 0).y - 50))
            wait(30)
        }
        function checkControls(item, pageItem) {
            if (!item.visible) return
            if (/^settings(Button|Toggle|Selector)-/.test(item.objectName)) {
                const point = item.mapToItem(pageItem, 0, 0)
                verify(point.x >= -1 && point.x + item.width <= pageItem.width + 1,
                    "control remains horizontally bounded: " + item.objectName)
            }
            for (const child of item.children) checkControls(child, pageItem)
        }
        function test_application() {
            try {
            Services.SettingsWindowState.shown = true
            wait(100)
            const names = ["Appearance", "Surfaces", "Hub", "Profile", "Bar", "Date & time", "Control Centre", "Notifications", "Clipboard", "Launcher", "Emoji", "Wallpaper", "Power & Idle"]
            for (const theme of ["catppuccin-mocha", "catppuccin-frappe", "everforest-dark-hard", "everforest-light-hard", "catppuccin-latte"]) {
                Services.Settings.setTheme(theme)
                for (const size of [Qt.size(720,500), Qt.size(940,720)]) {
                    // Resize the native test window as an operator would. Changing the
                    // preferred implicit size alone does not resize a mapped FloatingWindow.
                    window.contentItem.Window.window.width = size.width
                    window.contentItem.Window.window.height = size.height
                    tryCompare(window.contentItem, "width", size.width)
                    tryCompare(window.contentItem, "height", size.height)
                    for (const name of names) {
                        const sub = ({Bar:"bar", "Control Centre":"controlcentre", Surfaces:"surfaces", Hub:"hub"})[name]
                        if (sub) { Services.SettingsWindowState.page = "Appearance"; wait(30) }
                        const nav = findChild(window.contentItem, sub ? "appearanceNav-" + sub : "settingsNav-" + name)
                        verify(nav !== null)
                        nav.forceActiveFocus(Qt.TabFocusReason)
                        wait(30)
                        verify(nav.activeFocus, "navigation takes keyboard focus")
                        const navigation = findChild(window.contentItem, "settingsNavigation")
                        const navPoint = nav.mapToItem(navigation, 0, 0)
                        verify(sub || (navPoint.y >= 0 && navPoint.y + nav.height <= navigation.height + 1), "focused navigation stays in viewport")
                        keyClick(Qt.Key_Space)
                        compare(Services.SettingsWindowState.page, name)
                        wait(30)
                        const title = name === "Emoji" ? "Emoji Picker" : name === "Launcher" ? "Application Launcher" : name
                        const current = page(title)
                        verify(current !== null && current.visible, "production page opens: " + name)
                        verify(current.body.width > 400 && current.body.width <= current.width, "bounded page width")
                        compare(current.boundsBehavior, Flickable.StopAtBounds)
                        verify(nav.checked, "selection remains distinct from focus")
                        if (!nav.hovered) compare(nav.background.color, sub ? Theme.Theme.elevated : "#00000000", "navigation levels have distinct selection")
                        checkControls(current.body, current)
                        if (Quickshell.env("MAGI_SETTINGS_CAPTURES")
                                && ["Control Centre", "Launcher", "Appearance"].indexOf(name) >= 0) {
                            if (name === "Appearance") tryCompare(Services.ThemeOrchestrator, "busy", false)
                            wait(50)
                            const capture = grabImage(window.contentItem)
                            compare(capture.width, size.width)
                            compare(capture.height, size.height)
                            capture.save(Quickshell.env("MAGI_SETTINGS_CAPTURES") + "/" + theme + "-" + name.replace(/ /g, "-") + "-" + size.width + ".png")
                        }
                    }
                }
            }
            Services.SettingsWindowState.page = "Bar"; wait(50)
            const slider = findChild(page("Bar"), "visualSetting-statusIconSize")
            verify(slider.visible, "surface controls remain reachable")
            const iconSize = Services.Settings.data.appearance.visual.statusIconSize
            slider.forceActiveFocus(Qt.TabFocusReason); keyClick(Qt.Key_Right)
            compare(Services.Settings.data.appearance.visual.statusIconSize, iconSize + 1, "production slider writes existing visual setting")
            Services.SettingsWindowState.page = "Control Centre"; wait(50)
            const primary = findChild(page("Control Centre"), "primaryColumns")
            const secondary = findChild(page("Control Centre"), "secondaryColumns")
            compare(primary.mapToItem(page("Control Centre"), primary.width, 0).x,
                secondary.mapToItem(page("Control Centre"), secondary.width, 0).x, "column steppers align")
            const secondaryBefore = Services.Settings.data.controlCentre.actionColumns
            const primaryBefore = Services.Settings.data.controlCentre.columns
            primary.forceActiveFocus(Qt.TabFocusReason); keyClick(Qt.Key_Up)
            compare(Services.Settings.data.controlCentre.columns, primaryBefore + 1)
            mouseClick(primary.up.indicator)
            compare(Services.Settings.data.controlCentre.columns, primaryBefore + 2, "integrated stepper pointer increment")
            mouseClick(primary.down.indicator)
            compare(Services.Settings.data.controlCentre.columns, primaryBefore + 1, "integrated stepper pointer decrement")
            compare(Services.Settings.data.controlCentre.actionColumns, secondaryBefore, "column settings stay independent")
            Services.SettingsWindowState.page = "Launcher"; wait(50)
            const layoutChoice = findChild(page("Application Launcher"), "settingsSelector-Layout")
            reveal(page("Application Launcher"), layoutChoice)
            const priorLayout = Services.Settings.data.launcher.layout
            mouseClick(layoutChoice)
            tryCompare(layoutChoice.popup, "visible", true)
            keyClick(Qt.Key_Down); keyClick(Qt.Key_Return)
            tryCompare(layoutChoice.popup, "visible", false)
            verify(Services.Settings.data.launcher.layout !== priorLayout, "styled selector retains production activation")
            mouseClick(layoutChoice)
            tryCompare(layoutChoice.popup, "visible", true)
            const chosenLayout = Services.Settings.data.launcher.layout
            keyClick(Qt.Key_Escape)
            tryCompare(layoutChoice.popup, "visible", false)
            compare(Services.Settings.data.launcher.layout, chosenLayout, "Escape dismisses without changing selection")
            verify(Services.SettingsWindowState.shown, "combo popup owns Escape before window")
            Services.SettingsWindowState.page = "Emoji"
            wait(50)
            const emoji = page("Emoji Picker")
            const toggle = findChild(emoji, "settingsToggle-Enable Emoji Picker")
            reveal(emoji, toggle)
            const before = Services.Settings.data.emoji.enabled
            toggle.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            compare(Services.Settings.data.emoji.enabled, !before, "production toggle writes existing key")
            keyClick(Qt.Key_Tab)
            verify(!toggle.activeFocus, "Tab advances to next production control")
            const reset = findChild(emoji, "settingsButton-Reset Emoji settings and history")
            reveal(emoji, reset); mouseClick(reset)
            compare(Services.Settings.data.emoji.enabled, true, "production reset uses existing defaults")
            Services.SettingsWindowState.page = "Wallpaper"; wait(50)
            const draft = findChild(page("Wallpaper"), "wallpaperDirectories")
            draft.text = "/tmp/unsaved-wallpaper-draft"
            Services.SettingsWindowState.page = "Profile"; wait(50)
            verify(findChild(page("Profile"), "profileAvatarPreview") !== null)
            Services.SettingsWindowState.page = "Wallpaper"; wait(50)
            compare(draft.text, "/tmp/unsaved-wallpaper-draft", "navigation retains explicit-save draft")
            verify(Services.Settings.data.wallpaper.directories.indexOf(draft.text) === -1, "navigation does not save draft")
            findChild(page("Wallpaper"), "wallpaperLibrarySources").expanded = true
            wait(30)
            const save = findChild(page("Wallpaper"), "settingsButton-Save directories")
            reveal(page("Wallpaper"), save); mouseClick(save)
            compare(Services.Settings.data.wallpaper.directories[0], draft.text, "explicit Save still writes directories")
            const helper = createTemporaryObject(helperFixture, window.contentItem)
            verify(helper.lineCount > 1 && helper.width === 220, "long helper text wraps within width")
            const button = createTemporaryObject(buttonFixture, window.contentItem)
            for (const theme of ["catppuccin-mocha", "catppuccin-latte"]) {
                Services.Settings.setTheme(theme); wait(20)
                mousePress(button)
                compare(button.contentItem.color, Theme.Theme.accentText, "pressed ink pairs with accent")
                mouseRelease(button)
                button.forceActiveFocus(Qt.TabFocusReason)
                verify(button.activeFocus)
                button.enabled = false
                compare(button.opacity, UI.SettingsMetrics.disabledOpacity)
                button.enabled = true
            }
            tryCompare(Services.Settings, "saveState", "saved")
            const status = findChild(window.contentItem, "settingsSaveStatus")
            const statusPanel = findChild(window.contentItem, "settingsSavePanel")
            status.text = "Long diagnostic details ".repeat(200)
            wait(30)
            verify(statusPanel.width < 200 && status.height <= 60, "sidebar diagnostic is compact and bounded")
            console.log("RESULT: 0 failures; all Settings pages, keyboard, palettes, reset and drafts")
            finish.start()
            } catch (e) { console.error("FAIL: " + e + " " + e.stack); throw e }
        }
    }
}
