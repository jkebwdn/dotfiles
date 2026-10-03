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
    signal valueMoved(real value)
    implicitHeight: MagiTheme.RenderTokens.sliderHeight
    opacity: interactive ? 1 : 0.45

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
            border.width: MagiTheme.RenderTokens.sliderBorder
            border.color: MagiTheme.Theme.sliderRim
        }
    }
    Icon {
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        role: root.icon
            moduleId: root.moduleId
        color: MagiTheme.Theme.text
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
}
