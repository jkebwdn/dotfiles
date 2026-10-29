pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth

import "../../../components/bar" as MagiBar
import "../../../components/controls" as MagiControls
import "../../../services" as MagiServices
import "../../../theme" as MagiTheme

MagiBar.ExpandableModule {
    id: root
    styleId: "bluetooth"

    readonly property var connectedDevice:
        MagiServices.Bluetooth.primaryDevice
    readonly property string connectedName:
        MagiServices.Bluetooth.displayName(connectedDevice)
    readonly property int connectedBattery:
        MagiServices.Bluetooth.batteryPercent(connectedDevice)
    function deviceList(model) {
        return (Array.isArray(model) ? model : model ? model.values || [] : []).filter(device => !!device)
    }
    readonly property var orderedDevices: {
        const devices = deviceList(MagiServices.Bluetooth.devices)
        return devices.filter(device => device.paired || device.bonded)
            .concat(devices.filter(device => !device.paired && !device.bonded))
    }
    menuId: "bluetooth"
    icon: !MagiServices.Bluetooth.enabled ? "bluetooth-off"
        : connectedDevice ? "bluetooth-connected" : "bluetooth"
    title: "Bluetooth"
    collapsedWidth: 30
    expandedWidth: 326
    menuHeight: 350
    color: sharedSurface
        ? Qt.alpha(root.itemBackground, root.itemBackground.a * (1 - sharedSurface.expansion))
        : root.itemBackground
    barVisible: MagiServices.Bluetooth.connectedCount > 0

    pillContent: Component {
        MagiControls.MorphingPillContent {
            pill: parent
            moduleId: "bluetooth"
            icon: root.icon
            collapsedText: ""
            expandedTitle: root.connectedDevice
                ? root.connectedName
                : "Bluetooth"
            expandedStatus: root.connectedBattery >= 0
                ? root.connectedBattery + "%"
                : root.connectedDevice
                    ? "Connected"
                    : MagiServices.Bluetooth.enabled ? "On" : "Off"
            iconColor: root.connectedDevice
                ? MagiTheme.Theme.barAccent("bluetooth")
                : MagiTheme.Theme.barItemForeground("bluetooth", MagiServices.Bluetooth.enabled
                    ? MagiTheme.Theme.text : MagiTheme.Theme.muted, false)
        }
    }

    menuContent: Component {
        Column {
            width: parent ? parent.width : 0
            spacing: 12

            Item {
                width: parent.width
                height: 30

                Column {
                    anchors {
                        right: parent.right
                        left: adapterToggle.right
                        leftMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 1

                    Text {
                        width: parent.width
                        text: MagiServices.Bluetooth.busy ? MagiServices.Bluetooth.actionState
                            : root.connectedDevice ? "Connected and ready"
                            : MagiServices.Bluetooth.enabled
                                ? "Ready to pair and connect"
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
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                MagiControls.CompactToggle {
                    Accessible.name: "Bluetooth"
                    id: adapterToggle

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    checked: MagiServices.Bluetooth.enabled
                    enabled: MagiServices.Bluetooth.available
                    onToggled: MagiServices.Bluetooth.setEnabled(checked)
                }
            }

            Rectangle {
                id: connectedCard

                width: parent.width
                visible: root.connectedDevice !== null && !MagiServices.Bluetooth.prompt
                height: visible ? 72 : 0
                radius: MagiTheme.Theme.radiusMedium
                color: MagiTheme.Theme.elevated

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
                        textFormat: Text.PlainText
                        text: root.connectedName
                        color: MagiTheme.Theme.text
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: MagiServices.Bluetooth.stateText(root.connectedDevice)
                            + (root.connectedBattery >= 0 ? " · Battery " + root.connectedBattery + "%" : "")
                        color: MagiTheme.Theme.muted
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                MagiControls.ActionChip {
                    activeFocusOnTab: true
                    moduleId: "bluetooth"
                    id: disconnectChip

                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    label: MagiServices.Bluetooth.busy && root.connectedDevice
                        && root.connectedDevice.dbusPath === MagiServices.Bluetooth.actionPath
                        ? "Working…" : "Disconnect"
                    Accessible.name: root.connectedName + ", " + MagiServices.Bluetooth.stateText(root.connectedDevice)
                    available: MagiServices.Bluetooth.canAct(root.connectedDevice)
                    onTriggered: MagiServices.Bluetooth.toggleConnection(
                        root.connectedDevice
                    )
                }
            }

            Item {
                width: parent.width
                height: visible ? 28 : 0
                visible: !MagiServices.Bluetooth.prompt

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.connectedDevice
                        ? "Other devices"
                        : "Known & nearby"
                    color: MagiTheme.Theme.muted
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 11
                    font.letterSpacing: 0
                }

                MagiControls.ActionChip {
                    activeFocusOnTab: true
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

            BluetoothAuthentication {
                width: parent.width
                visible: MagiServices.Bluetooth.prompt !== null
                height: visible ? implicitHeight : 0
            }

            Text {
                width: parent.width
                visible: text.length > 0 && !MagiServices.Bluetooth.prompt
                text: MagiServices.Bluetooth.actionError
                textFormat: Text.PlainText
                color: MagiTheme.Theme.subtext
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Flickable {
                width: parent.width
                height: MagiServices.Bluetooth.prompt ? 0
                    : (root.connectedDevice ? 150 : 234) - (MagiServices.Bluetooth.actionError ? 42 : 0)
                contentWidth: width
                contentHeight: deviceColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: MagiServices.Bluetooth.enabled && !MagiServices.Bluetooth.prompt

                Text {
                    width: parent.width
                    visible: deviceColumn.implicitHeight === 0
                    text: MagiServices.Bluetooth.discovering ? "Searching for devices…" : "No devices found. Scan to discover nearby devices."
                    color: MagiTheme.Theme.subtext; font.pixelSize: 12; wrapMode: Text.WordWrap
                }
                Column {
                    id: deviceColumn

                    width: parent.width
                    spacing: 5

                    Repeater {
                        id: deviceRows
                        model: root.orderedDevices

                        delegate: Rectangle {
                            id: deviceRow
                            objectName: "bluetooth-device-" + modelData.dbusPath

                            required property var modelData

                            readonly property string displayName:
                                MagiServices.Bluetooth.displayName(modelData)
                            readonly property int batteryPercent:
                                MagiServices.Bluetooth.batteryPercent(modelData)
                            readonly property bool changing: !MagiServices.Bluetooth.canAct(modelData)
                            readonly property string deviceState: MagiServices.Bluetooth.stateText(modelData)
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: displayName + ", " + deviceState
                            Accessible.onPressAction: MagiServices.Bluetooth.toggleConnection(modelData)
                            Keys.onReturnPressed: MagiServices.Bluetooth.toggleConnection(modelData)
                            Keys.onSpacePressed: MagiServices.Bluetooth.toggleConnection(modelData)
                            border.width: activeFocus ? 1 : 0
                            border.color: MagiTheme.Theme.focus

                            MouseArea {
                                anchors { left: parent.left; right: deviceAction.left; top: parent.top; bottom: parent.bottom }
                                onClicked: MagiServices.Bluetooth.toggleConnection(deviceRow.modelData)
                            }

                            width: deviceColumn.width
                            visible: !modelData.connected
                            height: visible ? 52 : 0
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
                                textFormat: Text.PlainText
                                text: deviceRow.displayName
                                color: MagiTheme.Theme.text
                                font.family: MagiTheme.Theme.fontFamily
                                font.pixelSize: 13
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
                                    right: deviceAction.left
                                    rightMargin: 8
                                }
                                elide: Text.ElideRight
                                text: deviceRow.batteryPercent >= 0
                                    ? deviceRow.deviceState + " · Battery "
                                        + deviceRow.batteryPercent + "%"
                                    : deviceRow.deviceState
                                color: MagiTheme.Theme.muted
                                font.family: MagiTheme.Theme.fontFamily
                                font.pixelSize: 11
                            }

                            MagiControls.ActionChip {
                                activeFocusOnTab: true
                                moduleId: "bluetooth"
                                id: deviceAction
                                objectName: "bluetooth-action-" + deviceRow.modelData.dbusPath

                                anchors {
                                    right: parent.right
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                label: MagiServices.Bluetooth.busy && deviceRow.modelData.dbusPath === MagiServices.Bluetooth.actionPath
                                    ? "Working…" : deviceRow.modelData.paired || deviceRow.modelData.bonded ? "Connect" : "Pair"
                                Accessible.name: deviceRow.displayName + ", " + deviceRow.deviceState
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
