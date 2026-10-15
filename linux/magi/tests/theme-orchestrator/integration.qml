import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Palette
import "../../.config/quickshell/magi/components/settings/pages" as Pages
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property int ticks: 0
    Pages.AppearancePage { width: 900; height: 800 }
    function check(ok, label) { if (!ok) { failures++; console.error("FAIL: " + label) } }
    function ghost() { return Services.ThemeOrchestrator.targets.find(t => t.id === "ghostty") }
    Timer {
        interval: 150; repeat: true; running: true
        onTriggered: {
            if (++test.ticks > 100) { console.error("FAIL: timed out " + test.step); Qt.quit(); return }
            if (!Services.Settings.ready || Services.ThemeOrchestrator.busy) return
            test.check(!Services.ThemeOrchestrator.error, Services.ThemeOrchestrator.error)
            switch (test.step++) {
            case 0: Services.ThemeOrchestrator.activate(); break
            case 1:
                test.check(Services.ThemeOrchestrator.targets.length === 13, "registry reaches Settings")
                Services.ThemeOrchestrator.preview("ghostty", "")
                break
            case 2:
                test.check(Services.ThemeOrchestrator.plan !== null, "integration preview")
                Services.ThemeOrchestrator.enable()
                break
            case 3:
                test.check(test.ghost().enabled && test.ghost().installed, "enabled persisted")
                Services.Settings.setTheme("everforest-dark-hard")
                break
            case 4:
                test.check(Palette.Theme.background.toString() === "#272e33", "MAGI live Everforest")
                test.check(test.ghost().publishedPalette === "everforest-dark-hard", "selector drives generation")
                test.check(test.ghost().result.indexOf("Reload required") === 0, "honest reload status")
                Services.Settings.setTheme("catppuccin-mocha")
                break
            case 5:
                test.check(Palette.Theme.background.toString() === "#1e1e2e", "MAGI live Mocha")
                test.check(test.ghost().publishedPalette === "catppuccin-mocha", "reverse switch")
                Services.ThemeOrchestrator.disable("ghostty")
                break
            case 6:
                test.check(!test.ghost().enabled && !test.ghost().installed, "disable removes integration")
                Services.Settings.setTheme("everforest-dark-hard")
                break
            case 7:
                test.check(test.ghost().publishedPalette === "catppuccin-mocha", "disabled adapter stops writes")
                Services.Settings.discardAndReload()
                Services.ThemeOrchestrator.refresh()
                break
            case 8:
                test.check(!test.ghost().enabled, "Follow MAGI survives refresh")
                Services.Settings.setTheme("catppuccin-latte")
                Services.Settings.setTheme("everforest-dark-hard")
                Services.Settings.setTheme("catppuccin-mocha")
                break
            case 9:
                test.check(Services.ThemeOrchestrator.targets[0].desiredPalette === "catppuccin-mocha", "newest selection wins")
                console.log("RESULT: " + test.failures + " failures; orchestration and Settings")
                Qt.quit()
            }
        }
    }
}
