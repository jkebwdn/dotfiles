import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme

Button {
    id: root
    objectName: "settingsButton-" + text
    property bool primary: false
    property bool destructive: false
    // Quiet utility actions share the same geometry and focus handling as buttons.
    property string actionKind: ""
    readonly property bool utility: actionKind === "reset" || actionKind === "navigation"
    Layout.minimumWidth: 0
    implicitHeight: Math.max(SettingsMetrics.controlHeight, contentItem.implicitHeight + 12)
    leftPadding: SettingsMetrics.fieldPadding
    rightPadding: SettingsMetrics.fieldPadding
    topPadding: 6
    bottomPadding: 6
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : SettingsMetrics.disabledOpacity
    contentItem: Text {
        text: root.text
        font: root.font
        color: root.utility ? (root.destructive ? Theme.Theme.red : root.actionKind === "navigation" ? Theme.Theme.accent : Theme.Theme.text) : root.down || root.checked || root.primary ? Theme.Theme.accentText : root.destructive ? Theme.Theme.red : Theme.Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }
    background: Rectangle {
        radius: Theme.Theme.radius("action", 8, width, height)
        border.width: root.utility ? 1 : 0
        border.color: Theme.Theme.border
        color: root.utility ? (root.down ? Theme.Theme.overlay : root.hovered ? Theme.Theme.elevated : Theme.Theme.surface) : root.down || root.checked || root.primary ? Theme.Theme.accent : root.hovered ? Theme.Theme.overlay : root.flat ? "transparent" : Theme.Theme.elevated
    }
    ToolTip.visible: hovered && Accessible.name.length > 0 && Accessible.name !== text
    ToolTip.text: Accessible.name
    SettingsFocus {}
}
