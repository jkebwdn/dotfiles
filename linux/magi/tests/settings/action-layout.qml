import QtQuick
import Quickshell
import "../../.config/quickshell/magi/modules" as Modules
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property real baseline: 0
    function check(value, label) { if (!value) { failures++; console.error("FAIL: " + label) } }
    Modules.ModuleRegistry { id: registry; barWindow: null; sharedSurface: surface }
    Bar.SharedStatusSurface {
        id: surface
        combined: true
        modules: Object.values(registry.modules)
        requestedModule: registry.modules[Services.MenuController.activeMenu] || null
        statusContent: Component { Item { implicitWidth: 120; implicitHeight: 28 } }
    }
    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: {
            if (!Services.Settings.ready) return
            const cc = registry.modules.controlcentre
            switch (test.step++) {
            case 0: Services.MenuController.open("controlcentre"); break
            case 1:
                test.check(surface.phase === 3 && cc.actions.length === 6 && cc.actionRows === 1, "default action row")
                test.baseline = cc.menuHeight
                Services.Settings.setValue("controlCentre", "actionColumns", 3)
                break
            case 2:
                test.check(surface.phase === 3 && cc.actionRows === 2 && cc.menuHeight > test.baseline
                    && surface.revealedHeight === cc.menuHeight, "action columns retarget open surface")
                const entries = JSON.parse(JSON.stringify(Services.Settings.data.controlCentre.actions))
                for (let i=0;i<3;i++) entries[i].enabled=false
                Services.Settings.setEntries("actions", entries)
                break
            case 3:
                test.check(cc.actions.length === 3 && cc.actionRows === 1 && cc.menuHeight === test.baseline
                    && surface.phase === 3, "action enable state retargets")
                const key = Services.Settings.data.controlCentre.actions[5].key
                Services.Settings.moveEntry("actions", key, -1)
                break
            case 4:
                test.check(cc.actions[1].module === "shutdown" && surface.phase === 3, "action order updates live")
                Services.MenuController.close()
                break
            case 5:
                test.check(surface.phase === 0, "clean close")
                console.log("RESULT: " + failures + " failures; secondary action layout")
                Qt.quit()
            }
        }
    }
}
