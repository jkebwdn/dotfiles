import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
Flickable {
    id: root
    objectName: "settingsPage-" + title
    default property alias pageData: body.data
    property alias body: body
    property bool initialized: false
    signal revisited()
    Component.onCompleted: initialized = true
    onVisibleChanged: if (visible && initialized) revisited()
    property string title: ""
    property string description: ""
    contentHeight: body.implicitHeight + SettingsMetrics.pagePadding * 2
    contentWidth: width
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: body
        x: Math.max(SettingsMetrics.pagePadding, (root.width - width) / 2)
        y: SettingsMetrics.pagePadding
        width: Math.max(0, Math.min(760, root.width - SettingsMetrics.pagePadding * 2))
        spacing: SettingsMetrics.gap
        Label {
            text: root.title
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: SettingsMetrics.titleSize
            font.bold: true
            color: Theme.Theme.text
            Accessible.role: Accessible.Heading
        }
        SettingsHelp { text: root.description; visible: text.length > 0 }
    }
}
