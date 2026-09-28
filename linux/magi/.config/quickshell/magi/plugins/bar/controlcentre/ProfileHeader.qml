import QtQuick
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme

Rectangle {
    id: root
    implicitHeight: 58
    radius: Theme.Theme.radius("controlTile", 10, width, height)
    color: Theme.Theme.elevated
    readonly property var profile: Services.Settings.data.profile
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10
        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            radius: 21
            clip: true
            color: Theme.Theme.overlay
            Image {
                anchors.fill: parent
                source: Services.AssetManager.assetUrl(root.profile.avatar)
                fillMode: Image.PreserveAspectCrop
                visible: source !== ""
                sourceSize: Qt.size(84, 84)
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: root.profile.displayName
                color: Theme.Theme.text
                font.family: Theme.Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                visible: text.length > 0
            }
            Text {
                Layout.fillWidth: true
                text: root.profile.subtitle
                color: Theme.Theme.subtext
                font.family: Theme.Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }
    }
}
