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
    property var passwordCandidate: null
    property var pendingNetwork: null
    property string connectionError: ""

    readonly property bool connecting: pendingNetwork !== null

    menuId: "wifi"
    icon: !MagiServices.Network.wifiHardwareEnabled || !MagiServices.Network.wifiEnabled ? "wifi-off"
        : !MagiServices.Network.connected ? "wifi-disconnected" : signalIcon(MagiServices.Network.signalStrength)
    title: "Wi-Fi"
    collapsedWidth: 30
    expandedWidth: 328
    menuHeight: 390
    color: sharedSurface
        ? Qt.alpha(MagiTheme.Theme.surface, 1 - sharedSurface.expansion)
        : MagiTheme.Theme.surface

    function signalIcon(strength) { return Icons.IconRegistry.signalRole(strength) }

    function updateScanning() {
        MagiServices.Network.setScanning(
            requestedOpen
            || selectedNetwork !== null
            || passwordCandidate !== null
        )
    }

    function resetTransientState() {
        passwordWindow.clearPassword()
        passwordCandidate = null
        selectedNetwork = null
        connectionError = ""
        updateScanning()
    }

    function selectNetwork(network) {
        if (!network || network.connected || connecting)
            return

        connectionError = ""
        passwordWindow.clearPassword()

        if (network.known) {
            pendingNetwork = network
            MagiServices.Network.connectKnown(network)
            return
        }

        if (network.security === WifiSecurityType.Open) {
            pendingNetwork = network
            MagiServices.Network.connectOpen(network)
            return
        }

        passwordCandidate = network
        updateScanning()
        MagiServices.MenuController.close()
    }

    function showPasswordCandidate() {
        if (!passwordCandidate || phase !== 0)
            return

        selectedNetwork = passwordCandidate
        passwordCandidate = null
        passwordWindow.clearPassword()
        updateScanning()
    }

    function submitPassword(password) {
        if (!selectedNetwork || password.length === 0 || connecting)
            return

        const network = selectedNetwork
        connectionError = ""
        pendingNetwork = network

        MagiServices.Network.connectWithPassword(network, password)

        passwordWindow.clearPassword()
        selectedNetwork = null
        MagiServices.MenuController.open(menuId)
        updateScanning()
    }

    function cancelPassword() {
        passwordWindow.clearPassword()
        selectedNetwork = null
        connectionError = ""
        MagiServices.MenuController.open(menuId)
        updateScanning()
    }

    function connectionSucceeded(network) {
        if (pendingNetwork !== network)
            return

        pendingNetwork = null
        connectionError = ""
        passwordCandidate = null
        selectedNetwork = null
        passwordWindow.clearPassword()
        updateScanning()
    }

    function connectionFailed(network) {
        if (pendingNetwork !== network)
            return

        pendingNetwork = null
        connectionError =
            "Connection failed. Check the password or try again."
        updateScanning()
    }

    Connections {
        target: root

        function onRequestedOpenChanged() {
            if (!root.requestedOpen
                    && !root.selectedNetwork
                    && !root.passwordCandidate
                    && !root.pendingNetwork) {
                root.connectionError = ""
            }
            root.updateScanning()
        }

        function onPhaseChanged() {
            root.showPasswordCandidate()
        }
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

    WifiPasswordWindow {
        id: passwordWindow

        network: root.selectedNetwork
        connecting: root.connecting

        onSubmitted: password => root.submitPassword(password)
        onCancelled: root.cancelPassword()
    }
}
