pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth

import "../../../components/bar" as MagiBar
import "../../../components/controls" as MagiControls
import "../../../services" as MagiServices
import "../../../theme" as MagiTheme

MagiBar.ExpandableModule {
    id: root

    readonly property var connectedDevice:
        MagiServices.Bluetooth.primaryDevice
    readonly property string connectedName:
        MagiServices.Bluetooth.displayName(connectedDevice)
    readonly property int connectedBattery:
        MagiServices.Bluetooth.batteryPercent(connectedDevice)
    readonly property int connectedPillWidth: Math.min(210, Math.max(
        118,
        46 + connectedName.length * 7 + (connectedBattery >= 0 ? 42 : 0)
    ))

    menuId: "bluetooth"
    icon: !MagiServices.Bluetooth.enabled ? "bluetooth-off"
        : connectedDevice ? "bluetooth-connected" : "bluetooth"
    title: "Bluetooth"
    collapsedWidth: connectedDevice ? connectedPillWidth : 30
    expandedWidth: 326
    menuHeight: 350
    color: sharedSurface
        ? Qt.alpha(MagiTheme.Theme.surface, 1 - sharedSurface.expansion)
        : MagiTheme.Theme.surface
    barVisible: connectedDevice !== null
        || (!sharedSurface && (requestedOpen || phase !== 0))

    pillContent: Component {
        MagiControls.MorphingPillContent {
            pill: parent
            moduleId: "bluetooth"
            icon: root.icon
            collapsedText: root.connectedDevice
                ? root.connectedName
                    + (root.connectedBattery >= 0
                        ? " · " + root.connectedBattery + "%"
                        : "")
                : ""
            expandedTitle: root.connectedDevice
                ? root.connectedName
                : "Bluetooth"
            expandedStatus: root.connectedBattery >= 0
                ? root.connectedBattery + "%"
                : root.connectedDevice
                    ? "Connected"
                    : MagiServices.Bluetooth.enabled ? "On" : "Off"
            iconColor: root.connectedDevice
                ? MagiTheme.Theme.accent
                : MagiServices.Bluetooth.enabled
                    ? MagiTheme.Theme.text
                    : MagiTheme.Theme.muted
        }
    }

    menuContent: Component {
        Column {
            width: parent ? parent.width : 0
            spacing: 10

            Item {
                width: parent.width
                height: 30

                Column {
                    anchors {
                        left: parent.left
                        right: adapterToggle.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 1

                    Text {
                        width: parent.width
                        text: root.connectedDevice
                            ? "Connected and ready"
                            : MagiServices.Bluetooth.enabled
                                ? "Ready for known devices"
                                : "Bluetooth is off"
                        color: MagiTheme.Theme.text
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: MagiServices.Bluetooth.enabled
                            ? root.connectedDevice
                                ? "Manage the active connection below"
                                : "Scan to find nearby devices"
                            : "Turn on to connect devices"
                        color: MagiTheme.Theme.muted
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                MagiControls.ActionChip {
                    moduleId: "bluetooth"
                    id: adapterToggle

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    label: MagiServices.Bluetooth.enabled ? "On" : "Off"
                    active: MagiServices.Bluetooth.enabled
                    available: MagiServices.Bluetooth.available
                    onTriggered: MagiServices.Bluetooth.setEnabled(
                        !MagiServices.Bluetooth.enabled
                    )
                }
            }

            Rectangle {
                id: connectedCard

                width: parent.width
                visible: root.connectedDevice !== null
                height: visible ? 58 : 0
                radius: MagiTheme.Theme.radiusMedium
                color: MagiTheme.Theme.background

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        right: disconnectChip.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 3

                    Text {
                        width: parent.width
                        text: root.connectedName
                        color: MagiTheme.Theme.text
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.connectedBattery >= 0
                            ? "Battery "
                                + root.connectedBattery + "%"
                            : "Connected"
                        color: MagiTheme.Theme.muted
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                MagiControls.ActionChip {
                    moduleId: "bluetooth"
                    id: disconnectChip

                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    label: "Disconnect"
                    available: root.connectedDevice !== null
                    onTriggered: MagiServices.Bluetooth.toggleConnection(
                        root.connectedDevice
                    )
                }
            }

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.connectedDevice
                        ? "OTHER DEVICES"
                        : "KNOWN & NEARBY"
                    color: MagiTheme.Theme.muted
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 0.8
                }

                MagiControls.ActionChip {
                    moduleId: "bluetooth"
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    icon: MagiServices.Bluetooth.discovering ? "scanning" : "scan"
                    label: MagiServices.Bluetooth.discovering
                        ? "Stop"
                        : "Scan"
                    active: MagiServices.Bluetooth.discovering
                    available: MagiServices.Bluetooth.enabled
                    onTriggered: MagiServices.Bluetooth.setDiscovering(
                        !MagiServices.Bluetooth.discovering
                    )
                }
            }

            Flickable {
                width: parent.width
                height: root.connectedDevice ? 176 : 244
                contentWidth: width
                contentHeight: deviceColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: MagiServices.Bluetooth.enabled

                Column {
                    id: deviceColumn

                    width: parent.width
                    spacing: 5

                    Repeater {
                        model: MagiServices.Bluetooth.devices

                        delegate: Rectangle {
                            id: deviceRow

                            required property var modelData

                            readonly property string displayName:
                                MagiServices.Bluetooth.displayName(modelData)
                            readonly property int batteryPercent:
                                MagiServices.Bluetooth.batteryPercent(modelData)
                            readonly property bool canConnect:
                                modelData.connected
                                || modelData.paired
                                || modelData.bonded
                            readonly property bool changing:
                                modelData.state
                                    === BluetoothDeviceState.Connecting
                                || modelData.state
                                    === BluetoothDeviceState.Disconnecting
                            readonly property string deviceState: {
                                if (modelData.state
                                        === BluetoothDeviceState.Connecting) {
                                    return "Connecting"
                                }
                                if (modelData.state
                                        === BluetoothDeviceState.Disconnecting) {
                                    return "Disconnecting"
                                }
                                if (modelData.paired || modelData.bonded)
                                    return "Paired"
                                return "Available"
                            }

                            width: deviceColumn.width
                            visible: !modelData.connected
                            height: visible ? 44 : 0
                            radius: MagiTheme.Theme.radiusSmall
                            color: deviceHover.hovered
                                ? MagiTheme.Theme.elevated
                                : modelData.paired || modelData.bonded
                                    ? MagiTheme.Theme.background
                                    : "transparent"

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    right: deviceAction.left
                                    rightMargin: 10
                                    top: parent.top
                                    topMargin: 5
                                }
                                text: deviceRow.displayName
                                color: MagiTheme.Theme.text
                                font.family: MagiTheme.Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: deviceRow.modelData.paired
                                    || deviceRow.modelData.bonded
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    bottom: parent.bottom
                                    bottomMargin: 5
                                }
                                text: deviceRow.batteryPercent >= 0
                                    ? deviceRow.deviceState + " · Battery "
                                        + deviceRow.batteryPercent + "%"
                                    : deviceRow.deviceState
                                color: MagiTheme.Theme.muted
                                font.family: MagiTheme.Theme.fontFamily
                                font.pixelSize: 9
                            }

                            MagiControls.ActionChip {
                    moduleId: "bluetooth"
                                id: deviceAction

                                anchors {
                                    right: parent.right
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                visible: deviceRow.canConnect
                                label: deviceRow.changing
                                    ? deviceRow.deviceState
                                    : "Connect"
                                available: !deviceRow.changing
                                onTriggered:
                                    MagiServices.Bluetooth.toggleConnection(
                                        deviceRow.modelData
                                    )
                            }

                            HoverHandler {
                                id: deviceHover
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: !MagiServices.Bluetooth.enabled
                text: MagiServices.Bluetooth.available
                    ? "Turn on Bluetooth to manage known devices."
                    : "No Bluetooth adapter is available."
                color: MagiTheme.Theme.muted
                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }
}
