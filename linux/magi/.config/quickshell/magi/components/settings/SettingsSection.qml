import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
ColumnLayout {
    id: root
    default property alias sectionData: content.data
    property string title: ""
    property string description: ""
    property bool collapsible: false
    property bool expanded: !collapsible
    Layout.fillWidth: true
    spacing: SettingsMetrics.compactGap
    Layout.topMargin: title.length > 0 ? SettingsMetrics.sectionGap : 0
    Label {
        visible: !root.collapsible && root.title.length > 0
        text: root.title
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        font.pixelSize: SettingsMetrics.sectionSize
        font.bold: true
        color: Theme.Theme.text
        Accessible.role: Accessible.Heading
    }
    SettingsButton {
        id: disclosure
        flat: true
        leftPadding: 0
        rightPadding: 0
        contentItem: Text {
            text: disclosure.text
            font.pixelSize: SettingsMetrics.sectionSize
            font.bold: true
            color: Theme.Theme.text
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        background: Rectangle {
            radius: Theme.Theme.radius("action", 8, width, height)
            color: disclosure.hovered || disclosure.down ? Theme.Theme.surface : "transparent"
        }
        visible: root.collapsible
        Layout.fillWidth: true
        text: root.title + (root.expanded ? "  ▾" : "  ▸")
        checked: root.expanded
        onClicked: root.expanded = !root.expanded
    }
    SettingsHelp { text: root.description; visible: text.length > 0 && root.expanded }
    ColumnLayout {
        id: content
        visible: root.expanded
        opacity: root.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: SettingsMetrics.transitionDuration } }
        Layout.fillWidth: true
        spacing: 10
    }
}
