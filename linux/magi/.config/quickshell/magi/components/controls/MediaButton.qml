import QtQuick
import "../../theme" as Theme
Item {
    id: root
    property string icon
    property string moduleId: "media"
    property bool available: true
    signal triggered()
    implicitWidth: 32
    implicitHeight: 28
    Accessible.name: icon
    Accessible.role: Accessible.Button
    Icon { anchors.centerIn: parent; role: root.icon; moduleId: root.moduleId; size: 26; color: root.available ? Theme.Theme.text : Theme.Theme.muted; opacity: root.available ? 1 : 0.4 }
    TapHandler { enabled: root.available; onTapped: root.triggered() }
}
