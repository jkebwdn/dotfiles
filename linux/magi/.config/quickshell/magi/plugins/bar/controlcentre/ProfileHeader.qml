import QtQuick
import QtQuick.Layouts
import "../../../components/controls" as Controls
import "../../../components/controls/VisualState.js" as VisualState
import "../../../services" as Services
import "../../../theme" as Theme

Rectangle {
    id: root
    implicitHeight: 58
    radius: Theme.Theme.radius("controlTile", 10, width, height)
    color: Theme.Theme.elevated
    readonly property var profile: Services.Settings.data.profile
    property int localHour: new Date().getHours()
    Timer { interval: 60000; repeat: true; running: true; onTriggered: root.localHour = new Date().getHours() }
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10
        Controls.RoundedArtwork {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            radius: Theme.Theme.radius("avatar", 10, width, height)
            borderWidth: Theme.Theme.visual.avatarBorderWidth
            source: Services.AssetManager.assetUrl(root.profile.avatar)
            placeholder: "profile"
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
                text: root.profile.subtitleMode === "custom" ? root.profile.subtitle : VisualState.greeting(root.localHour)
                color: Theme.Theme.subtext
                font.family: Theme.Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }
    }
}
