import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme

AbstractButton {
    id: root
    default property alias sampleData: sample.data
    property bool selected: false
    signal navigate(int delta)
    property alias sample: sample
    implicitWidth: 176
    implicitHeight: 126
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    Accessible.name: text
    Accessible.role: Accessible.RadioButton
    Accessible.checked: selected
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onLeftPressed: navigate(-1)
    Keys.onRightPressed: navigate(1)
    background: Rectangle {
        radius: Theme.Theme.radius("action", 12, width, height)
        color: root.down ? Theme.Theme.overlay : root.hovered ? Theme.Theme.elevated : Theme.Theme.surface
        border.width: root.selected || root.visualFocus ? 2 : 1
        border.color: root.visualFocus ? Theme.Theme.focus : root.selected ? Theme.Theme.accent : Theme.Theme.border
        Behavior on color {
            ColorAnimation {
                duration: SettingsMetrics.transitionDuration
            }
        }
    }
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        Item {
            id: sample
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        Text {
            text: root.text
            Layout.fillWidth: true
            color: Theme.Theme.text
            font.pixelSize: 12
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
