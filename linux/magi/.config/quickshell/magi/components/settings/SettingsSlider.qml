import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
Slider {
    id: root
    wheelEnabled: false
    background: Rectangle {
        x: root.leftPadding; y: (root.height - height) / 2
        width: root.availableWidth; height: 4; radius: 2
        color: Theme.Theme.elevated
        Rectangle { width: root.position * parent.width; height: parent.height; radius: 2; color: Theme.Theme.accent }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: (root.height - height) / 2
        implicitWidth: 14; implicitHeight: 14; radius: 7
        color: root.pressed ? Theme.Theme.text : Theme.Theme.accent
    }
    implicitHeight: Math.max(SettingsMetrics.controlHeight, implicitContentHeight + topPadding + bottomPadding)
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : SettingsMetrics.disabledOpacity
    SettingsFocus {}
}
