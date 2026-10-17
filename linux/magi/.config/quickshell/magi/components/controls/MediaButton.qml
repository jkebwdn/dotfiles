import QtQuick
import "../../theme" as Theme
Item {
    id: root
    property string icon
    property string moduleId: "media"
    property bool available: true
    signal triggered()
    implicitWidth: 32
    implicitHeight: 32
    activeFocusOnTab: available
    Keys.onSpacePressed: if (available) triggered()
    Keys.onReturnPressed: if (available) triggered()
    Rectangle { anchors.fill: parent; radius: Theme.Theme.radiusSmall; color: hover.hovered ? Theme.Theme.overlay : "transparent"; border.width: root.activeFocus ? 1 : 0; border.color: Theme.Theme.focus }
    HoverHandler { id: hover }
    Accessible.name: icon
    Accessible.role: Accessible.Button
    Icon { anchors.centerIn: parent; role: root.icon; moduleId: root.moduleId; size: 26; color: root.available ? Theme.Theme.text : Theme.Theme.muted; opacity: root.available ? 1 : 0.4 }
    TapHandler { enabled: root.available; onTapped: root.triggered() }
}
