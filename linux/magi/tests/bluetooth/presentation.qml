import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/plugins/bar/bluetooth" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    QtObject {
        id: speaker
        property string name: "Headphones"
        property string address: "11:22:33:44:55:66"
        property string dbusPath: "/org/bluez/hci0/dev_11_22_33_44_55_66"
        property bool paired: false
        property bool bonded: false
        property bool pairing: false
        property bool connected: false
        property int state: 0
        property bool batteryAvailable: false
    }
    QtObject {
        id: other
        property string name: "Headphones"
        property string address: "11:22:33:44:55:77"
        property string dbusPath: "/org/bluez/hci0/dev_11_22_33_44_55_77"
        property bool paired: false
        property bool bonded: false
        property bool pairing: false
        property bool connected: false
        property int state: 0
        property bool batteryAvailable: false
    }
    QtObject {
        id: adapter
        property bool enabled: true
        property bool discovering: false
        property var devices: [speaker, other]
    }
    UI.Bluetooth { id: module }
    FloatingWindow {
        id: win
        visible: true
        implicitWidth: 350
        implicitHeight: 390
        color: "#20202c"
        Loader { id: body; anchors.fill: parent; anchors.margins: 12; sourceComponent: module.menuContent }
    }
    Timer { id: done; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "BluetoothProductionMenu"
        when: Services.Settings.ready
        function eq(actual, expected) { if (actual !== expected) throw new Error("Expected " + expected + ", got " + actual + " " + new Error().stack) }
        function ok(value) { if (!value) throw new Error("Assertion failed " + new Error().stack) }
        function status(state, error) {
            Services.Bluetooth.receive({event:"state",path:speaker.dbusPath,state:state,error:error || ""})
        }
        function test_pairing_and_auth() {
            try {
                Services.Bluetooth.adapter = adapter
                Services.Bluetooth.backendReady = true
                Services.MenuController.open("bluetooth")
                wait(400)
                let row = findChild(body, "bluetooth-device-" + speaker.dbusPath)
                let chip = findChild(body, "bluetooth-action-" + speaker.dbusPath)
                ok(row !== null); eq(chip.label,"Pair")
                mouseClick(row,20,20)
                eq(Services.Bluetooth.testCommands.length,1)
                eq(Services.Bluetooth.testCommands[0].path,speaker.dbusPath)
                eq(Services.Bluetooth.stateText(speaker),"Pairing…")
                mouseClick(row,20,20); Services.Bluetooth.toggleConnection(other)
                eq(Services.Bluetooth.testCommands.length,1)
                status("Pairing…")
                for (let kind of ["pin","passkey","confirm","displayPin","displayPasskey","authorize","service"]) {
                    Services.Bluetooth.receive({event:"prompt",prompt:{id:10,path:speaker.dbusPath,kind:kind,value:kind === "confirm" ? "000123" : ""}})
                    wait(20)
                    let input=findChild(body,"bluetooth-auth-input")
                    let confirm=findChild(body,"bluetooth-auth-confirm")
                    if (kind === "pin" || kind === "passkey") {
                        ok(!confirm.available)
                        input.text=kind === "pin" ? "0123" : "000123"
                        ok(confirm.available)
                        input.forceActiveFocus(); keyClick(Qt.Key_Return)
                        eq(Services.Bluetooth.testCommands.slice(-1)[0].action,"answer")
                        eq(Services.Bluetooth.testCommands.slice(-1)[0].value,input.text)
                    } else if (!kind.startsWith("display")) {
                        confirm.forceActiveFocus(); keyClick(Qt.Key_Space)
                        eq(Services.Bluetooth.testCommands.slice(-1)[0].accepted,true)
                    } else ok(!confirm.visible)
                }
                Services.Bluetooth.receive({event:"prompt",prompt:null})
                speaker.paired=true
                status("Connecting…")
                ok(!Services.Bluetooth.canAct(speaker))
                status("", "Connection failed. Check the device and try again.")
                ok(Services.Bluetooth.canAct(speaker))
                ok(Services.Bluetooth.stateText(speaker).startsWith("Connection failed"))
                row.forceActiveFocus();keyClick(Qt.Key_Return)
                eq(Services.Bluetooth.testCommands.slice(-1)[0].path,speaker.dbusPath)
                status("")
                speaker.connected=true; speaker.state=1
                wait(20)
                eq(Services.Bluetooth.connectedCount,1)
                Services.Bluetooth.toggleConnection(speaker)
                eq(Services.Bluetooth.actionState,"Disconnecting…")
                status("");speaker.connected=false;speaker.state=0;speaker.paired=false
                speaker.pairing=true;ok(!Services.Bluetooth.canAct(speaker));speaker.pairing=false
                speaker.state=3;ok(!Services.Bluetooth.canAct(speaker));speaker.state=2;ok(!Services.Bluetooth.canAct(speaker));speaker.state=0
                // Discovery belongs to this menu only if MAGI started it.
                Services.Bluetooth.setDiscovering(true);ok(adapter.discovering)
                Services.Bluetooth.toggleConnection(other)
                eq(Services.Bluetooth.testCommands.slice(-1)[0].path,other.dbusPath)
                Services.MenuController.close()
                ok(!adapter.discovering);ok(!Services.Bluetooth.busy)
                Services.MenuController.open("bluetooth")
                adapter.discovering=true
                Services.MenuController.close();ok(adapter.discovering)
                adapter.enabled=false;ok(!Services.Bluetooth.canAct(speaker))
                console.log("Bluetooth production menu/service and authentication PASS")
            } catch (error) { console.error("Bluetooth fixture FAIL: " + error); throw error } finally { Services.Bluetooth.adapter = null; done.start() }
        }
    }
}
