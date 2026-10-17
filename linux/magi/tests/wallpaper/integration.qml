import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/hub" as UI
import "../../.config/quickshell/magi/components/settings/pages" as Pages
ShellRoot {
    UI.HubWindow { id: window; readyToOpen: true }
    property int step: 0
    property int attempts: 0
    property int changed: 0
    property string imagePath: Quickshell.env("MAGI_WALLPAPER_IMAGE")
    Connections { target: Services.Wallpaper; function onSelectionChanged() { changed++ } }
    function check(ok, why) { if (!ok) { console.error("FAIL: " + why); Qt.exit(1) } }
    Timer {
        interval: 300; repeat: true; running: true
        onTriggered: {
            if (++attempts > 60) { console.error("FAIL timeout " + step + ": " + Services.Wallpaper.error); Qt.exit(1) }
            if (!Services.Settings.ready || !Services.Wallpaper.initialized || Services.Wallpaper.busy) return
            if (step === 0) {
                check(Services.Settings.setValue("wallpaper", "directories", [Quickshell.env("MAGI_WALLPAPER_ROOT")]), "save roots")
                check(!Services.Settings.setValue("wallpaper", "directories", ["relative"]), "reject relative")
                check(Services.Settings.setValue("wallpaper", "thumbnailSize", 180), "grid size")
                Services.Wallpaper.open(); step++
            } else if (step === 1) {
                if (!Services.Wallpaper.entries.length) return
                check(window.visible, "manager opens")
                check(Services.Wallpaper.entries.length === 1, "scan result")
                Services.Wallpaper.choose(imagePath); step++
            } else if (step === 2) {
                check(!Services.Wallpaper.error, Services.Wallpaper.error)
                check(changed === 1, "confirmed selection event")
                check(Services.Wallpaper.currentPath === imagePath, "confirmed current path")
                check(Services.Wallpaper.state.recents[0] === imagePath, "recent persisted")
                Services.Wallpaper.favourite(imagePath); step++
            } else if (step === 3) {
                check(Services.Wallpaper.state.favourites[0] === imagePath, "favourite persisted")
                Services.Wallpaper.filter = "Favourites"
                check(Services.Wallpaper.results.length === 1, "favourite filter")
                // Fake backend rejects contain, after Qt preflight succeeds.
                Services.Wallpaper.mode = "contain"
                Services.Wallpaper.choose(imagePath); step++
            } else if (step === 4) {
                check(Services.Wallpaper.error.indexOf("simulated rejection") >= 0, "backend failure surfaced")
                check(Services.Wallpaper.opened, "failure keeps manager open")
                check(Services.Wallpaper.state.shared.mode === "cover", "failure preserves saved selection")
                check(changed === 1, "no false event on failure")
                Services.Wallpaper.choose(imagePath + ".missing"); step++
            } else if (step === 5) {
                check(Services.Wallpaper.error.indexOf("decode") >= 0, "missing image error")
                Services.Wallpaper.start({op:"load"}); step++
            } else if (step === 6) {
                check(Services.Wallpaper.state.shared.path === imagePath, "state reload")
                check(Services.Settings.saveState === "saved", "settings persisted")
                Services.Settings.discardAndReload(); step++
            } else if (step === 7) {
                check(Services.Settings.data.wallpaper.thumbnailSize === 180, "settings reload")
                check(Services.Settings.resetSection("wallpaper"), "settings reset")
                check(Services.Settings.data.wallpaper.thumbnailSize === 220, "reset defaults")
                Services.Wallpaper.close(); step++
            } else {
                check(!window.visible, "manager closes")
                console.log("Wallpaper UI, apply, failure, state, settings and reset PASS")
                Qt.quit()
            }
        }
    }
}
