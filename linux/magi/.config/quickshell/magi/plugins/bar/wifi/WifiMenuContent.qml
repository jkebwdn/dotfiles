pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Networking
import "../../../components/controls" as Controls
import "../../../services" as Services
import "../../../theme" as Theme
Column {
    id: root
    required property var controller
    width: parent ? parent.width : 0
    spacing: 12
    function requestInitialFocus() {
        for (let i = 0; i < rows.count; ++i) {
            const row = rows.itemAt(i)
            if (row && row.authenticating) row.focusAuthentication()
        }
    }
    Keys.onEscapePressed: event => {
        if (root.controller.authenticating) { root.controller.cancelPassword(); event.accepted = true }
        else event.accepted = false
    }
    Item {
        width: parent.width; height: 30
        Controls.CompactToggle {
            id: radioToggle
            anchors.left: parent.left
            Accessible.name: "Wi-Fi"
            checked: Services.Network.wifiEnabled
            enabled: Services.Network.wifiHardwareEnabled
            onToggled: { Services.Network.setWifiEnabled(checked); root.controller.resetTransientState() }
        }
        Text {
            anchors.left: radioToggle.right; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
            text: Services.Network.wifiEnabled ? (Services.Network.wifiDevice !== null && Services.Network.wifiDevice.scannerEnabled ? "Scanning…" : "Wireless enabled") : "Wireless is off"
            color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily; font.pixelSize: 11
        }
    }

    Rectangle {
        id: connected
        width: parent.width; height: 72
        visible: Services.Network.connected && Services.Network.wifiEnabled
        radius: Theme.Theme.radiusMedium; color: Theme.Theme.elevated
        Controls.Icon {
            id: connectedIcon
            x: 12; anchors.verticalCenter: parent.verticalCenter
            size: 30; role: root.controller.signalIcon(Services.Network.signalStrength); moduleId: "wifi"; color: Theme.Theme.accent
        }
        Column {
            anchors { left: connectedIcon.right; leftMargin: 10; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 4
            Text { width: parent.width; text: Services.Network.ssid; font.pixelSize: 14; font.bold: true; color: Theme.Theme.text; elide: Text.ElideRight }
            Text { text: "Connected · " + Services.Network.signalStrength + "%"; font.pixelSize: 10; color: Theme.Theme.subtext }
        }
    }
    Text {
        id: listHeading
        visible: Services.Network.wifiEnabled
        text: "Nearby networks"; font.pixelSize: 12; color: Theme.Theme.muted
    }
    Flickable {
        id: list
        width: parent.width
        height: Math.max(48, root.controller.menuHeight - root.controller.viewTopPadding - root.controller.viewBottomPadding
            - 30 - 24 - listHeading.height - (connected.visible ? 84 : 0))
        visible: Services.Network.wifiEnabled
        contentHeight: networkColumn.implicitHeight; contentWidth: width
        clip: true; boundsBehavior: Flickable.StopAtBounds
        function showRow(row) {
            Qt.callLater(function() {
                const bottom = row.y + row.height
                if (bottom > list.contentY + list.height) list.contentY = bottom - list.height
                if (row.y < list.contentY) list.contentY = row.y
                list.returnToBounds()
            })
        }
        Text {
            width: parent.width
            visible: root.controller.listCount === 0
            text: Services.Network.wifiDevice !== null && Services.Network.wifiDevice.scannerEnabled ? "Searching for nearby networks…" : "No other networks found"
            color: Theme.Theme.subtext; font.pixelSize: 12; wrapMode: Text.WordWrap
        }
        Column {
            id: networkColumn
            width: list.width; spacing: 4
            Repeater {
                id: rows
                model: Services.Network.wifiEnabled ? Services.Network.availableNetworks : null
                Rectangle {
                    id: row
                    required property var modelData
                    readonly property bool authenticating: root.controller.selectedNetwork === modelData
                    readonly property bool pending: root.controller.pendingNetwork === modelData
                    readonly property bool failed: root.controller.errorNetwork === modelData
                    readonly property int strength: Math.round(modelData.signalStrength * 100)
                    width: networkColumn.width
                    visible: !modelData.connected
                    height: visible ? 52 + (authenticating ? 124 : failed ? 38 : 0) : 0
                    radius: Theme.Theme.radiusSmall
                    color: authenticating ? Theme.Theme.elevated : hover.hovered ? Theme.Theme.overlay : "transparent"
                    activeFocusOnTab: visible && !root.controller.connecting
                    Keys.onReturnPressed: root.controller.selectNetwork(modelData)
                    Keys.onSpacePressed: root.controller.selectNetwork(modelData)
                    border.width: activeFocus ? 1 : 0
                    border.color: Theme.Theme.focus
                    function focusAuthentication() { auth.requestInputFocus(); list.showRow(row) }
                    onAuthenticatingChanged: { if (authenticating) focusAuthentication() }
                    Item {
                        width: parent.width; height: 52
                        Controls.Icon {
                            id: signal
                            x: 8; anchors.verticalCenter: parent.verticalCenter; size: 22
                            role: root.controller.signalIcon(row.strength); moduleId: "wifi"
                            color: row.pending || row.authenticating ? Theme.Theme.accent : Theme.Theme.text
                        }
                        Column {
                            anchors { left: signal.right; leftMargin: 10; right: percentage.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 3
                            Text { width: parent.width; text: row.modelData.name; font.pixelSize: 13; color: Theme.Theme.text; elide: Text.ElideRight }
                            Text {
                                text: row.pending ? "Connecting…" : row.modelData.known ? "Saved" : row.modelData.security === WifiSecurityType.Open ? "Open" : "Secured"
                                font.pixelSize: 11; color: row.pending ? Theme.Theme.accent : Theme.Theme.muted
                            }
                        }
                        Text { id: percentage; anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: row.strength + "%"; font.pixelSize: 11; color: Theme.Theme.muted }
                        TapHandler { enabled: !row.modelData.connected && !root.controller.connecting; onTapped: root.controller.selectNetwork(row.modelData) }
                    }
                    WifiAuthentication {
                        id: auth
                        x: 10; y: 56; width: parent.width - 20
                        controller: root.controller; network: row.modelData
                        visible: row.authenticating
                    }
                    Text {
                        x: 10; y: 52; width: parent.width - 20
                        visible: row.failed && !row.authenticating
                        text: root.controller.connectionError; wrapMode: Text.WordWrap; color: Theme.Theme.danger; font.pixelSize: 10
                    }
                    HoverHandler { id: hover }
                }
            }
        }
    }
    Text {
        visible: !Services.Network.wifiEnabled
        width: parent.width
        text: Services.Network.wifiHardwareEnabled ? "Turn on Wi-Fi to discover nearby networks." : "No wireless hardware available."
        font.pixelSize: 11; color: Theme.Theme.muted; wrapMode: Text.WordWrap
    }
}
