import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
Switch {
    id: root
    implicitWidth: 40
    implicitHeight: 30
    padding: 4
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.45
    indicator: Rectangle {
        x: 4; y: (root.height - height) / 2
        width: 32; height: 18
        radius: Theme.Theme.radius("action", 9, width, height)
        color: root.checked ? Theme.Theme.accent : Theme.Theme.elevated
        border.width: root.visualFocus || !root.checked ? 1 : 0
        border.color: root.visualFocus ? Theme.Theme.focus : Theme.Theme.border
        Rectangle {
            x: root.checked ? 17 : 3; y: 3; width: 12; height: 12
            radius: Theme.Theme.radius("action", 6, width, height)
            color: root.checked ? Theme.Theme.accentText : Theme.Theme.text
            Behavior on x { NumberAnimation { duration: 120 } }
        }
    }
    contentItem: Item {}
}
