pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth as QsBluetooth

Singleton {
    id: root

    readonly property var adapter: QsBluetooth.Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property bool discovering: available && adapter.discovering
    readonly property var devices:
        available ? adapter.devices : null

    property var connectedDevices: []
    property var observedDevices: []

    readonly property int connectedCount: connectedDevices.length
    readonly property var primaryDevice:
        connectedCount > 0 ? connectedDevices[0] : null
    readonly property string statusText:
        !available ? "Bluetooth unavailable"
        : !enabled ? "Bluetooth off"
        : connectedCount === 0 ? "No connected devices"
        : connectedCount === 1 ? displayName(primaryDevice)
        : connectedCount + " devices connected"

    function displayName(device) {
        if (!device)
            return ""
        if (device.name && device.name.length > 0)
            return device.name
        if (device.deviceName && device.deviceName.length > 0)
            return device.deviceName
        return device.address
    }

    function batteryPercent(device) {
        if (!device || !device.batteryAvailable)
            return -1
        return Math.round(device.battery * 100)
    }

    function rebuildConnectedDevices() {
        const next = []

        for (let index = 0; index < observedDevices.length; ++index) {
            const device = observedDevices[index]
            if (device && device.connected)
                next.push(device)
        }

        connectedDevices = next
    }

    function registerDevice(device) {
        if (!device || observedDevices.indexOf(device) >= 0)
            return

        observedDevices = observedDevices.concat([device])
        rebuildConnectedDevices()
    }

    function unregisterDevice(device) {
        const next = observedDevices.filter(function(candidate) {
            return candidate !== device
        })
        observedDevices = next
        rebuildConnectedDevices()
    }

    function setEnabled(value) {
        if (available)
            adapter.enabled = value
    }

    function setDiscovering(value) {
        if (available && enabled)
            adapter.discovering = value
    }

    function toggleConnection(device) {
        if (!device)
            return

        if (device.connected)
            device.disconnect()
        else if (device.paired || device.bonded)
            device.connect()
    }

    property Instantiator deviceObserver: Instantiator {
        model: root.devices

        delegate: QtObject {
            id: deviceEntry

            required property var modelData
            readonly property var device: modelData

            Component.onCompleted: root.registerDevice(device)
            Component.onDestruction: root.unregisterDevice(device)

            property Connections deviceConnections: Connections {
                target: deviceEntry.device

                function onConnectedChanged() {
                    root.rebuildConnectedDevices()
                }
            }
        }
    }
}
