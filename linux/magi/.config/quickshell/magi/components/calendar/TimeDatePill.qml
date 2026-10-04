import QtQuick
import "../../services" as Services
import "../../theme" as Theme
Rectangle {
    id: root
    property bool datePart: false
    property bool absorbed: false
    property real expansion: 0
    readonly property string displayText: datePart ? Services.ClockState.dateText : Services.ClockState.timeText
    signal triggered()
    implicitWidth: label.implicitWidth + 14
    implicitHeight: Theme.Theme.barPillHeight
    radius: Theme.Theme.barPillRadius
    color: Qt.alpha(Theme.Theme.surface, 1 - expansion)
    // Keep the slot (and toggle hit target), not a second visible clock.
    opacity: absorbed ? 0 : 1
    Accessible.ignored: absorbed
    Accessible.role: Accessible.Button
    Accessible.name: displayText
    Accessible.description: "Toggle date surface"
    Accessible.onPressAction: triggered()
    Text {
        id: label
        anchors.centerIn: parent
        text: root.displayText
        color: Theme.Theme.text
        font.family: Theme.Theme.fontFamily; font.pixelSize: 12; font.bold: true
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.triggered() }
}
