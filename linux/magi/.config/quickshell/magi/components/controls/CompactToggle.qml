import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
import "../../services" as Services
Switch {
    id: root
    property color activeColor: Theme.Theme.accent
    property bool indicatorOnRight: false
    property string toggleStyle: Services.Settings.data.appearance.toggleStyle
    implicitWidth: 40
    implicitHeight: 30
    padding: 4
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    opacity: enabled ? 1 : 0.45
    indicator: Item {
        objectName: "toggleIndicator"
        x: root.indicatorOnRight ? root.width - width : 4
        y: (root.height - height) / 2
        implicitWidth: 32; implicitHeight: 18
        Rectangle {
            objectName: "toggleTrack"
            anchors.centerIn: parent
            width: parent.width
            height: root.toggleStyle === "minimal" ? 6 : parent.height
            radius: Theme.Theme.radius("action", height / 2, width, height)
            color: root.checked ? root.activeColor
                : root.hovered ? Theme.Theme.overlay : Theme.Theme.elevated
            border.width: root.checked ? 0 : 1
            border.color: Theme.Theme.border
        }
        Rectangle {
            objectName: "toggleKnob"
            width: root.toggleStyle === "filled" ? 8 : 12; height: width
            x: root.checked ? parent.width - width - 3 : 3
            y: (parent.height - height) / 2
            radius: Theme.Theme.radius("action", width / 2, width, height)
            color: root.checked ? (root.toggleStyle === "minimal" ? root.activeColor : Theme.Theme.legibleInk(root.activeColor, Theme.Theme.accentText)) : Theme.Theme.text
            Behavior on x { NumberAnimation { duration: Theme.Motion.control } }
        }
        Rectangle {
            objectName: "toggleFocus"
            anchors.fill: parent; anchors.margins: -3
            radius: Theme.Theme.radius("action", 11, width, height)
            color: "transparent"; border.width: root.visualFocus ? 1 : 0; border.color: Theme.Theme.focus
        }
        opacity: root.down ? 0.8 : 1
    }
    contentItem: Item {}
}
