import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
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
        color: Palette.Theme.background
        Pane {
            anchors.fill: parent; padding: 0
            font.family: "Noto Sans"; font.pixelSize: 13
            palette.window: Palette.Theme.background
            palette.windowText: Palette.Theme.text
            palette.text: Palette.Theme.text
            palette.buttonText: Palette.Theme.text
            background: Rectangle { color: Palette.Theme.background }
            Pages.AppearancePage { id: page; anchors.fill: parent }
        }
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
            const labels = [
                ["Applied — reactive palette", "Applied"],
                ["Runtime update accepted; configerrors clear (visual check required)", "Applied"],
                ["Reload required — :colorscheme magi; otherwise next launch", "Reload"],
                ["Relaunch Thunar required; system scheme requested; GTK4 full palette deferred", "Relaunch"],
                ["Next launch after terminal palette reload; inherits Ghostty ANSI", "Next launch"],
                ["Next prompt in shells with MAGI environment; existing shells need a new shell", "New shell"],
                ["CSS generated · Manual workspace colour required · Restart Zen after CSS changes", "Manual step"],
                ["Restart application after changes", "Restart"],
                ["Future adapter with a long status that should remain in details", "Details"]
            ]
            for (const pair of labels) compare(page.compactThemeResult(pair[0]), pair[1])
            verify(!control("follow", "qt").enabled, "deferred target is disabled")
            verify(findChild(page, "themeStatus-qt").text.indexOf("Unavailable") >= 0)
            verify(!findChild(page, "themeStatus-qt").visible, "deferred detail is quiet")
            const deferredDetails = findChild(page, "themeDetails-qt")
            reveal(deferredDetails); mouseClick(deferredDetails)
            verify(findChild(page, "themeStatus-qt").visible, "deferred reason remains available")
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
            verify(findChild(page, "themeStatus-ghostty").visible, "errors are never collapsed")
            compare(findChild(page, "themeSummary-ghostty").text, "Error")

            clickFollow("ghostty"); confirm("ghostty")
            verify(row("ghostty").enabled && row("ghostty").installed)
            verify(control("follow", "ghostty").checked)
            verify(findChild(page, "themeStatus-ghostty").text.indexOf("Reload required") >= 0)
            verify(!findChild(page, "themeStatus-ghostty").visible, "healthy verbose detail is collapsed")
            compare(findChild(page, "themeSummary-ghostty").text, "Reload")
            const details = findChild(page, "themeDetails-ghostty")
            reveal(details); mouseClick(details)
            verify(findChild(page, "themeStatus-ghostty").visible, "full reload instructions remain available")
            mouseClick(details)
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
                if (["catppuccin-mocha", "catppuccin-frappe", "everforest-dark-hard", "everforest-light-hard"].includes(theme.id)) {
                    for (const contentWidth of [530, 750]) {
                        window.width = contentWidth
                        wait(80)
                        for (const target of Services.ThemeOrchestrator.targets) {
                            const summary = findChild(page, "themeSummary-" + target.id)
                            compare(summary.lineCount, 1, "collapsed status remains one line")
                            verify(summary.text.length <= 13, "collapsed status uses concise labels")
                            const follow = control("follow", target.id)
                            const details = findChild(page, "themeDetails-" + target.id)
                            const point = details.mapToItem(page, details.width, 0)
                            verify(point.x <= page.width && follow.width >= 130, "target controls remain bounded")
                        }
                        page.contentY = Math.max(0, control("follow", "ghostty").mapToItem(page.contentItem, 0, 0).y - 60)
                        wait(50)
                        const directory = Quickshell.env("MAGI_SETTINGS_CAPTURES")
                        if (directory) grabImage(window.contentItem).save(directory + "/targets-" + theme.id + "-" + contentWidth + ".png")
                    }
                }
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
