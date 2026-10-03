import QtQuick
import "../../../components/controls" as Controls
import "../../../theme" as Theme

Item {
    id: root
    required property string moduleId
    property string icon: ""
    property string label: ""
    property bool toggle: false
    property bool active: false
    property bool available: true
    property bool danger: false
    signal triggered()
    implicitHeight: 38
    Accessible.name: label
    Accessible.role: Accessible.Button
    Controls.Icon {
        anchors.centerIn: parent
        role: root.icon
        moduleId: root.moduleId
        size: Theme.RenderTokens.tileIconSize
        color: Theme.Theme.controlInk(root.toggle, root.active, root.available, root.danger && root.active)
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
