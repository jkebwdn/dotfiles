import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
SpinBox {
    id: root
    implicitWidth: 118
    implicitHeight: SettingsMetrics.controlHeight
    leftPadding: 32; rightPadding: 32
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : SettingsMetrics.disabledOpacity
    contentItem: TextInput {
        text: root.displayText
        font: root.font
        color: Theme.Theme.text
        selectionColor: Theme.Theme.accent
        selectedTextColor: Theme.Theme.accentText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: root.inputMethodHints
    }
    down.indicator: Rectangle {
        x: root.mirrored ? root.width - width - 3 : 3
        y: 3; implicitWidth: 28; height: root.height - 6
        radius: Theme.Theme.radius("action", 5, width, height)
        color: root.down.pressed ? Theme.Theme.accent : root.down.hovered ? Theme.Theme.elevated : "transparent"
        Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 16; color: root.down.pressed ? Theme.Theme.accentText : Theme.Theme.text; opacity: root.down.enabled ? 1 : 0.5 }
    }
    up.indicator: Rectangle {
        x: root.mirrored ? 3 : root.width - width - 3
        y: 3; implicitWidth: 28; height: root.height - 6
        radius: Theme.Theme.radius("action", 5, width, height)
        color: root.up.pressed ? Theme.Theme.accent : root.up.hovered ? Theme.Theme.elevated : "transparent"
        Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 16; color: root.up.pressed ? Theme.Theme.accentText : Theme.Theme.text; opacity: root.up.enabled ? 1 : 0.5 }
    }
    background: Rectangle {
        radius: Theme.Theme.radius("action", 8, width, height)
        color: root.hovered ? Theme.Theme.overlay : Theme.Theme.elevated
        border.width: 1; border.color: root.activeFocus ? Theme.Theme.focus : Theme.Theme.border
    }
    SettingsFocus {}
}
