import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/hub" as UI
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    UI.HubWindow { id: window; readyToOpen: true }
    function find(item, name) {
        if (!item) return null
        if (item.objectName === name) return item
        for (const child of item.children || []) { const result = find(child, name); if (result) return result }
        return null
    }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "WallpaperReload"
        when: Services.Settings.ready && Services.Wallpaper.initialized && !Services.Wallpaper.busy
        function test_restore_and_interaction() {
            try {
            const path = Quickshell.env("MAGI_WALLPAPER_IMAGE")
            compare(Services.Wallpaper.state.shared.path, path)
            compare(Services.Wallpaper.state.favourites[0], path)
            tryCompare(Services.Wallpaper, "currentPath", path)
            Services.Wallpaper.open()
            tryCompare(window, "visible", true)
            tryVerify(() => find(window.content, "wallpaperManagerContent") !== null)
            Services.Wallpaper.filter = "Favourites"
            const content = find(window.content, "wallpaperManagerContent")
            tryCompare(content.grid, "count", 1)
            tryVerify(() => content.grid.itemAtIndex(0) !== null)
            tryCompare(content.grid.itemAtIndex(0), "previewReady", true)
            compare(Services.Hub.mode, "settings")
            compare(Services.Hub.modes.length, 5)
            compare(Services.SettingsWindowState.page, "Wallpaper")
            const thumbnail = find(content.grid.itemAtIndex(0), "wallpaperThumbnail")
            verify(thumbnail.asynchronous && !thumbnail.cache)
            compare(thumbnail.sourceSize.width, 320)
            verify(find(thumbnail, "artworkSource").clip)
            verify(find(thumbnail, "artworkEffect").maskEnabled)
            tryVerify(() => Services.Wallpaper.libraryLoaded && Services.Wallpaper.entries.length > 0)
            const originalEntries = Services.Wallpaper.entries
            for (const palette of ["catppuccin-mocha", "catppuccin-frappe", "everforest-dark-hard", "everforest-light-hard"]) {
                Services.Settings.setTheme(palette)
                for (const size of [[752,768],[1280,900],[3840,2160]]) {
                    window.content.Window.window.width = size[0]
                    window.content.Window.window.height = size[1]
                    wait(60)
                    verify(content.width > 0 && content.grid.width <= content.width)
                    verify(content.grid.height >= 140)
                    compare(content.grid.cacheBuffer, 0)
                    if (size[0] === 1280 && Quickshell.env("MAGI_SECONDARY_CAPTURES"))
                        grabImage(window.content).save(Quickshell.env("MAGI_SECONDARY_CAPTURES") + "/wallpaper-" + palette + ".png")
                    const anchor = window.content.selectorPill.mapToItem(null, 0, 0)
                    Services.SettingsWindowState.page = "Profile"; wait(20)
                    Services.SettingsWindowState.page = "Wallpaper"; wait(30)
                    compare(find(window.content, "wallpaperManagerContent"), content, "retained canonical manager")
                    compare(window.content.selectorPill.mapToItem(null, 0, 0).y, anchor.y)
                }
            }
            window.content.Window.window.width = 1200
            window.content.Window.window.height = 900
            Services.Wallpaper.filter = "All"
            Services.Wallpaper.entries = Array.from({length:60}, (_,i) => Object.assign({}, originalEntries[0], {name:"Image " + i}))
            wait(80)
            compare(content.grid.count, 60)
            content.grid.currentIndex = 0
            content.focusGrid(); keyClick(Qt.Key_Down)
            verify(content.grid.currentIndex > 0, "arrow navigation")
            content.grid.currentIndex = 59; wait(60)
            verify(content.grid.contentY > 0, "focused tile scrolls into view")
            verify(content.grid.itemAtIndex(0) === null, "offscreen thumbnail delegate released")
            Services.Wallpaper.entries = originalEntries
            Services.Wallpaper.mode = "tile"
            const draft = find(window.content, "wallpaperDirectories")
            draft.text = "/tmp/unsaved-phase2d"
            Services.SettingsWindowState.page = "Profile"; wait(30)
            Services.SettingsWindowState.page = "Wallpaper"; wait(30)
            compare(Services.Wallpaper.mode, "tile", "navigation keeps fit choice")
            compare(draft.text, "/tmp/unsaved-phase2d")
            verify(Services.Settings.data.wallpaper.directories.indexOf(draft.text) === -1)
            Services.Wallpaper.mode = "cover"
            Services.Wallpaper.filter = "Favourites"; wait(50)
            content.focusGrid()
            tryCompare(content.grid, "activeFocus", true)
            keyClick(Qt.Key_Return)
            tryCompare(Services.Wallpaper, "busy", false)
            Services.Wallpaper.filter = "All"
            Services.Wallpaper.random()
            tryCompare(Services.Wallpaper, "busy", false)
            compare(Services.Wallpaper.currentPath, path)
            Services.Wallpaper.scope = "TEST-1"
            Services.Wallpaper.choose(path)
            tryCompare(Services.Wallpaper, "busy", false)
            compare(Services.Wallpaper.state.monitors["TEST-1"].path, path)
            Services.Wallpaper.scope = ""
            Services.Settings.setValue("wallpaper", "enabled", false)
            verify(Services.Hub.opened, "disabling wallpaper leaves Settings usable")
            Services.Settings.setValue("wallpaper", "enabled", true)
            mouseClick(content, 5, 5)
            verify(Services.Wallpaper.opened, "interior click is consumed")
            content.focusGrid(); keyClick(Qt.Key_Escape)
            tryCompare(Services.Wallpaper, "opened", false)
            Services.Wallpaper.open(); tryCompare(window, "visible", true)
            mouseClick(window.content.parent, 8, 80)
            verify(Services.Wallpaper.opened)
            Services.Hub.close()
            console.log("Wallpaper process restart, thumbnail decode, Enter, Escape and outside persistence PASS")
            } catch(error) { console.error("FAIL:",error,error.stack) }
            finish.start()
        }
    }
}
