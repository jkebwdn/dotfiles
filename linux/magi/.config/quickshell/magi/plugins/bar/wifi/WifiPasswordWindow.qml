import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../../theme" as MagiTheme

PanelWindow {
    id: root

    property var network: null
    property bool connecting: false

    signal submitted(string password)
    signal cancelled()

    function clearPassword() {
        passwordInput.text = ""
    }

    function requestInputFocus() {
        Qt.callLater(function() {
            if (root.visible)
                passwordInput.forceActiveFocus()
        })
    }

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

    visible: network !== null
    color: "transparent"

    onVisibleChanged: {
        if (visible)
            requestInputFocus()
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
                text: root.network
                    ? "Connect to " + root.network.name
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
                    enabled: !root.connecting
                    color: MagiTheme.Theme.text
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 12
                    selectByMouse: true

                    onAccepted: {
                        if (text.length > 0 && !root.connecting)
                            root.submitted(text)
                    }

                    Keys.onEscapePressed: function(event) {
                        root.cancelled()
                        event.accepted = true
                    }
                }
            }

            Row {
                spacing: 8

                Rectangle {
                    width: 80
                    height: 26
                    radius: MagiTheme.Theme.radiusSmall
                    color: connectMouse.containsMouse
                        ? MagiTheme.Theme.elevated
                        : MagiTheme.Theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: root.connecting ? "Connecting…" : "Connect"
                        color: MagiTheme.Theme.text
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: connectMouse

                        anchors.fill: parent
                        enabled: passwordInput.text.length > 0
                            && !root.connecting
                        hoverEnabled: true
                        cursorShape: enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor
                        onClicked: root.submitted(passwordInput.text)
                    }
                }

                Rectangle {
                    width: 70
                    height: 26
                    radius: MagiTheme.Theme.radiusSmall
                    color: cancelMouse.containsMouse
                        ? MagiTheme.Theme.elevated
                        : MagiTheme.Theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: MagiTheme.Theme.text
                        font.family: MagiTheme.Theme.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: cancelMouse

                        anchors.fill: parent
                        enabled: !root.connecting
                        hoverEnabled: true
                        cursorShape: enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor
                        onClicked: root.cancelled()
                    }
                }
            }
        }
    }
}
