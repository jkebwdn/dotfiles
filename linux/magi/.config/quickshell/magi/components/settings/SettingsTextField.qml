import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
TextField {
    id: root
    leftPadding: SettingsMetrics.fieldPadding; rightPadding: SettingsMetrics.fieldPadding
    topPadding: 6; bottomPadding: 6
    verticalAlignment: TextInput.AlignVCenter
    placeholderTextColor: Theme.Theme.muted
    color: Theme.Theme.text
    selectionColor: Theme.Theme.accent
    selectedTextColor: Theme.Theme.accentText
    background: Rectangle {
        radius: Theme.Theme.radius("action", 8, width, height)
        color: root.hovered ? Theme.Theme.overlay : Theme.Theme.elevated
        border.width: root.activeFocus ? SettingsMetrics.focusWidth : 0
        border.color: Theme.Theme.focus
    }
    implicitHeight: Math.max(SettingsMetrics.controlHeight, contentHeight + topPadding + bottomPadding)
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : SettingsMetrics.disabledOpacity
    SettingsFocus {}
}
