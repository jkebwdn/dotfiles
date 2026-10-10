import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/modules" as Modules
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/components/hub" as UI
ShellRoot {
    id: test
    property int step: 0
    property int modeIndex: 0
    property var modes: ["apps", "notifications", "emoji", "clipboard"]
    property string selected: modes[Math.min(modeIndex, modes.length - 1)]
    function check(ok, label) { if (!ok) throw new Error(selected + " step " + step + ": " + label) }
    Modules.ModuleRegistry { id: registry; barWindow: null; sharedSurface: surface }
    Bar.SharedStatusSurface {
        id: surface
        combined: true
        modules: Object.values(registry.modules)
        requestedModule: registry.modules[Services.MenuController.activeMenu] || null
        statusContent: Component { Item { implicitWidth: 120; implicitHeight: 28 } }
    }
    UI.HubWindow { id: window; readyToOpen: surface.phase === 0 }
    Timer { id: finish; interval: 200; onTriggered: Qt.quit() }
    Timer {
        id: sequence
        interval: 550; running: true; repeat: true
        onTriggered: {
            if (!Services.Settings.ready || !Services.Emoji.entries.length) return
            switch (test.step++) {
            case 0:
                Services.Settings.resetSection("controlCentre")
                for (const mode of test.modes) Services.Settings.addEntry("actions", mode)
                Services.Settings.setValue("controlCentre", "columns", 3)
                Services.Settings.setValue("controlCentre", "actionColumns", 2)
                Services.MenuController.open("controlcentre")
                break
            case 1:
                test.check(surface.phase === 3, "CC fully open")
                test.check(registry.modules.controlcentre.actions.length === 10, "optional entries render")
                test.check(registry.modules.controlcentre.columns === 3 && registry.modules.controlcentre.actionColumns === 2, "independent columns")
                Modules.ControlCatalog.primary(test.selected)
                test.check(Services.Hub.opened && Services.Hub.mode === test.selected, "catalogue selects Hub mode")
                test.check(!Services.MenuController.activeMenu && !window.visible, "destination waits for actual collapse")
                break
            case 2:
                test.check(surface.phase === 0 && window.visible, "handoff completed")
                test.check(test.selected === "notifications" ? window.content.currentContent.activeFocus
                    : window.content.currentContent.searchField.activeFocus, "destination focus")
                test.check(!Services.Notifications.serverActivated && !Services.Clipboard.activated, "no backend ownership change")
                Services.Hub.close()
                Services.MenuController.open("controlcentre")
                break
            case 3:
                test.check(surface.phase === 3 && !window.visible, "CC reopens after Hub")
                if (++test.modeIndex < test.modes.length) { test.step = 1; break }
                Services.Hub.suppressed = true
                Modules.ControlCatalog.primary("notifications")
                test.check(!Services.Hub.opened && Services.MenuController.activeMenu === "controlcentre", "unavailable destination does not dismiss CC")
                Services.Hub.suppressed = false
                Services.MenuController.close()
                console.log("RESULT: 0 failures; Hub catalogue: optional entries, four routes, real collapse gate, focus, reopen, unavailable handling")
                sequence.stop(); finish.start()
            }
        }
    }
}
