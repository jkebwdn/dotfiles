import QtQuick
import "../../../components/controls" as Controls
import "../../../theme" as Theme

Rectangle {
    id: root
    required property string moduleId
    property string icon: ""
    property string label: ""
    property bool active: false
    property bool available: true
    property bool danger: false
    signal triggered()
    implicitHeight: 38
    radius: Theme.Theme.radius("action", 10, width, height)
    color: root.active ? (root.danger ? Theme.Theme.danger : Theme.Theme.accent)
        : pointer.containsMouse ? Theme.Theme.elevated : Theme.Theme.background
    opacity: available ? 1 : 0.45
    Accessible.name: label
    Accessible.role: Accessible.Button
    Controls.Icon {
        anchors.centerIn: parent
        role: root.icon
        moduleId: root.moduleId
        size: 17
        color: root.active ? Theme.Theme.accentText : Theme.Theme.text
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.available
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.triggered()
    }
}
