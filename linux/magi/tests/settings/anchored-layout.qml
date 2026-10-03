pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../.config/quickshell/magi/modules" as Modules
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    function check(ok,label) { if(!ok) { failures++;console.error("FAIL: "+label) } }
    QtObject { id: network; property bool connected: false; property bool known: false; property int security: 999; property string name: "Test"; property real signalStrength: .5; signal connectionFailed(int reason) }
    Modules.ModuleRegistry { id: registry; barWindow: null; hostMode: "anchored" }
    Bar.ModulePill { id: centre; module: registry.modules.controlcentre }
    Bar.ModulePill { id: wifi; module: registry.modules.wifi }
    Timer {
        interval: 500; repeat: true; running: true
        onTriggered: {
            const module=registry.modules.wifi
            switch(test.step++) {
            case 0: Services.MenuController.open("wifi"); break
            case 1:
                test.check(wifi.phase===3 && wifi.revealedHeight===module.menuHeight,"anchored opens")
                module.selectNetwork(network);break
            case 2:
                test.check(wifi.phase===3 && wifi.revealedHeight===module.menuHeight,"inline authentication retargets anchored height")
                module.cancelPassword();break
            case 3:
                test.check(wifi.phase===3 && wifi.revealedHeight===module.menuHeight,"cancel returns anchored height")
                Services.MenuController.close();break
            case 4:
                test.check(wifi.phase===0 && wifi.width===module.collapsedWidth,"anchored clean close")
                Services.MenuController.open("bluetooth");break
            case 5:
                const bluetooth=registry.modules.bluetooth
                test.check(bluetooth.fallbackPill && bluetooth.fallbackPill.phase===3,"hidden-from-bar fallback opens")
                bluetooth.requestGeometry(380,250);break
            case 6:
                const fallback=registry.modules.bluetooth.fallbackPill
                test.check(fallback.phase===3 && fallback.revealedHeight===250 && fallback.menuWidth===380,"hidden fallback retargets")
                Services.MenuController.close();break
            case 7:
                test.check(registry.modules.bluetooth.fallbackPill.phase===0,"hidden fallback closes")
                console.log("RESULT: "+test.failures+" failures; anchored geometry and inline form retarget")
                Qt.quit()
            }
        }
    }
}
