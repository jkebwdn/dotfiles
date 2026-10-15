import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Palette
import "../../.config/quickshell/magi/components/settings/pages" as Pages
ShellRoot {
    Component.onCompleted: Services.ThemeOrchestrator.activate()
    Window {
        id: window
        visible: true; width: 750; height: 720
        Pages.AppearancePage { id: page; anchors.fill: parent }
    }
    Process {
        id: editHook
        command: ["python3", "-c", "import pathlib,sys; p=pathlib.Path(sys.argv[1]); p.write_text(p.read_text().replace('config-file = ?', 'config-file = /user/'))",
            Quickshell.env("XDG_CONFIG_HOME") + "/ghostty/config.ghostty"]
    }
    Process {
        id: changeBase
        command: ["python3", "-c", "import pathlib,sys; p=pathlib.Path(sys.argv[1]); p.write_text(p.read_text()+'# later user edit\\n')",
            Quickshell.env("XDG_CONFIG_HOME") + "/ghostty/config.ghostty"]
    }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "ThemeEnrollmentPointer"
        when: Services.Settings.ready && !Services.ThemeOrchestrator.busy && Services.ThemeOrchestrator.targets.length > 0
        function row(id) { return Services.ThemeOrchestrator.targets.find(t => t.id === id) }
        function control(prefix, id) { return findChild(page, prefix + "Theme-" + id) }
        function reveal(item) {
            page.contentY = Math.max(0, Math.min(page.contentHeight - page.height,
                item.mapToItem(page.contentItem, 0, 0).y - 80))
            wait(40)
            const point = item.mapToItem(page, item.width / 2, item.height / 2)
            verify(point.y > 0 && point.y < page.height && point.x > 0 && point.x < page.width,
                "pointer target is inside the real page viewport")
        }
        function clickFollow(id) {
            const checkbox = control("follow", id)
            reveal(checkbox)
            verify(checkbox.enabled, "available target is interactive")
            mouseClick(checkbox)
        }
        function idle() { tryCompare(Services.ThemeOrchestrator, "busy", false); wait(50) }
        function confirm(id) {
            tryVerify(() => Services.ThemeOrchestrator.plan !== null)
            const button = control("confirm", id)
            tryCompare(button, "visible", true)
            // Production row scrolls the confirmation into view; no test reveal here.
            wait(80)
            const point = button.mapToItem(page, button.width / 2, button.height / 2)
            verify(point.y > 0 && point.y < page.height, "confirmation is visible without hunting below the target list")
            mouseClick(button)
            idle()
        }
        function test_enrollment() {
            verify(!control("follow", "qt").enabled, "deferred target is disabled")
            verify(findChild(page, "themeStatus-qt").text.indexOf("Unavailable") >= 0)
            verify(!control("follow", "ghostty").checked)
            clickFollow("ghostty")
            tryVerify(() => Services.ThemeOrchestrator.plan !== null)
            verify(control("follow", "ghostty").checked, "pending opt-in stays visible")
            mouseClick(control("cancel", "ghostty"))
            verify(!control("follow", "ghostty").checked, "cancel restores unchecked")

            clickFollow("ghostty")
            tryVerify(() => Services.ThemeOrchestrator.plan !== null)
            changeBase.running = true
            tryCompare(changeBase, "running", false)
            confirm("ghostty")
            verify(!control("follow", "ghostty").checked, "enrollment failure rolls checkbox back")
            verify(row("ghostty").error.indexOf("preview changed") >= 0, "useful enrollment error")

            clickFollow("ghostty"); confirm("ghostty")
            verify(row("ghostty").enabled && row("ghostty").installed)
            verify(control("follow", "ghostty").checked)
            verify(findChild(page, "themeStatus-ghostty").text.indexOf("Reload required") >= 0)
            clickFollow("ghostty"); idle()
            verify(!control("follow", "ghostty").checked && !row("ghostty").installed)

            // Installed executable, missing audited config: interactive with a clear
            // setup error, never silently disabled because it is not enrolled.
            clickFollow("btop"); idle()
            verify(!control("follow", "btop").checked)
            verify(row("btop").error.indexOf("configuration missing") >= 0)

            // The already-confirmed profile is supplied by discovery; no text entry.
            clickFollow("zen"); confirm("zen")
            verify(control("follow", "zen").checked)
            verify(row("zen").result.indexOf("Manual workspace colour required") >= 0)
            verify(findChild(page, "themeStatus-zen").text.indexOf("Restart Zen") >= 0)
            // Real production Copy pointer -> existing clipboard backend -> stub
            // wl-copy. Python asserts exact bytes for every current palette.
            for (const theme of Palette.ThemeRegistry.themes) {
                Services.Settings.setTheme(theme.id)
                tryCompare(Services.ThemeOrchestrator, "zenWorkspaceColor", theme.roles.background)
                tryVerify(() => row("zen").publishedPalette === theme.id)
                idle()
                verify(findChild(page, "zenWorkspaceColor").text.indexOf(theme.roles.background) >= 0)
                if (theme.id === "catppuccin-mocha") compare(theme.roles.background, "#1e1e2e")
                if (theme.id === "everforest-dark-hard") compare(theme.roles.background, "#272e33")
                const copy = findChild(page, "copyZenWorkspaceColor")
                reveal(copy); mouseClick(copy)
                tryCompare(Services.ThemeOrchestrator, "copyingZenColor", false)
                compare(Services.ThemeOrchestrator.copyMessage, "Copied")
            }
            clickFollow("zen"); idle()
            verify(!row("zen").installed)

            clickFollow("ghostty"); confirm("ghostty")
            editHook.running = true
            tryCompare(editHook, "running", false)
            clickFollow("ghostty"); idle()
            verify(!control("follow", "ghostty").checked, "conflict still stops future writes")
            verify(row("ghostty").error.length > 0, "changed hook is protected and reported")
            console.log("Theme pointer PASS: opt-in, visible confirmation, cancel, disable, unavailable, failure, Zen and changed-hook protection")
        }
        function cleanupTestCase() { finish.start() }
    }
}
