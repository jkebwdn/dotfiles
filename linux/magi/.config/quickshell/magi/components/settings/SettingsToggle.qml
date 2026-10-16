import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
CheckBox {
    id: root
    objectName: "settingsToggle-" + text
    Layout.fillWidth: text.length > 0
    implicitWidth: Math.max(34, contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(SettingsMetrics.controlHeight, contentItem.implicitHeight + 12)
    leftPadding: 0; rightPadding: text.length > 0 ? 48 : 0
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : SettingsMetrics.disabledOpacity
    indicator: Rectangle {
        x: root.width - width
        y: (root.height - height) / 2
        implicitWidth: 32; implicitHeight: 18
        radius: Theme.Theme.radius("action", 9, width, height)
        color: root.checked ? Theme.Theme.accent : root.hovered ? Theme.Theme.overlay : Theme.Theme.elevated
        border.width: root.checked ? 0 : 1
        border.color: Theme.Theme.border
        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            y: 3; width: 12; height: 12
            radius: Theme.Theme.radius("action", 6, width, height)
            color: root.checked ? Theme.Theme.accentText : Theme.Theme.text
        }
        opacity: root.down ? 0.8 : 1
    }
    contentItem: Text {
        text: root.text
        font: root.font
        color: Theme.Theme.text
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }
    SettingsFocus {}
}
