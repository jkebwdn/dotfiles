import QtQuick
import Quickshell
import "../../.config/quickshell/magi/modules" as Modules
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property var originalWifi: null
    function check(ok, label) { if (!ok) { failures++; console.error("FAIL: " + label) } }
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
            switch (test.step++) {
            case 0:
                test.originalWifi = registry.modules.wifi
                test.check(Object.keys(registry.modules).length === 4, "all independent modules exist")
                test.check(registry.modules.bluetooth.pill === null, "no hidden Bluetooth pill")
                Services.MenuController.open("controlcentre")
                break
            case 1:
                test.check(surface.phase === 3, "CC opens without bar delegates")
                Services.MenuController.navigate("bluetooth")
                break
            case 2:
                test.check(surface.phase === 3 && surface.displayedModule === registry.modules.bluetooth,
                    "hidden Bluetooth detail navigation")
                Services.MenuController.navigate("wifi")
                break
            case 3:
                test.check(surface.phase === 3 && registry.modules.wifi === test.originalWifi,
                    "Wi-Fi session identity survives navigation")
                // Exercise the preserved secured-network handoff against a stub backend/window.
                registry.modules.wifi.selectNetwork({connected:false,known:false,security:999,name:"Test"})
                break
            case 4:
                test.check(registry.modules.wifi.selectedNetwork !== null && surface.phase === 0,
                    "password handoff waits for collapse")
                test.check(registry.interactionBusy, "password blocks destructive placement")
                registry.modules.wifi.cancelPassword()
                break
            case 5:
                test.check(surface.phase === 3 && surface.displayedModule === test.originalWifi,
                    "cancel restores same browser session")
                Services.MenuController.close()
                break
            case 6:
                test.check(surface.phase === 0 && registry.modules.bluetooth.pill === null, "clean close without hidden pills")
                console.log("RESULT: " + test.failures + " failures; module ownership/handoff")
                Qt.quit()
            }
        }
    }
}
