import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
Item {
    id: root
    property string icon
    property string label: icon === "media-play" ? "Play" : icon === "media-pause" ? "Pause" : icon === "media-next" ? "Next track" : "Previous track"
    property string moduleId: "media"
    property bool available: true
    signal triggered()
    implicitWidth: 32
    implicitHeight: 32
    activeFocusOnTab: available
    Keys.onSpacePressed: if (available) triggered()
    Keys.onReturnPressed: if (available) triggered()
    Rectangle { anchors.fill: parent; radius: Theme.Theme.radiusSmall; color: root.available && hover.hovered ? Theme.Theme.overlay : "transparent"; border.width: root.activeFocus ? 1 : 0; border.color: Theme.Theme.focus }
    HoverHandler { id: hover }
    Accessible.name: label
    Accessible.description: available ? "" : "Unavailable"
    ToolTip.visible: hover.hovered
    ToolTip.delay: 500
    ToolTip.text: label
    Accessible.role: Accessible.Button
    Icon { anchors.centerIn: parent; role: root.icon; moduleId: root.moduleId; size: 26; color: root.available ? Theme.Theme.text : Theme.Theme.muted; opacity: 1 }
    TapHandler { enabled: root.available; onTapped: root.triggered() }
}
