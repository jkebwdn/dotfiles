import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
import "SettingsScroll.js" as Scroll
Flickable {
    id: root
    objectName: "settingsPage-" + title
    default property alias pageData: body.data
    property alias body: body
    property bool initialized: false
    signal revisited()
    Component.onCompleted: initialized = true
    onVisibleChanged: if (visible && initialized) revisited()
    property real contentPadding: SettingsMetrics.pagePadding
    property real maximumBodyWidth: 760
    property string title: ""
    property real titleSize: SettingsMetrics.titleSize
    property string description: ""
    contentHeight: body.implicitHeight + root.contentPadding * 2
    contentWidth: width
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    function clampPosition() { contentY = Math.max(originY,Math.min(contentY,originY+Math.max(0,contentHeight-height))) }
    onContentHeightChanged: clampPosition()
    onHeightChanged: clampPosition()
    flickableDirection: Flickable.VerticalFlick
    ScrollInput { view: root }
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: body
        x: root.contentPadding
        y: root.contentPadding
        width: Math.max(0, Math.min(root.maximumBodyWidth, root.width - root.contentPadding * 2))
        spacing: SettingsMetrics.gap
        Label {
            visible: root.title.length > 0
            text: root.title
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: root.titleSize
            font.bold: true
            color: Theme.Theme.text
            Accessible.role: Accessible.Heading
        }
        SettingsHelp { text: root.description; visible: text.length > 0 }
    }
}
