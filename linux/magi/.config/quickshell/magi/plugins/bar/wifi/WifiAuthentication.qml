pragma ComponentBehavior: Bound
import QtQuick
import "../../../components/controls" as Controls
import "../../../theme" as Theme
Column {
    id: root
    required property var controller
    required property var network
    readonly property bool active: controller.selectedNetwork === network
    spacing: 8
    function requestInputFocus() {
        Qt.callLater(function() { if (root.active && root.visible && root.enabled) input.forceActiveFocus() })
    }
    function submit() { if (input.text.length > 0 && !controller.connecting) controller.submitPassword(input.text) }
    onActiveChanged: { input.text = ""; if (active) requestInputFocus() }
    onVisibleChanged: { if (visible) requestInputFocus() }
    Component.onCompleted: requestInputFocus()
    Connections { target: root.controller; function onClearPassword() { input.text = "" } }
    Rectangle {
        width: parent.width; height: 32
        radius: Theme.Theme.radiusSmall
        color: Theme.Theme.surface
        border.color: input.activeFocus ? Theme.Theme.accent : Theme.Theme.border
        border.width: 1
        TextInput {
            id: input
            objectName: "wifiPasswordInput"
            anchors.fill: parent; anchors.margins: 6
            enabled: !root.controller.connecting
            color: Theme.Theme.text
            font.family: Theme.Theme.fontFamily; font.pixelSize: 12
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            selectByMouse: true
            activeFocusOnTab: true
            verticalAlignment: TextInput.AlignVCenter
            onAccepted: root.submit()
            Keys.onEscapePressed: event => { root.controller.cancelPassword(); event.accepted = true }
        }
    }
    Row {
        spacing: 8
        Controls.ActionChip {
            label: root.controller.connecting ? "Connecting…" : "Connect"
            available: input.text.length > 0 && !root.controller.connecting
            onTriggered: root.submit()
        }
        Controls.ActionChip { label: "Cancel"; available: !root.controller.connecting; onTriggered: root.controller.cancelPassword() }
    }
    Text {
        width: parent.width
        text: root.controller.errorNetwork === root.network ? root.controller.connectionError : ""
        visible: text.length > 0
        color: Theme.Theme.danger
        font.pixelSize: 10
        wrapMode: Text.WordWrap
    }
}
