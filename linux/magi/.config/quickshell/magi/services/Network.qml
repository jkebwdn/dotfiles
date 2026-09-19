
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

QtObject {
    id: root

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled

    property var wifiDevice: null
    property var activeNetwork: null

    readonly property bool connected:
        activeNetwork !== null && activeNetwork.connected

    readonly property string ssid:
        connected ? activeNetwork.name : ""

    readonly property int signalStrength:
        connected ? activeNetwork.signalStrength : 0

    readonly property string statusText:
        !wifiHardwareEnabled ? "Wi-Fi unavailable"
        : !wifiEnabled ? "Wi-Fi disabled"
        : connected ? ssid + " (" + signalStrength + "%)"
        : "Wi-Fi disconnected"

    readonly property string icon:
        !wifiHardwareEnabled || !wifiEnabled ? "󰤭"
        : !connected ? "󰤯"
        : signalStrength >= 75 ? "󰤨"
        : signalStrength >= 50 ? "󰤥"
        : signalStrength >= 25 ? "󰤢"
        : "󰤟"

    property Instantiator deviceObserver: Instantiator {
        model: Networking.devices

        delegate: QtObject {
            required property var modelData

            // Keep track of the first available Wi-Fi device.
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

    property Instantiator networkObserver: Instantiator {
        model: root.wifiDevice !== null
            ? root.wifiDevice.networks
            : null

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
