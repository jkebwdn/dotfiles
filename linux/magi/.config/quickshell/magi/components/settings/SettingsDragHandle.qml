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
    text: ""
    signal contextRequested()
    signal selectionRequested()
    onClicked: selectionRequested()
    background: Rectangle {
        color: "transparent"
        radius: Theme.Theme.radius("action", 8, width, height)
        border.width: pointer.containsMouse || root.activeFocus ? 1 : 0
        border.color: Theme.Theme.focus
    }
    flat: true
    implicitWidth: 28; implicitHeight: 28
    leftPadding: 4; rightPadding: 4
    Accessible.name: "Arrange " + label
    Accessible.description: instructions
    ToolTip.visible: false
    // A passive overlay rather than a Popup: overlapping hints must not grab
    // the next pointer press, including after keyboard moves into Available.
    function hint() { hintDelay.restart() }
    onVisibleChanged: if (!visible) { hintDelay.stop(); hintBox.visible = false }
    onActiveFocusChanged: { hintBox.visible = false; if (activeFocus && focusReason !== Qt.MouseFocusReason) hint() }
    Timer {
        id: hintDelay; interval: 500
        onTriggered: {
            if (!root.visible || pointer.pressed || !(pointer.containsMouse || root.activeFocus)) return
            const point = root.mapToItem(hintBox.parent, 0, root.height + 6)
            hintBox.x = Math.max(8, Math.min(hintBox.parent.width - hintBox.width - 8, point.x))
            hintBox.y = Math.max(8, Math.min(hintBox.parent.height - hintBox.height - 8, point.y))
            hintBox.visible = true
            hintTimeout.restart()
        }
    }
    Timer { id: hintTimeout; interval: 5000; onTriggered: hintBox.visible = false }
    Rectangle {
        id: hintBox
        parent: root.Overlay.overlay
        visible: false
        z: 100
        width: 300; height: hintText.implicitHeight + 24
        color: Theme.Theme.surface
        radius: Theme.Theme.radius("action", 8, width, height)
        border.width: 1; border.color: Theme.Theme.border
        Text {
            id: hintText
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            text: root.instructions
            color: Theme.Theme.text
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers & Qt.ShiftModifier)) { contextRequested(); event.accepted = true; return }
        if (event.key === Qt.Key_Escape && cancellingDrag) { dragCancelled(); event.accepted = true; return }
        if (!(event.modifiers & Qt.AltModifier)) return
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down)
            moveRequested(event.key === Qt.Key_Up ? -1 : 1)
        else if (event.key === Qt.Key_Home || event.key === Qt.Key_End)
            edgeRequested(event.key === Qt.Key_End)
        else if (hasLanes && (event.key === Qt.Key_Left || event.key === Qt.Key_Right))
            laneRequested(event.key === Qt.Key_Left ? -1 : 1)
        else return
        hintBox.visible = false; hint()
        event.accepted = true
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onEntered: root.hint()
        onExited: { hintDelay.stop(); hintBox.visible = false }
        onPressed: mouse => { hintDelay.stop(); hintBox.visible = false; root.forceActiveFocus(Qt.MouseFocusReason); if (mouse.button === Qt.RightButton) root.contextRequested(); else root.dragPressed(mouse.x, mouse.y) }
        onPositionChanged: mouse => { if (pressed) root.dragMoved(mouse.x, mouse.y) }
        onReleased: mouse => { if (mouse.button === Qt.LeftButton) root.dragReleased(mouse.x, mouse.y) }
        onCanceled: root.dragCancelled()
    }
}
