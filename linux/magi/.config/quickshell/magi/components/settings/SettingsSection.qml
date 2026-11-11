import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
Item {
    id: root
    default property alias sectionData: content.data
    property string title: ""
    property string description: ""
    property string infoText: ""
    property alias disclosureButton: disclosure
    property bool collapsible: false
    property bool expanded: !collapsible
    Layout.fillWidth: true
    property bool carded: true
    readonly property bool settingsSection: true
    readonly property real padding: carded ? SettingsMetrics.fieldPadding : 0
    Layout.minimumWidth: 0
    property Item cardBackground: Rectangle {
        parent: root
        z: -1
        anchors.fill: parent
        objectName: "settingsSectionBackground"
        visible: root.carded
        color: Theme.Theme.elevated
        radius: Theme.Theme.radius("surface", 12, width, height)
        border.width: 1
        border.color: Qt.alpha(Theme.Theme.border, .45)
    }
    implicitHeight: sectionLayout.implicitHeight
    ColumnLayout {
        id: sectionLayout
        width: root.width
        spacing: SettingsMetrics.compactGap
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.padding; Layout.rightMargin: root.padding
            Layout.topMargin: root.padding
            Layout.bottomMargin: root.expanded ? 0 : root.padding
            visible: root.collapsible || root.title.length > 0
            spacing: SettingsMetrics.compactGap
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
                    radius: Theme.Theme.radius("surface", 8, width, height)
                    color: disclosure.hovered || disclosure.down ? Theme.Theme.surface : "transparent"
                }
                visible: root.collapsible
                Layout.fillWidth: true
                text: root.title + (root.expanded ? "  ▾" : "  ▸")
                checked: root.expanded
                onClicked: root.expanded = !root.expanded
            }
            SettingsInfo { visible: root.infoText.length > 0; label: root.title; helpText: root.infoText }
        }
        SettingsHelp {
            Layout.leftMargin: root.padding; Layout.rightMargin: root.padding
            text: root.description; visible: text.length > 0 && root.expanded
        }
        ColumnLayout {
            id: content
            Layout.leftMargin: root.padding; Layout.rightMargin: root.padding
            Layout.topMargin: !root.title && !root.description ? root.padding : 0
            Layout.bottomMargin: root.padding
            visible: root.expanded
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: SettingsMetrics.transitionDuration } }
            Layout.fillWidth: true
            spacing: 10
        }
    }
}
