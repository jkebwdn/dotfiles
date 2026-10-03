pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Networking
import "../../.config/quickshell/magi/modules" as Modules
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property real closedAuthHeight: 0
    function check(ok,label) { if (!ok) {failures++;console.error("FAIL: "+label)} }
    QtObject {
        id: secured
        property bool connected: false; property bool known: false
        property int security: 999; property string name: "Secure test"; property real signalStrength: .7
        signal connectionFailed(int reason)
    }
    QtObject {
        id: open
        property bool connected: false; property bool known: false
        property int security: WifiSecurityType.Open; property string name: "Open test"; property real signalStrength: .2
        signal connectionFailed(int reason)
    }
    Modules.ModuleRegistry { id: registry; barWindow: null; sharedSurface: surface }
    Bar.SharedStatusSurface {
        id: surface
        combined: true
        modules: Object.values(registry.modules)
        requestedModule: registry.modules[Services.MenuController.activeMenu] || null
        statusContent: Component { Item { implicitWidth: 160; implicitHeight: 28 } }
    }
    function inputIn(item) {
        if (item.objectName === "wifiPasswordInput" && item.visible) return item
        for (const child of item.children || []) { const found = inputIn(child); if (found) return found }
        return null
    }
    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: {
            const wifi=registry.modules.wifi
            switch(test.step++) {
            case 0:
                Services.Network.availableNetworks=[secured,open]
                Services.MenuController.open("wifi"); break
            case 1:
                test.closedAuthHeight=wifi.menuHeight
                wifi.selectNetwork(secured); break
            case 2: {
                test.check(surface.phase===3 && wifi.authenticating && wifi.menuHeight>test.closedAuthHeight && surface.revealedHeight===wifi.menuHeight,"inline form retargets without collapse")
                test.check(Services.Network.scanning && registry.interactionBusy,"scan/structural guard retained")
                const input=test.inputIn(surface)
                test.check(!!input && input.echoMode===TextInput.Password,"masked real input exists")
                if(input){input.text="dummy-test-secret";input.accepted();test.check(input.text==="","Enter handler clears secret")}
                test.check(wifi.connecting && Services.Network.passwordCalls===1,"submit through existing backend")
                secured.connectionFailed(1);break
            }
            case 3:
                test.check(!wifi.connecting && wifi.selectedNetwork===secured && wifi.errorNetwork===secured && wifi.connectionError.length>0,"failure stays with row for retry")
                wifi.submitPassword("dummy-retry"); secured.connected=true; break
            case 4:
                test.check(!wifi.authenticating && !wifi.connecting && wifi.connectionError==="" && surface.phase===3,"success clears form without closing browser")
                secured.connected=false;wifi.selectNetwork(secured);break
            case 5:
                wifi.cancelPassword();test.check(!wifi.authenticating && Services.MenuController.activeMenu==="wifi","cancel retains browser")
                secured.known=true;wifi.selectNetwork(secured);test.check(Services.Network.knownCalls===1,"known-network path retained")
                secured.connected=true;break
            case 6:
                wifi.selectNetwork(open);test.check(Services.Network.openCalls===1,"open-network path retained")
                open.connected=true;break
            case 7:
                secured.connected=false;secured.known=false;wifi.selectNetwork(secured)
                wifi.submitPassword("late-result-test")
                Services.MenuController.navigate("bluetooth");break
            case 8:
                test.check(!wifi.authenticating && wifi.connecting,"navigation clears form but observes in-flight request")
                secured.connectionFailed(1)
                test.check(Services.MenuController.activeMenu==="bluetooth" && !wifi.authenticating && !wifi.connecting,"late failure does not reopen Wi-Fi or authentication")
                Services.MenuController.close();break
            case 9:
                test.check(surface.phase===0 && !Services.Network.scanning,"clean close ends scanning")
                console.log("RESULT: "+test.failures+" failures; inline Wi-Fi auth, secret clearing, retry, late callbacks and geometry")
                Qt.quit()
            }
        }
    }
}
