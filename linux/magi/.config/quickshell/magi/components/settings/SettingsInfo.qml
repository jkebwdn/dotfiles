import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import "../controls" as Controls
import "../../theme" as Theme

// Contextual, view-local help: never imports or writes Settings.
ToolButton {
    id: root
    required property string helpText
    property string label: "Information"
    property alias helpPopup: tip
    property bool dismissed: false
    objectName: "settingsInfo-" + label
    implicitWidth: 26
    implicitHeight: 26
    padding: 5
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: label + " information"
    Accessible.description: helpText
    onHoveredChanged: if (hovered) dismissed = false
    onActiveFocusChanged: if (activeFocus) dismissed = false
    onClicked: { dismissed = false; forceActiveFocus(Qt.MouseFocusReason) }
    Keys.onEscapePressed: event => { dismissed = true; event.accepted = true }
    contentItem: Controls.Icon { role: "info"; size: 16; color: root.hovered || root.activeFocus ? Theme.Theme.text : Theme.Theme.subtext }
    background: Rectangle {
        color: root.hovered || root.down ? Theme.Theme.overlay : "transparent"
        radius: Theme.Theme.radius("surface", 6, width, height)
    }
    SettingsFocus { }
    ToolTip {
        id: tip
        parent: root
        popupType: Popup.Item
        x: root.width - width
        y: root.height + SettingsMetrics.compactGap
        visible: root.visible && !root.dismissed && (root.hovered || root.activeFocus)
        delay: root.activeFocus ? 0 : 300
        timeout: -1
        focus: false
        modal: false
        margins: 8
        padding: 10
        width: Math.min(320, Math.max(80, (root.Window.window ? root.Window.window.width : 336) - 16))
        text: root.helpText
        contentItem: Text {
            text: tip.text
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            font.pixelSize: SettingsMetrics.helperSize
            color: Theme.Theme.text
        }
        background: Rectangle {
            color: Theme.Theme.overlay
            radius: Theme.Theme.radius("surface", 8, width, height)
            border.width: 1
            border.color: Theme.Theme.border
        }
    }
}
