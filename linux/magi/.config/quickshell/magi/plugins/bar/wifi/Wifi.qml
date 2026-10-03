pragma ComponentBehavior: Bound

import QtQuick
import "../../../icons" as Icons
import Quickshell.Networking

import "../../../components/bar" as MagiBar
import "../../../components/controls" as MagiControls
import "../../../services" as MagiServices
import "../../../theme" as MagiTheme

MagiBar.ExpandableModule {
    id: root

    property var selectedNetwork: null
    property var pendingNetwork: null
    property var errorNetwork: null
    property string connectionError: ""
    signal clearPassword()
    readonly property bool connecting: pendingNetwork !== null
    readonly property bool authenticating: selectedNetwork !== null
    readonly property int listCount: {
        const networks = MagiServices.Network.availableNetworks
        const values = networks && typeof networks.values !== "function" ? networks.values || networks : networks || []
        return values.filter(n => !n.connected).length
    }
    readonly property real baseHeight: !MagiServices.Network.wifiEnabled ? 122
        : 74 + (MagiServices.Network.connected ? 76 : 0) + Math.max(48, Math.min(6, listCount) * 48)
    menuId: "wifi"
    icon: !MagiServices.Network.wifiHardwareEnabled || !MagiServices.Network.wifiEnabled ? "wifi-off"
        : !MagiServices.Network.connected ? "wifi-disconnected" : signalIcon(MagiServices.Network.signalStrength)
    title: "Wi-Fi"
    collapsedWidth: 30
    expandedWidth: 344
    menuHeight: Math.min(barWindow && hostMode === "combined" ? barWindow.height - 100 : 640,
        baseHeight + (authenticating ? 124 : connectionError ? 38 : 0))
    color: sharedSurface ? Qt.alpha(MagiTheme.Theme.surface, 1 - sharedSurface.expansion) : MagiTheme.Theme.surface

    function signalIcon(strength) { return Icons.IconRegistry.signalRole(strength) }
    function updateScanning() { MagiServices.Network.setScanning(requestedOpen || connecting) }
    function resetTransientState() {
        clearPassword()
        selectedNetwork = null
        errorNetwork = null
        connectionError = ""
        updateScanning()
    }
    function selectNetwork(network) {
        if (!network || network.connected || connecting) return
        resetTransientState()
        if (network.known) {
            pendingNetwork = network
            MagiServices.Network.connectKnown(network)
        } else if (network.security === WifiSecurityType.Open) {
            pendingNetwork = network
            MagiServices.Network.connectOpen(network)
        } else selectedNetwork = network
        updateScanning()
    }
    function submitPassword(password) {
        if (!selectedNetwork || password.length === 0 || connecting) return
        connectionError = ""
        errorNetwork = null
        pendingNetwork = selectedNetwork
        MagiServices.Network.connectWithPassword(selectedNetwork, password)
        clearPassword()
        updateScanning()
    }
    // Cancels the UI session, not an already submitted NetworkManager operation.
    // The pending object is retained independently so late completion is observed.
    function cancelPassword() { resetTransientState() }
    function connectionSucceeded(network) {
        if (pendingNetwork !== network) return
        pendingNetwork = null
        resetTransientState()
    }
    function connectionFailed(network) {
        if (pendingNetwork !== network) return
        pendingNetwork = null
        if (requestedOpen) {
            connectionError = "Connection failed. Check the password and retry."
            errorNetwork = network
            if (network.security !== WifiSecurityType.Open) selectedNetwork = network
        }
        updateScanning()
    }
    onRequestedOpenChanged: {
        if (!requestedOpen) resetTransientState()
        updateScanning()
    }
    onSelectedNetworkChanged: clearPassword()
    onPendingNetworkChanged: updateScanning()
    Connections {
        target: root.pendingNetwork
        function onConnectedChanged() {
            if (root.pendingNetwork && root.pendingNetwork.connected) root.connectionSucceeded(root.pendingNetwork)
        }
        function onConnectionFailed(reason) { root.connectionFailed(root.pendingNetwork) }
    }
    Connections {
        target: MagiServices.Network
        function onWifiEnabledChanged() { if (!MagiServices.Network.wifiEnabled) root.resetTransientState() }
    }

    pillContent: Component {
        MagiControls.MorphingPillContent {
            pill: parent
            moduleId: "wifi"
            icon: root.icon
            expandedTitle: MagiServices.Network.connected
                ? MagiServices.Network.ssid
                : "Wi-Fi"
            expandedStatus: MagiServices.Network.connected
                ? MagiServices.Network.signalStrength + "%"
                : MagiServices.Network.wifiEnabled ? "Scanning" : "Off"
            iconColor: MagiServices.Network.connected
                ? MagiTheme.Theme.accent
                : MagiTheme.Theme.muted
        }
    }

    menuContent: Component {
        WifiMenuContent {
            controller: root
        }
    }

}
