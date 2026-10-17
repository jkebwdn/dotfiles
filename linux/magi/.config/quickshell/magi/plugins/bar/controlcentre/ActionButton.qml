import QtQuick
import QtQuick.Controls.Basic
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
    implicitHeight: Theme.RenderTokens.actionSize
    activeFocusOnTab: available
    Keys.onSpacePressed: if (available) triggered()
    Keys.onReturnPressed: if (available) triggered()
    Rectangle {
        anchors.fill: parent
        radius: Theme.Theme.radius("action", 10, width, height)
        color: pointer.containsMouse || root.activeFocus ? Theme.Theme.elevated : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.Theme.focus
    }
    Accessible.name: label
    Accessible.role: Accessible.Button
    ToolTip.visible: pointer.containsMouse
    ToolTip.text: label
    Controls.Icon {
        anchors.centerIn: parent
        role: root.icon
        moduleId: root.moduleId
        size: Theme.RenderTokens.actionIconSize
        color: Theme.Theme.legibleInk(Theme.Theme.surface, Theme.Theme.stateInk("secondary", root.toggle, root.active, root.available, root.danger && root.active))
        opacity: root.available ? 1 : 0.45
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 12; height: 2
        radius: Theme.Theme.radius("action", 1, width, height)
        visible: root.toggle && root.active
        color: Theme.Theme.accent
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
