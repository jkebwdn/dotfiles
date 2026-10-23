import QtQuick
import QtQuick.Controls.Basic
import "../../../components/controls" as Controls
import "../../../theme" as Theme

Item {
    id: root
    required property string moduleId
    property string icon: ""
    property string label: ""
    property bool interactive: true
    property string accentRole: ""
    signal secondaryTriggered()
    property bool toggle: false
    property bool active: false
    property bool available: true
    property bool danger: false
    signal triggered()
    implicitHeight: Theme.RenderTokens.actionSize
    activeFocusOnTab: available && interactive
    Keys.onSpacePressed: if (available && interactive) triggered()
    Keys.onReturnPressed: if (available && interactive) triggered()
    Rectangle {
        anchors.fill: parent
        radius: Theme.Theme.radius("secondaryControl", 10, width, height)
        color: pointer.containsMouse || root.activeFocus ? Theme.Theme.elevated
            : root.accentRole ? Qt.alpha(Theme.Theme.primaryAccent(root.accentRole,"accent"), Theme.Theme.visual.secondaryBackgroundOpacity) : "transparent"
        border.width: root.activeFocus ? Math.max(1,Theme.Theme.visual.secondaryBorderWidth) : Theme.Theme.visual.secondaryBorderWidth
        border.color: root.activeFocus ? Theme.Theme.focus : Theme.Theme.roles[Theme.Theme.visual.secondaryBorder]
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
        radius: Theme.Theme.radius("secondaryControl", 1, width, height)
        visible: root.toggle && root.active
        color: root.accentRole ? Theme.Theme.primaryAccent(root.accentRole, "accent") : Theme.Theme.accent
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.available && root.interactive
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.secondaryTriggered() : root.triggered()
    }
}
