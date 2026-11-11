import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme

// Level-three heading: the title/help stay visible; disclosure owns only options.
ColumnLayout {
    id: root
    default property alias options: content.data
    property string title: ""
    property string description: ""
    property bool collapsible: false
    property bool expanded: !collapsible
    property alias disclosureButton: disclosure
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: SettingsMetrics.compactGap
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: SettingsMetrics.compactGap
        Label {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: SettingsMetrics.subheadingSize
            font.weight: Font.DemiBold
            color: Theme.Theme.text
            wrapMode: Text.Wrap
            Accessible.role: Accessible.Heading
            MouseArea { anchors.fill: parent; enabled: root.collapsible; onClicked: root.expanded = !root.expanded }
        }
        ToolButton {
            id: disclosure
            visible: root.collapsible
            implicitWidth: 32; implicitHeight: 30
            text: root.expanded ? "▾" : "▸"
            focusPolicy: Qt.StrongFocus
            Accessible.name: root.title + " options"
            Accessible.description: root.expanded ? "Expanded" : "Collapsed"
            Accessible.checkable: true
            Accessible.checked: root.expanded
            onClicked: root.expanded = !root.expanded
            contentItem: Text { text: disclosure.text; color: Theme.Theme.text; font.pixelSize: SettingsMetrics.sectionSize; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { color: "transparent"; radius: Theme.Theme.radius("surface", 4, width, height); border.width: disclosure.activeFocus ? 1 : 0; border.color: Theme.Theme.focus }
        }
    }
    SettingsHelp { text: root.description; visible: text.length > 0 }
    ColumnLayout { id: content; Layout.fillWidth: true; visible: root.expanded; spacing: SettingsMetrics.gap }
}
