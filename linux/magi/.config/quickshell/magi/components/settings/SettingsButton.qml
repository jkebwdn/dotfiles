import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
Button {
    id: root
    objectName: "settingsButton-" + text
    property bool primary: false
    implicitHeight: Math.max(SettingsMetrics.controlHeight, contentItem.implicitHeight + 12)
    leftPadding: 12; rightPadding: 12
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : SettingsMetrics.disabledOpacity
    contentItem: Text {
        text: root.text
        font: root.font
        color: root.down || root.checked || root.primary ? Theme.Theme.accentText : Theme.Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }
    background: Rectangle {
        radius: Theme.Theme.radius("action", 8, width, height)
        color: root.down || root.checked || root.primary ? Theme.Theme.accent
            : root.hovered ? Theme.Theme.elevated : root.flat ? "transparent" : Theme.Theme.surface
    }
    ToolTip.visible: hovered && Accessible.name.length > 0 && Accessible.name !== text
    ToolTip.text: Accessible.name
    SettingsFocus {}
}
