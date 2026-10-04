import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/launcher" as UI
import "../../.config/quickshell/magi/components/settings/pages" as Pages
ShellRoot {
    property int step: 0
    property var originalApps: []
    function check(ok, label) { if (!ok) throw new Error("Hidden applications step " + step + ": " + label) }
    function restoreButton(item) {
        if (item.text === "Restore") return item
        for (const child of item.children || []) {
            const match = restoreButton(child)
            if (match) return match
        }
        return null
    }
    FloatingWindow {
        visible: true; implicitWidth: 720; implicitHeight: 640
        UI.LauncherContent { id: ui; anchors.fill: parent; service: Services.Launcher }
    }
    FloatingWindow {
        visible: false; implicitWidth: 720; implicitHeight: 640
        Pages.LauncherPage { id: settings; anchors.fill: parent }
    }
    Timer {
        interval: 450; repeat: true; running: true
        onTriggered: {
            if (!Services.Settings.ready) return
            const launcher = Services.Launcher
            switch (step++) {
            case 0:
                Services.Settings.resetSection("launcher")
                launcher.open()
                break
            case 1:
                check(launcher.results.length === 1, "discovery")
                originalApps = launcher.applications
                ui.focusSearch()
                ui.navigate(Qt.Key_Menu, Qt.NoModifier)
                break
            case 2:
                check(ui.contextMenu.opened && ui.contextMenu.activeFocus, "keyboard context popup focus")
                ui.contextMenu.itemAt(0).triggered()
                ui.contextMenu.close()
                break
            case 3:
                check(launcher.results.length === 0, "hide from list")
                check(ui.searchField.activeFocus, "search focus restored")
                check(!launcher.busy && launcher.opened, "hide never launches/closes")
                check(Services.Settings.saveState === "saved", "hide saved")
                check(launcher.hiddenApplications[0].name === "MAGI Launch Fixture", "friendly hidden name")
                launcher.query = "MAGI Launch Fixture"
                check(launcher.results.length === 0, "search exclusion")
                Services.Settings.setValue("launcher","layout","grid")
                break
            case 4:
                check(ui.grid && launcher.results.length === 0, "grid exclusion")
                Services.Settings.discardAndReload()
                break
            case 5:
                check(launcher.preferences.hiddenIds[0] === "magi-test.desktop", "persist and reload")
                check(launcher.results.length === 0, "reload exclusion")
                launcher.applications = []
                check(launcher.hiddenApplications[0].id === "magi-test.desktop"
                    && launcher.hiddenApplications[0].unavailable, "uninstalled entry remains restorable")
                break
            case 6: {
                const button = restoreButton(settings)
                check(!!button, "restore UI exists")
                button.clicked()
                check(launcher.preferences.hiddenIds.length === 0, "restore UI action")
                launcher.applications = originalApps
                check(launcher.results.length === 1, "restored in search/grid")
                launcher.hide("magi-test.desktop")
                check(launcher.preferences.hiddenIds.length === 1, "hide again")
                check(launcher.hide("magi-test.desktop") && launcher.preferences.hiddenIds.length === 1, "hide idempotent")
                check(!launcher.hide("unknown.desktop"), "unknown hide rejected")
                Services.Settings.resetSection("launcher")
                break
            }
            case 7:
                check(!ui.grid && launcher.preferences.hiddenIds.length === 0 && launcher.results.length === 1, "reset restores all")
                check(Services.Settings.saveState === "saved", "reset saved")
                console.log("Hidden applications contextual action, list/grid/search, persistence, unavailable ID, Restore UI and reset PASS")
                Qt.quit()
            }
        }
    }
}
