pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool active: false
    property bool priorWifi: false
    property bool priorBluetooth: false
    function begin(wifiEnabled, bluetoothEnabled) {
        root.priorWifi = !!wifiEnabled
        root.priorBluetooth = !!bluetoothEnabled
        root.active = true
    }
    function end() {
        const restore = {wifi:root.priorWifi, bluetooth:root.priorBluetooth}
        root.active = false
        return restore
    }
    function cancel() { root.active = false }
}
