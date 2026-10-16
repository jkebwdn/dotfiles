import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
SettingsButton {
    id: root
    property string label: ""
    property bool cancellingDrag: false
    property bool hasLanes: false
    readonly property string instructions: "Drag to arrange. Alt+Up/Down moves one place; Alt+Home/End moves to the ends."
        + (hasLanes ? " Alt+Left/Right moves between regions, including Available." : "")
        + " Escape cancels a drag."
    signal dragPressed(real px, real py)
    signal dragMoved(real px, real py)
    signal dragReleased(real px, real py)
    signal dragCancelled()
    signal moveRequested(int delta)
    signal edgeRequested(bool last)
    signal laneRequested(int delta)
    text: "≡"
    flat: true
    implicitWidth: 28; implicitHeight: 28
    leftPadding: 4; rightPadding: 4
    Accessible.name: "Arrange " + label
    Accessible.description: instructions
    ToolTip.visible: false
    ToolTip {
        parent: root
        y: root.height + 6
        width: 300
        margins: 12
        delay: 500
        timeout: 5000
        visible: root.visible && !pointer.pressed && (pointer.containsMouse
            || (root.activeFocus && root.focusReason !== Qt.MouseFocusReason))
        contentItem: Text {
            text: root.instructions
            color: Theme.Theme.text
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        background: Rectangle {
            color: Theme.Theme.surface
            radius: Theme.Theme.radius("action", 8, width, height)
            border.width: 1; border.color: Theme.Theme.border
        }
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && cancellingDrag) { dragCancelled(); event.accepted = true; return }
        if (!(event.modifiers & Qt.AltModifier)) return
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down)
            moveRequested(event.key === Qt.Key_Up ? -1 : 1)
        else if (event.key === Qt.Key_Home || event.key === Qt.Key_End)
            edgeRequested(event.key === Qt.Key_End)
        else if (hasLanes && (event.key === Qt.Key_Left || event.key === Qt.Key_Right))
            laneRequested(event.key === Qt.Key_Left ? -1 : 1)
        else return
        event.accepted = true
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        preventStealing: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onPressed: mouse => { root.forceActiveFocus(Qt.MouseFocusReason); root.dragPressed(mouse.x, mouse.y) }
        onPositionChanged: mouse => { if (pressed) root.dragMoved(mouse.x, mouse.y) }
        onReleased: mouse => root.dragReleased(mouse.x, mouse.y)
        onCanceled: root.dragCancelled()
    }
}
