
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

QtObject {
    id: root

    // Wi-Fi state

    readonly property bool wifiEnabled:
        Networking.wifiEnabled

    readonly property bool wifiHardwareEnabled:
        Networking.wifiHardwareEnabled

    property var wifiDevice: null
    property var activeNetwork: null

    readonly property bool connected:
        activeNetwork !== null && activeNetwork.connected

    readonly property string ssid:
        connected ? activeNetwork.name : ""

    // Quickshell reports signal strength as a fraction (0.0–1.0).

    readonly property int signalStrength:
        connected ? Math.round(activeNetwork.signalStrength * 100) : 0

    readonly property string statusText:
        !wifiHardwareEnabled ? "Wi-Fi unavailable"
        : !wifiEnabled ? "Wi-Fi disabled"
        : connected ? ssid + " (" + signalStrength + "%)"
        : "Wi-Fi disconnected"

    // Wi-Fi icon

    readonly property string icon:
        !wifiHardwareEnabled || !wifiEnabled ? "󰤭"
        : !connected ? "󰤯"
        : signalStrength >= 75 ? "󰤨"
        : signalStrength >= 50 ? "󰤥"
        : signalStrength >= 25 ? "󰤢"
        : "󰤟"

    // Available networks for the Wi-Fi menu

    readonly property var availableNetworks:
        wifiDevice !== null ? wifiDevice.networks : null

    // Wi-Fi controls

    function setWifiEnabled(enabled) {
        Networking.wifiEnabled = enabled
    }

    function setScanning(enabled) {
        if (wifiDevice !== null)
            wifiDevice.scannerEnabled = enabled
    }

    // Connection controls

    // Connect using an existing NetworkManager profile.

    function connectKnown(network) {
        if (network === null || network.connected || !network.known)
            return

        network.connect()
    }

    // Connect to a new password-protected network.

    function connectWithPassword(network, password) {
        if (network === null || network.connected || password.length === 0)
            return

        network.connectWithPsk(password)
    }

    // Connect to an open network.

    function connectOpen(network) {
        if (network === null || network.connected)
            return

        network.connect()
    }

    // Find the first available Wi-Fi device

    property Instantiator deviceObserver: Instantiator {
        model: Networking.devices

        delegate: QtObject {
            required property var modelData

            Component.onCompleted: {
                if (modelData.type === DeviceType.Wifi
                        && root.wifiDevice === null) {
                    root.wifiDevice = modelData
                }
            }

            Component.onDestruction: {
                if (root.wifiDevice === modelData) {
                    root.wifiDevice = null
                    root.activeNetwork = null
                }
            }
        }
    }

    // Track the connected network

    property Instantiator networkObserver: Instantiator {
        model: root.availableNetworks

        delegate: QtObject {
            required property var modelData

            function updateActiveNetwork() {
                if (modelData.connected) {
                    root.activeNetwork = modelData
                } else if (root.activeNetwork === modelData) {
                    root.activeNetwork = null
                }
            }

            Component.onCompleted: updateActiveNetwork()

            Component.onDestruction: {
                if (root.activeNetwork === modelData)
                    root.activeNetwork = null
            }

            property Connections connectionObserver: Connections {
                target: modelData

                function onConnectedChanged() {
                    updateActiveNetwork()
                }
            }
        }
    }
}
