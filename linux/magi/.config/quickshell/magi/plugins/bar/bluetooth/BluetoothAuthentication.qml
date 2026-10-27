pragma ComponentBehavior: Bound
import QtQuick
import "../../../services" as MagiServices
import "../../../theme" as MagiTheme
import "../../../components/controls" as MagiControls

Column {
    id: root
    readonly property var request: MagiServices.Bluetooth.prompt
    readonly property string kind: request ? request.kind : ""
    readonly property bool entry: kind === "pin" || kind === "passkey"
    readonly property bool displayOnly: kind === "displayPin" || kind === "displayPasskey"
    readonly property bool valid: kind === "pin" ? input.text.length > 0 && input.text.length <= 16
        : kind === "passkey" ? /^[0-9]{1,6}$/.test(input.text) : true
    spacing: 10
    onRequestChanged: {
        input.text = ""
        if (request) Qt.callLater(function() { if (root.entry) input.forceActiveFocus(); else cancel.forceActiveFocus() })
    }
    Text {
        width: parent.width
        text: MagiServices.Bluetooth.actionName
        textFormat: Text.PlainText
        color: MagiTheme.Theme.text
        font.pixelSize: 13
        elide: Text.ElideRight
    }
    Text {
        width: parent.width
        text: root.kind === "pin" ? "Enter the device PIN"
            : root.kind === "passkey" ? "Enter the device passkey"
            : root.kind === "confirm" ? "Do the codes match on both devices?"
            : root.displayOnly ? "Type this code on the device"
            : root.kind === "service" ? "Allow this device’s service?"
            : "Allow pairing with this device?"
        textFormat: Text.PlainText
        color: MagiTheme.Theme.text
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
    Text {
        width: parent.width
        visible: text.length > 0
        text: root.request ? root.request.value : ""
        textFormat: Text.PlainText
        color: MagiTheme.Theme.text
        font.pixelSize: root.kind === "service" ? 11 : 18
        wrapMode: Text.WrapAnywhere
        Accessible.name: text
    }
    Rectangle {
        width: parent.width
        height: visible ? 34 : 0
        visible: root.entry
        radius: MagiTheme.Theme.radiusSmall
        color: MagiTheme.Theme.background
        border.width: input.activeFocus ? 1 : 0
        border.color: MagiTheme.Theme.focus
        TextInput {
            id: input
            objectName: "bluetooth-auth-input"
            anchors.fill: parent
            anchors.margins: 7
            color: MagiTheme.Theme.text
            font.pixelSize: 14
            maximumLength: root.kind === "pin" ? 16 : 6
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            Accessible.name: root.kind === "pin" ? "Device PIN" : "Device passkey"
            onAccepted: if (root.valid) MagiServices.Bluetooth.answer(true, text)
        }
    }
    Row {
        spacing: 8
        MagiControls.ActionChip {
            activeFocusOnTab: true
            id: cancel
            objectName: "bluetooth-auth-cancel"
            label: "Cancel"
            onTriggered: MagiServices.Bluetooth.answer(false, "")
        }
        MagiControls.ActionChip {
            activeFocusOnTab: true
            objectName: "bluetooth-auth-confirm"
            label: root.entry ? "Pair" : "Confirm"
            visible: !root.displayOnly
            available: root.valid
            onTriggered: MagiServices.Bluetooth.answer(true, input.text)
        }
    }
    Keys.onEscapePressed: MagiServices.Bluetooth.cancel()
}
