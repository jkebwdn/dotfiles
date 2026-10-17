import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/hub" as UI
ShellRoot {
    UI.HubWindow { id: window }
    Component { id: dialogFixture; Dialog { modal: true; focus: true; standardButtons: Dialog.Close } }
    Component { id: editorFixture; TextField { Keys.onEscapePressed: event => { text = "cancelled"; event.accepted = true } } }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "HubComposition"
        when: Services.Settings.ready && Services.Emoji.entries.length > 0
        function test_composition() {
            try {
                compare(Services.Hub.modes, ["apps","clipboard","notifications","emoji","settings"])
                Services.Hub.open("apps"); wait(100)
                const native = window.contentItem.Window.window
                for (const size of [Qt.size(1280,900),Qt.size(1920,1080),Qt.size(3840,2160),Qt.size(1024,768)]) {
                    native.width = size.width; native.height = size.height; wait(30)
                    let heights = []
                    let anchor = null
                    for (const mode of Services.Hub.modes) {
                        Services.Hub.open(mode); wait(60)
                        const pill = window.content.selectorPill
                        const point = pill.mapToItem(window.contentItem, 0, 0)
                        if (!anchor) anchor = point
                        compare(point.x, anchor.x); compare(point.y, anchor.y)
                        compare(point.y, window.selectorAnchorY)
                        const surface = window.content.surface
                        compare(window.content.y + surface.height + window.content.contentSelectorGap, point.y)
                        verify(window.content.y >= 64)
                        verify(window.content.width <= size.width - 32)
                        compare(surface.radius, Theme.Theme.radius("surface",11,surface.width,surface.height))
                        heights.push(surface.height)
                    }
                    verify(new Set(heights).size > 1, "content dimensions vary around fixed selector")
                }
                native.width = 1920; native.height = 1080; wait(30)
                // Actual keys: arrows focus selector only, activation changes mode.
                Services.Hub.open("apps"); wait(50)
                keyClick(Qt.Key_F6)
                verify(window.content.modeButtons.itemAt(0).activeFocus)
                keyClick(Qt.Key_Right); verify(window.content.modeButtons.itemAt(1).activeFocus)
                compare(Services.Hub.mode,"apps")
                keyClick(Qt.Key_Return); wait(50); compare(Services.Hub.mode,"clipboard")
                verify(window.content.currentContent.searchField.activeFocus)
                keyClick(Qt.Key_F6); keyClick(Qt.Key_Left); keyClick(Qt.Key_Space); wait(50)
                compare(Services.Hub.mode,"apps")
                keyClick(Qt.Key_Down); compare(Services.Hub.mode,"apps")
                // Search clear uses the same edit signal as typing.
                const search = window.content.currentContent.searchField
                Services.Launcher.query = "fixture"; wait(20)
                mouseClick(search, search.width - 20, search.height / 2)
                compare(Services.Launcher.query, ""); verify(search.activeFocus)
                // Real header uses the shared mask and validated settings.
                Services.Settings.setValue("launcher","headerEnabled",true)
                Services.Settings.setValue("launcher","headerImage",Qt.resolvedUrl("test-artwork.ppm").toString().replace("file://",""))
                for (const fit of ["cover","contain"]) {
                    Services.Settings.setValue("launcher","headerFit",fit)
                    Services.Settings.setValue("launcher","headerRadius",24)
                    Services.Settings.setValue("launcher","headerBorderWidth",4)
                    wait(30)
                    const art = findChild(window.content.currentContent,"launcherHeaderArtwork")
                    verify(art.visible); compare(art.radius,24); compare(art.frameWidth,4)
                    compare(art.fillMode,fit === "cover" ? Image.PreserveAspectCrop : Image.PreserveAspectFit)
                    compare(findChild(art,"artworkMask").radius,20)
                    verify(findChild(art,"artworkSource").clip)
                }
                Services.Settings.setValue("launcher","headerBorderRole","accent")
                Services.Settings.setValue("launcher","headerPosition","bottom")
                tryCompare(Services.Settings,"saveState","saved")
                Services.Settings.discardAndReload(); tryCompare(Services.Settings,"ready",true); wait(100)
                compare(Services.Settings.data.launcher.headerRadius,24)
                compare(Services.Settings.data.launcher.headerBorderWidth,4)
                compare(Services.Settings.data.launcher.headerFit,"contain")
                compare(Services.Settings.data.launcher.headerBorderRole,"accent")
                compare(Services.Settings.data.launcher.headerPosition,"bottom")
                Services.Settings.resetSection("launcher"); wait(30)
                compare(Services.Settings.data.launcher.headerRadius,12)
                // Each palette passes through production surface/search/selector/icon roles.
                for (const palette of ["catppuccin-mocha","catppuccin-frappe","everforest-dark-hard","everforest-light-hard"]) {
                    Services.Settings.setTheme(palette); wait(40)
                    for (const mode of Services.Hub.modes) {
                        mouseClick(window.content.modeButtons.itemAt(Services.Hub.modes.indexOf(mode))); wait(30)
                        compare(Services.Hub.mode,mode)
                        compare(window.content.surface.color,Theme.Theme.surface)
                        compare(window.content.selectorPill.color,Theme.Theme.surface)
                        const button = window.content.modeButtons.itemAt(Services.Hub.modes.indexOf(mode))
                        compare(button.background.color,Theme.Theme.overlay)
                        const captures = Quickshell.env("MAGI_HUB_CAPTURES")
                        if (captures) grabImage(window.content).save(captures + "/" + palette + "-" + mode + ".png")
                        if (window.content.currentContent.searchField)
                            compare(window.content.currentContent.searchField.background.color,Theme.Theme.elevated)
                    }
                }
                Services.SettingsWindowState.open(); wait(80)
                const settings = window.content.currentContent
                verify(Services.SettingsWindowState.shown)
                for (const page of ["Appearance","Profile","Bar","Date & time","Control Centre","Notifications","Clipboard","Launcher","Emoji","Wallpaper","Icons"]) {
                    const nav = findChild(settings,"settingsNav-"+page)
                    nav.forceActiveFocus(); wait(20); keyClick(Qt.Key_Space); wait(40)
                    compare(Services.SettingsWindowState.page,page)
                }
                // Retain the canonical Settings content and page instances across Hub modes.
                const barPage = findChild(settings,"settingsPage-Bar")
                Services.Hub.open("emoji"); wait(20); Services.SettingsWindowState.open(); wait(30)
                compare(window.content.currentContent,settings)
                compare(findChild(settings,"settingsPage-Bar"),barPage)
                Services.SettingsWindowState.page = "Launcher"; wait(50)
                const choice = findChild(settings,"settingsSelector-Layout")
                verify(choice !== null)
                choice.forceActiveFocus(); keyClick(Qt.Key_Space); wait(100)
                verify(choice.popup.opened); keyClick(Qt.Key_Escape); wait(100)
                verify(!choice.popup.opened && Services.Hub.opened)
                choice.forceActiveFocus(); keyClick(Qt.Key_Space); wait(100)
                Services.Hub.open("emoji"); wait(40)
                verify(!choice.popup.opened,"direct mode switch dismisses Settings popup")
                Services.SettingsWindowState.open(); wait(40)
                const editor = editorFixture.createObject(settings)
                editor.forceActiveFocus(); keyClick(Qt.Key_Escape); compare(editor.text,"cancelled")
                verify(Services.Hub.opened); editor.destroy()
                const dialog = dialogFixture.createObject(settings); dialog.open(); wait(30)
                keyClick(Qt.Key_Escape); wait(50); verify(!dialog.opened && Services.Hub.opened); dialog.destroy()
                const nav = findChild(settings,"settingsNav-Emoji"); nav.forceActiveFocus()
                keyClick(Qt.Key_Escape); tryCompare(Services.Hub,"opened",false)
                verify(!Services.SettingsWindowState.shown)
                Services.SettingsWindowState.open(); wait(50)
                mouseClick(window.contentItem,8,80); verify(!Services.Hub.opened && !Services.SettingsWindowState.shown)
                console.log("Hub composition PASS: five modes, logical-output anchor, keyboard/pointer, shared roles, header mask, retained Settings pages, child Escape, outside close")
            } catch (error) { console.error("FAIL:",error,error.stack) } finally { finish.start() }
        }
    }
}
