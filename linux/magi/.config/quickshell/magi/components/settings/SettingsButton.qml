import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
Button {
    id: root
    background: Rectangle {
        radius: Theme.Theme.radius("action", 8, width, height)
        color: root.down ? Theme.Theme.accent : root.hovered ? Theme.Theme.overlay : Theme.Theme.elevated
        opacity: root.enabled ? 1 : .45
    }
}
