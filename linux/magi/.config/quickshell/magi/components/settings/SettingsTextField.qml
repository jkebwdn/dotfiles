import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
TextField {
    id: root
    leftPadding: 10; rightPadding: 10
    color: Theme.Theme.text
    selectionColor: Theme.Theme.accent
    selectedTextColor: Theme.Theme.accentText
    background: Rectangle {
        radius: Theme.Theme.radius("action", 8, width, height)
        color: root.hovered ? Theme.Theme.elevated : Theme.Theme.surface
    }
    implicitHeight: Math.max(SettingsMetrics.controlHeight, contentHeight + topPadding + bottomPadding)
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : SettingsMetrics.disabledOpacity
    SettingsFocus {}
}
