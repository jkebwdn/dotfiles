pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth as QsBluetooth

Singleton {
    id: root

    readonly property var adapter: QsBluetooth.Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: available && !!adapter.enabled
    readonly property bool discovering: available && !!adapter.discovering
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

    // Runtime transaction state only. Quickshell remains the device model.
    property string actionPath: ""
    property string actionName: ""
    property string actionState: ""
    property string actionError: ""
    property var prompt: null
    property bool backendReady: false
    property var queued: null
    property bool ownsDiscovery: false
    readonly property bool busy: actionState !== ""

    function stateText(device) {
        if (!device) return "Unavailable"
        if (device.dbusPath === actionPath && (actionError || actionState))
            return actionError || actionState
        if (device.pairing) return "Pairing…"
        if (device.state === QsBluetooth.BluetoothDeviceState.Connecting) return "Connecting…"
        if (device.state === QsBluetooth.BluetoothDeviceState.Disconnecting) return "Disconnecting…"
        return device.connected ? "Connected" : device.paired || device.bonded ? "Paired" : "Available"
    }

    function canAct(device) {
        return enabled && !!device && !busy && !device.pairing
            && device.state !== QsBluetooth.BluetoothDeviceState.Connecting
            && device.state !== QsBluetooth.BluetoothDeviceState.Disconnecting
    }

    function send(request) {
        if (backendReady && worker.running) worker.write(JSON.stringify(request) + "\n")
    }

    function toggleConnection(device) {
        if (!canAct(device)) return
        if (!device.dbusPath) {
            actionError = "Device unavailable"
            return
        }
        actionName = displayName(device)
        actionPath = device.dbusPath
        actionError = ""
        actionState = device.connected ? "Disconnecting…"
            : device.paired || device.bonded ? "Connecting…" : "Pairing…"
        const request = {action: "select", path: actionPath}
        if (backendReady) send(request)
        else {
            queued = request
            worker.running = true
            startupTimeout.restart()
        }
    }

    function answer(accepted, value) {
        if (prompt) send({action: "answer", id: prompt.id, accepted: accepted, value: value || ""})
    }

    function cancel() {
        queued = null
        if (backendReady) send({action: "cancel"})
        actionState = ""
        actionError = "Pairing cancelled"
        prompt = null
    }

    function receive(event) {
        if (event.event === "ready") {
            startupTimeout.stop()
            backendReady = true
            if (queued) { send(queued); queued = null }
        } else if (event.event === "state") {
            actionPath = event.path
            actionState = event.state
            actionError = event.error
        } else if (event.event === "prompt") {
            prompt = event.prompt
            // A request is only possible for a deliberate action in this menu.
            if (prompt && !MenuController.isOpen("bluetooth")) cancel()
        } else if (event.event === "unavailable") {
            actionState = ""
            actionError = "Bluetooth service unavailable"
        }
    }

    function setDiscovering(value) {
        if (available && enabled) {
            if (value && !adapter.discovering) ownsDiscovery = true
            adapter.discovering = value
            if (value && ownsDiscovery) discoveryTimeout.restart()
            if (!value) { ownsDiscovery = false; discoveryTimeout.stop() }
        }
    }

    function stopOwnedDiscovery() {
        if (ownsDiscovery) setDiscovering(false)
        ownsDiscovery = false
        discoveryTimeout.stop()
    }

    onEnabledChanged: {
        if (!enabled) {
            stopOwnedDiscovery()
            if (busy) cancel()
        }
    }

    property Connections menuLifecycle: Connections {
        target: MenuController
        function onActiveMenuChanged() {
            if (!MenuController.isOpen("bluetooth")) {
                root.stopOwnedDiscovery()
                if (root.prompt || root.actionState === "Pairing…") root.cancel()
            }
        }
    }

    property Timer discoveryTimeout: Timer {
        interval: 30000
        onTriggered: root.stopOwnedDiscovery()
    }
    property Timer startupTimeout: Timer {
        interval: 10000
        onTriggered: {
            root.queued = null
            worker.running = false
            root.actionState = ""
            root.actionError = "Bluetooth service unavailable"
        }
    }
    property Process worker: Process {
        command: ["python3", Qt.resolvedUrl("bluetooth_backend.py").toString().replace(/^file:\/\//, "")]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => {
                try { root.receive(JSON.parse(data)) }
                catch (error) { console.warn("Invalid Bluetooth backend response") }
            }
        }
        onExited: {
            startupTimeout.stop()
            root.backendReady = false
            root.queued = null
            root.prompt = null
            if (root.busy) root.actionError = "Bluetooth operation interrupted. Try again."
            root.actionState = ""
        }
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
                target: deviceEntry.device || null

                function onConnectedChanged() {
                    root.rebuildConnectedDevices()
                }
            }
        }
    }
}
