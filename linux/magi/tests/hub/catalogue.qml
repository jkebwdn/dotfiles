import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/modules" as Modules
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/components/hub" as UI
ShellRoot {
    id: test
    property int step: 0
    property int modeIndex: 0
    property var modes: ["apps", "clipboard", "notifications", "emoji", "settings"]
    property string selected: modes[Math.min(modeIndex, modes.length - 1)]
    function check(ok, label) { if (!ok) throw new Error(selected + " step " + step + ": " + label) }
    Modules.ModuleRegistry { id: registry; barWindow: null; sharedSurface: surface }
    FloatingWindow {
      id: host; visible: true; implicitWidth: 1000; implicitHeight: 800
      Bar.SharedStatusSurface {
        id: surface
        combined: true
        modules: Object.values(registry.modules)
        requestedModule: registry.modules[Services.MenuController.activeMenu] || null
        statusContent: Component { Item { implicitWidth: 120; implicitHeight: 28 } }
    }
    }
    UI.HubWindow { id: window; readyToOpen: surface.phase === 0 }
    Timer { id: finish; interval: 200; onTriggered: Qt.quit() }
    TestCase {
        name: "HubCatalogue"
        when: Services.Settings.ready && Services.Emoji.entries.length > 0 && host.visible
        function test_routes() {
            try {
                Services.SurfaceOrigin.mainScreen = host.screen
                Services.SurfaceOrigin.enabledScreens = [host.screen]
                Services.Settings.resetSection("controlCentre")
                for (const mode of test.modes) Services.Settings.addEntry("actions", mode)
                Services.Settings.setValue("controlCentre", "columns", 3)
                Services.Settings.setValue("controlCentre", "actionColumns", 2)
                for (const mode of test.modes) {
                    Services.MenuController.open("controlcentre")
                    tryCompare(surface, "phase", 3)
                    compare(registry.modules.controlcentre.actions.length, 11)
                    compare(registry.modules.controlcentre.columns, 3)
                    compare(registry.modules.controlcentre.actionColumns, 2)
                    Modules.ControlCatalog.primary(mode)
                    verify(Services.Hub.opened)
                    compare(Services.Hub.mode, mode)
                    verify(!Services.MenuController.activeMenu && !window.visible,
                           "Destination waits for actual collapse")
                    tryCompare(surface, "phase", 0)
                    tryCompare(window, "visible", true)
                    tryVerify(function() {
                        const content = window.content.currentContent
                        return content && ((mode === "notifications" || mode === "settings")
                            ? content.activeFocus : content.searchField.activeFocus)
                    })
                    verify(!Services.Notifications.serverActivated && !Services.Clipboard.activated)
                    Services.Hub.close()
                    Services.MenuController.open("controlcentre")
                    tryCompare(surface, "phase", 3)
                    tryCompare(window, "visible", false)
                }
                Services.Hub.suppressed = true
                Modules.ControlCatalog.primary("notifications")
                verify(!Services.Hub.opened && Services.MenuController.activeMenu === "controlcentre")
                Services.Hub.suppressed = false
                Services.MenuController.close()
                console.log("RESULT: 0 failures; Hub catalogue: optional entries, five routes, real collapse gate, focus, reopen, unavailable handling")
            } catch (error) {
                console.error("FAIL", error, error.stack)
            } finally { finish.start() }
        }
    }
}
