
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking

import "../../../theme" as MagiTheme
import "../../../services" as MagiServices

Rectangle {
    id: root

    property bool menuOpen: false

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

        onClicked: root.menuOpen = !root.menuOpen
    }

    // Hover tooltip

    PopupWindow {
        id: wifiTooltip

        anchor.item: root
        anchor.rect.x: root.width / 2 - width / 2
        anchor.rect.y: root.height + 6

        implicitWidth: tooltipText.implicitWidth + 20
        implicitHeight: 28

        visible: mouseArea.containsMouse && !root.menuOpen
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

    // Network selector

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
            MagiServices.Network.setScanning(visible)
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
                        id: wifiToggle

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        width: 48
                        height: 24

                        radius: MagiTheme.Theme.radiusSmall

                        color: toggleMouse.containsMouse
                            ? MagiTheme.Theme.surface
                            : MagiTheme.Theme.surface

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
                            id: toggleMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                MagiServices.Network.setWifiEnabled(
                                    !MagiServices.Network.wifiEnabled
                                )
                            }
                        }
                    }
                }

                // Connection status

                Text {
                    width: parent.width

                    text: MagiServices.Network.connected
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
                    text: "Available networks"

                    color: MagiTheme.Theme.muted
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 11
                }

                // Scrollable network list

                Flickable {
                    width: parent.width
                    height: 225

                    contentWidth: width
                    contentHeight: networkColumn.implicitHeight

                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: networkColumn

                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: MagiServices.Network.availableNetworks

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

                                // Signal icon

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

                                // Network name

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

                                // Signal percentage / connected indicator

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

                                    // Connection actions come next.
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
