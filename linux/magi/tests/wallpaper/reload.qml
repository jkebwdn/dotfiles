import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/wallpaper" as UI
ShellRoot {
    UI.WallpaperWindow { id: window; readyToOpen: true }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "WallpaperReload"
        when: Services.Settings.ready && Services.Wallpaper.initialized && !Services.Wallpaper.busy
        function test_restore_and_interaction() {
            const path = Quickshell.env("MAGI_WALLPAPER_IMAGE")
            compare(Services.Wallpaper.state.shared.path, path)
            compare(Services.Wallpaper.state.favourites[0], path)
            tryCompare(Services.Wallpaper, "currentPath", path)
            Services.Wallpaper.open()
            tryCompare(window, "visible", true)
            tryVerify(() => window.contentItem !== null)
            Services.Wallpaper.filter = "Favourites"
            const content = window.contentItem
            tryCompare(content.grid, "count", 1)
            tryVerify(() => content.grid.itemAtIndex(0) !== null)
            tryCompare(content.grid.itemAtIndex(0), "previewReady", true)
            content.focusGrid()
            tryCompare(content.grid, "activeFocus", true)
            keyClick(Qt.Key_Return)
            tryCompare(Services.Wallpaper, "busy", false)
            mouseClick(content, 5, 5)
            verify(Services.Wallpaper.opened, "interior click is consumed")
            content.focusGrid(); keyClick(Qt.Key_Escape)
            tryCompare(Services.Wallpaper, "opened", false)
            Services.Wallpaper.open(); tryCompare(window, "visible", true)
            mouseClick(window.contentItem.parent.parent, 8, 80)
            tryCompare(Services.Wallpaper, "opened", false)
            console.log("Wallpaper process restart, thumbnail decode, Enter, Escape and outside dismissal PASS")
            finish.start()
        }
    }
}
