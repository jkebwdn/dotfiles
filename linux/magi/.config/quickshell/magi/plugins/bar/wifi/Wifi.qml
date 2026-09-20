
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking

import "../../../theme" as MagiTheme
import "../../../services" as MagiServices

Rectangle {
    id: root

    property bool menuOpen: false
    property var selectedNetwork: null
    property var pendingNetwork: null
    property string connectionError: ""

    readonly property bool connecting: pendingNetwork !== null

    implicitWidth: 26
    implicitHeight: 26

    radius: MagiTheme.Theme.radiusMedium

    color: mouseArea.containsMouse || menuOpen
        ? MagiTheme.Theme.elevated
        : MagiTheme.Theme.surface

    function signalIcon(strength) {
        if (strength >= 75)
            return "󰤨"

        if (strength >= 50)
            return "󰤥"

        if (strength >= 25)
            return "󰤢"

        return "󰤟"
    }

    function clearSelection() {
        passwordInput.text = ""
        selectedNetwork = null
    }

    function selectNetwork(network) {
        if (network === null || network.connected || connecting)
            return

        connectionError = ""
        clearSelection()

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

        // A secured network needs keyboard input.
        // Close the browsing popup and open the focusable window.
        selectedNetwork = network
        menuOpen = false
    }

    function submitPassword() {
        if (selectedNetwork === null
                || passwordInput.text.length === 0
                || connecting) {
            return
        }

        const network = selectedNetwork
        const password = passwordInput.text

        connectionError = ""
        pendingNetwork = network

        MagiServices.Network.connectWithPassword(
            network,
            password
        )

        clearSelection()
        menuOpen = true
    }

    function connectionSucceeded(network) {
        if (pendingNetwork !== network)
            return

        pendingNetwork = null
        connectionError = ""
        clearSelection()
    }

    function connectionFailed(network) {
        if (pendingNetwork !== network)
            return

        pendingNetwork = null
        connectionError =
            "Connection failed. Check the password or try again."
    }

    // Bar icon

    Text {
        anchors.centerIn: parent

        text: MagiServices.Network.icon

        color: MagiServices.Network.connected
            ? MagiTheme.Theme.text
            : MagiTheme.Theme.muted

        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 14
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (root.selectedNetwork !== null)
                root.clearSelection()
            else
                root.menuOpen = !root.menuOpen
        }
    }

    // Hover tooltip

    PopupWindow {
        id: wifiTooltip

        anchor.item: root
        anchor.rect.x: root.width / 2 - width / 2
        anchor.rect.y: root.height + 6

        implicitWidth: tooltipText.implicitWidth + 20
        implicitHeight: 28

        visible: mouseArea.containsMouse
            && !root.menuOpen
            && root.selectedNetwork === null

        color: "transparent"

        Rectangle {
            anchors.fill: parent

            radius: MagiTheme.Theme.radiusSmall
            color: MagiTheme.Theme.elevated

            Text {
                id: tooltipText

                anchors.centerIn: parent

                text: MagiServices.Network.statusText
                color: MagiTheme.Theme.text

                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 12
            }
        }
    }

    // Network selector: browsing only, no keyboard input required.

    PopupWindow {
        id: wifiMenu

        anchor.item: root
        anchor.rect.x: root.width - width
        anchor.rect.y: root.height + 8

        implicitWidth: 300
        implicitHeight: 350

        visible: root.menuOpen
        color: "transparent"

        onVisibleChanged: {
            MagiServices.Network.setScanning(
                visible || root.selectedNetwork !== null
            )

            if (!visible && root.selectedNetwork === null)
                root.connectionError = ""
        }

        Rectangle {
            anchors.fill: parent

            radius: MagiTheme.Theme.radiusMedium
            color: MagiTheme.Theme.elevated

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Header

                Item {
                    width: parent.width
                    height: 26

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Wi-Fi"

                        color: MagiTheme.Theme.text
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        width: 48
                        height: 24

                        radius: MagiTheme.Theme.radiusSmall
                        color: MagiTheme.Theme.surface

                        Text {
                            anchors.centerIn: parent

                            text: MagiServices.Network.wifiEnabled
                                ? "On"
                                : "Off"

                            color: MagiTheme.Theme.text
                            font.family: MagiTheme.Theme.fontFamily
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                MagiServices.Network.setWifiEnabled(
                                    !MagiServices.Network.wifiEnabled
                                )

                                root.clearSelection()
                                root.connectionError = ""
                            }
                        }
                    }
                }

                // Connection status

                Text {
                    width: parent.width

                    text: !MagiServices.Network.wifiEnabled
                        ? "Wi-Fi is off"
                        : MagiServices.Network.connected
                            ? "Connected: " + MagiServices.Network.ssid
                            : "Not connected"

                    color: MagiTheme.Theme.text
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: parent.width
                    height: 1

                    color: MagiTheme.Theme.muted
                    opacity: 0.25
                }

                Text {
                    visible: MagiServices.Network.wifiEnabled

                    text: "Available networks"

                    color: MagiTheme.Theme.muted
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 11
                }

                // Scrollable network list

                Flickable {
                    width: parent.width
                    height: 225

                    visible: MagiServices.Network.wifiEnabled

                    contentWidth: width
                    contentHeight: networkColumn.implicitHeight

                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: networkColumn

                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: MagiServices.Network.wifiEnabled
                                ? MagiServices.Network.availableNetworks
                                : null

                            delegate: Rectangle {
                                id: networkRow

                                required property var modelData

                                readonly property int strength:
                                    Math.round(modelData.signalStrength * 100)

                                width: networkColumn.width
                                height: 36

                                radius: MagiTheme.Theme.radiusSmall

                                color: networkMouse.containsMouse
                                    ? MagiTheme.Theme.surface
                                    : "transparent"

                                Connections {
                                    target: networkRow.modelData

                                    function onConnectedChanged() {
                                        if (networkRow.modelData.connected) {
                                            root.connectionSucceeded(
                                                networkRow.modelData
                                            )
                                        }
                                    }

                                    function onConnectionFailed(reason) {
                                        root.connectionFailed(
                                            networkRow.modelData
                                        )
                                    }
                                }

                                Text {
                                    id: networkIcon

                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: root.signalIcon(networkRow.strength)

                                    color: MagiTheme.Theme.text
                                    font.family: MagiTheme.Theme.fontFamily
                                    font.pixelSize: 14
                                }

                                Text {
                                    anchors.left: networkIcon.right
                                    anchors.leftMargin: 8
                                    anchors.right: networkStrength.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: networkRow.modelData.name

                                    color: MagiTheme.Theme.text
                                    font.family: MagiTheme.Theme.fontFamily
                                    font.pixelSize: 12

                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: networkStrength

                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: networkRow.modelData.connected
                                        ? "✓"
                                        : networkRow.strength + "%"

                                    color: networkRow.modelData.connected
                                        ? MagiTheme.Theme.text
                                        : MagiTheme.Theme.muted

                                    font.family: MagiTheme.Theme.fontFamily
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: networkMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    cursorShape: networkRow.modelData.connected
                                        || root.connecting
                                        ? Qt.ArrowCursor
                                        : Qt.PointingHandCursor

                                    onClicked: {
                                        root.selectNetwork(
                                            networkRow.modelData
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width

                    visible: !MagiServices.Network.wifiEnabled

                    text: "Turn on Wi-Fi to see nearby networks."

                    color: MagiTheme.Theme.muted
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 12

                    wrapMode: Text.WordWrap
                }

                // Connection feedback

                Text {
                    width: parent.width

                    visible: root.connectionError !== ""
                        || root.connecting

                    text: root.connectionError !== ""
                        ? root.connectionError
                        : "Connecting…"

                    color: root.connectionError !== ""
                        ? MagiTheme.Theme.muted
                        : MagiTheme.Theme.text

                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 11

                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    // Separate layer-shell window for password entry.
    // OnDemand allows it to receive keyboard focus.

    PanelWindow {
        id: passwordWindow

        anchors {
            top: true
            right: true
        }

        margins {
            top: 48
            right: 16
        }

        implicitWidth: 300
        implicitHeight: 150

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        visible: root.selectedNetwork !== null
        color: "transparent"

        onVisibleChanged: {
            MagiServices.Network.setScanning(
                visible || root.menuOpen
            )

            if (visible)
                passwordInput.forceActiveFocus()
        }

        Rectangle {
            anchors.fill: parent

            radius: MagiTheme.Theme.radiusMedium
            color: MagiTheme.Theme.elevated

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    width: parent.width

                    text: root.selectedNetwork !== null
                        ? "Connect to " + root.selectedNetwork.name
                        : ""

                    color: MagiTheme.Theme.text
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true

                    elide: Text.ElideRight
                }

                Rectangle {
                    width: parent.width
                    height: 32

                    radius: MagiTheme.Theme.radiusSmall
                    color: MagiTheme.Theme.surface

                    TextInput {
                        id: passwordInput

                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        activeFocusOnTab: true
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password

                        color: MagiTheme.Theme.text
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 12

                        selectByMouse: true

                        onAccepted: root.submitPassword()
                    }
                }

                Row {
                    spacing: 8

                    Rectangle {
                        width: 80
                        height: 26

                        radius: MagiTheme.Theme.radiusSmall
                        color: MagiTheme.Theme.surface

                        Text {
                            anchors.centerIn: parent

                            text: "Connect"

                            color: MagiTheme.Theme.text
                            font.family: MagiTheme.Theme.fontFamily
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.submitPassword()
                        }
                    }

                    Rectangle {
                        width: 70
                        height: 26

                        radius: MagiTheme.Theme.radiusSmall
                        color: MagiTheme.Theme.surface

                        Text {
                            anchors.centerIn: parent

                            text: "Cancel"

                            color: MagiTheme.Theme.text
                            font.family: MagiTheme.Theme.fontFamily
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.clearSelection()
                                root.connectionError = ""
                                root.menuOpen = true
                            }
                        }
                    }
                }
            }
        }
    }
}
