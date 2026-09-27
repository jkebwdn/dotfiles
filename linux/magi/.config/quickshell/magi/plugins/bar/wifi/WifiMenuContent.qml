pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Networking

import "../../../components/controls" as MagiControls
import "../../../services" as MagiServices
import "../../../theme" as MagiTheme

Column {
    id: root

    required property var controller

    readonly property bool connectionStatusVisible:
        controller.connectionError !== "" || controller.connecting

    width: parent ? parent.width : 0
    spacing: 10

    Item {
        width: parent.width
        height: 30

        Column {
            anchors {
                left: parent.left
                right: radioToggle.left
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 2

            Text {
                width: parent.width
                text: !MagiServices.Network.wifiEnabled
                    ? "Wireless is off"
                    : MagiServices.Network.connected
                        ? "Connected"
                        : "Looking for a network"
                color: MagiTheme.Theme.text
                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
            }

            Text {
                width: parent.width
                text: MagiServices.Network.wifiEnabled
                    ? "Scanning nearby networks"
                    : "Turn on to discover networks"
                color: MagiTheme.Theme.muted
                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 8
            }
        }

        MagiControls.ActionChip {
                    moduleId: "wifi"
            id: radioToggle

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            label: MagiServices.Network.wifiEnabled ? "On" : "Off"
            active: MagiServices.Network.wifiEnabled
            available: MagiServices.Network.wifiHardwareEnabled
            onTriggered: {
                MagiServices.Network.setWifiEnabled(
                    !MagiServices.Network.wifiEnabled
                )
                root.controller.resetTransientState()
            }
        }
    }

    Rectangle {
        width: parent.width
        visible: MagiServices.Network.connected
        height: visible ? 62 : 0
        radius: MagiTheme.Theme.radiusMedium
        color: MagiTheme.Theme.background

        MagiControls.Icon {
            id: heroSignalIcon

            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            role: root.controller.signalIcon(
                MagiServices.Network.signalStrength
            )
            color: MagiTheme.Theme.accent
            moduleId: "wifi"
            size: 24
        }

        Column {
            anchors {
                left: heroSignalIcon.right
                leftMargin: 12
                right: signalValue.left
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            spacing: 3

            Text {
                width: parent.width
                text: MagiServices.Network.ssid
                color: MagiTheme.Theme.text
                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: MagiServices.Network.activeNetwork
                        && MagiServices.Network.activeNetwork.known
                    ? "Saved network · Signal strength"
                    : "Connected · Signal strength"
                color: MagiTheme.Theme.muted
                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        Text {
            id: signalValue

            anchors {
                right: parent.right
                rightMargin: 14
                verticalCenter: parent.verticalCenter
            }
            text: MagiServices.Network.signalStrength + "%"
            color: MagiTheme.Theme.text
            font.family: MagiTheme.Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
        }
    }

    Item {
        width: parent.width
        visible: MagiServices.Network.wifiEnabled
        height: visible ? 24 : 0

        Text {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            text: MagiServices.Network.connected
                ? "OTHER NETWORKS"
                : "AVAILABLE NETWORKS"
            color: MagiTheme.Theme.muted
            font.family: MagiTheme.Theme.fontFamily
            font.pixelSize: 8
            font.letterSpacing: 0.8
        }

        MagiControls.Icon {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            role: "scanning"
            color: MagiTheme.Theme.muted
            moduleId: "wifi"
            size: 10
        }
    }

    Flickable {
        width: parent.width
        height: {
            if (!MagiServices.Network.wifiEnabled)
                return 0
            if (MagiServices.Network.connected)
                return root.connectionStatusVisible ? 174 : 216
            return root.connectionStatusVisible ? 246 : 288
        }
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
                    readonly property bool pending:
                        root.controller.pendingNetwork === modelData
                    readonly property string networkState: {
                        if (pending)
                            return "Connecting"
                        if (modelData.known)
                            return "Saved"
                        if (modelData.security === WifiSecurityType.Open)
                            return "Open"
                        return "Secured"
                    }

                    width: networkColumn.width
                    visible: !modelData.connected
                    height: visible ? 44 : 0
                    radius: MagiTheme.Theme.radiusSmall
                    color: networkHover.hovered
                        ? MagiTheme.Theme.elevated
                        : modelData.known
                            ? MagiTheme.Theme.background
                            : "transparent"

                    Connections {
                        target: networkRow.modelData

                        function onConnectedChanged() {
                            if (networkRow.modelData.connected) {
                                root.controller.connectionSucceeded(
                                    networkRow.modelData
                                )
                            }
                        }

                        function onConnectionFailed(reason) {
                            root.controller.connectionFailed(
                                networkRow.modelData
                            )
                        }
                    }

                    MagiControls.Icon {
                        id: networkIcon

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        role: root.controller.signalIcon(networkRow.strength)
                        color: networkRow.pending
                            ? MagiTheme.Theme.accent
                            : MagiTheme.Theme.text
                        moduleId: "wifi"
                        size: 14
                    }

                    Column {
                        anchors {
                            left: networkIcon.right
                            leftMargin: 10
                            right: networkStrength.left
                            rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 2

                        Text {
                            width: parent.width
                            text: networkRow.modelData.name
                            color: MagiTheme.Theme.text
                            font.family: MagiTheme.Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: networkRow.modelData.known
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: networkRow.networkState
                            color: networkRow.pending
                                ? MagiTheme.Theme.accent
                                : MagiTheme.Theme.muted
                            font.family: MagiTheme.Theme.fontFamily
                            font.pixelSize: 8
                        }
                    }

                    Text {
                        id: networkStrength

                        anchors {
                            right: parent.right
                            rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        text: networkRow.strength + "%"
                        color: MagiTheme.Theme.muted
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 9
                    }

                    HoverHandler {
                        id: networkHover
                    }

                    TapHandler {
                        enabled: !networkRow.modelData.connected
                            && !root.controller.connecting
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.controller.selectNetwork(
                            networkRow.modelData
                        )
                    }
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        visible: !MagiServices.Network.wifiEnabled
        height: visible ? 72 : 0
        radius: MagiTheme.Theme.radiusMedium
        color: MagiTheme.Theme.background

        Text {
            anchors {
                left: parent.left
                right: parent.right
                margins: 14
                verticalCenter: parent.verticalCenter
            }
            text: MagiServices.Network.wifiHardwareEnabled
                ? "Turn on Wi-Fi to discover and connect to nearby networks."
                : "No wireless hardware is available."
            color: MagiTheme.Theme.muted
            font.family: MagiTheme.Theme.fontFamily
            font.pixelSize: 9
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        width: parent.width
        visible: root.connectionStatusVisible
        height: visible ? 34 : 0
        radius: MagiTheme.Theme.radiusSmall
        color: root.controller.connectionError !== ""
            ? MagiTheme.Theme.danger
            : MagiTheme.Theme.background

        Text {
            anchors {
                left: parent.left
                right: parent.right
                margins: 10
                verticalCenter: parent.verticalCenter
            }
            text: root.controller.connectionError !== ""
                ? root.controller.connectionError
                    + " Select the network to retry."
                : "Connecting…"
            color: MagiTheme.Theme.text
            font.family: MagiTheme.Theme.fontFamily
            font.pixelSize: 8
            elide: Text.ElideRight
        }
    }
}
