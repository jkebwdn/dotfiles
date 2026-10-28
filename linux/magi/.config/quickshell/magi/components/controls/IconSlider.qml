import QtQuick
import "../../theme" as MagiTheme

// Render control: dark fill inside a selectively outlined track, icon overlaid.
// Kept separate from ValueSlider so the dedicated Volume menu is unchanged.
Item {
    id: root
    property string icon: ""
    property string moduleId: ""
    property real value: 0
    property bool interactive: true
    property color fillColor: MagiTheme.Theme.sliderFill
    property bool iconActionEnabled: false
    property string iconActionName: ""
    signal iconTriggered()
    signal valueMoved(real value)
    implicitHeight: MagiTheme.RenderTokens.sliderHeight
    opacity: interactive ? 1 : 0.45
    activeFocusOnTab: interactive
    Accessible.role: Accessible.Slider
    Accessible.name: moduleId
    Keys.onLeftPressed: if (interactive) valueMoved(Math.max(0, value - 0.05))
    Keys.onRightPressed: if (interactive) valueMoved(Math.min(1, value + 0.05))
    Keys.onPressed: event => {
        if (interactive && (event.key === Qt.Key_Home || event.key === Qt.Key_End)) {
            valueMoved(event.key === Qt.Key_Home ? 0 : 1); event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: MagiTheme.RenderTokens.sliderRadius
        color: MagiTheme.Theme.sliderTrack

        Item {
            anchors.fill: parent
            anchors.margins: MagiTheme.RenderTokens.sliderBorder
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: Math.min(width / 2, Math.max(0, MagiTheme.RenderTokens.sliderRadius
                    - MagiTheme.RenderTokens.sliderBorder))
                color: root.fillColor
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: root.activeFocus ? Math.max(1, MagiTheme.RenderTokens.sliderBorder) : MagiTheme.RenderTokens.sliderBorder
            border.color: root.activeFocus ? MagiTheme.Theme.focus : MagiTheme.Theme.sliderRim
        }
    }
    Icon {
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        role: root.icon
            moduleId: root.moduleId
        color: MagiTheme.Theme.legibleInk(MagiTheme.Theme.sliderTrack, MagiTheme.Theme.text)
        size: MagiTheme.RenderTokens.sliderIconSize
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        function applyPosition(mouseX) {
            root.valueMoved(Math.max(0, Math.min(1, mouseX / width)))
        }
        onPressed: mouse => applyPosition(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                applyPosition(mouse.x)
        }
    }
    Item {
        width: 40; height: parent.height
        visible: root.iconActionEnabled
        enabled: root.interactive
        activeFocusOnTab: visible && enabled
        Accessible.role: Accessible.Button
        Accessible.name: root.iconActionName
        Accessible.onPressAction: root.iconTriggered()
        Keys.onReturnPressed: root.iconTriggered()
        Keys.onSpacePressed: root.iconTriggered()
        Rectangle { anchors.fill: parent; radius: 8; color: "transparent"; border.width: parent.activeFocus ? 1 : 0; border.color: MagiTheme.Theme.focus }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.iconTriggered() }
    }
}
