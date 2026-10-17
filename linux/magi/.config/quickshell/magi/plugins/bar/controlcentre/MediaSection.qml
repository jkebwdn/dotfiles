import QtQuick
import QtQuick.Layouts
import "../../../components/controls" as Controls
import "../../../services" as Services
import "../../../theme" as Theme

Rectangle {
    id: root
    implicitHeight: Theme.RenderTokens.mediaHeight
    radius: Theme.Theme.radius("controlTile", 10, width, height)
    color: Theme.Theme.elevated
    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        Controls.RoundedArtwork {
            objectName: "runtimeAlbumArt"
            Layout.preferredWidth: Theme.RenderTokens.mediaArtworkSize
            Layout.preferredHeight: Theme.RenderTokens.mediaArtworkSize
            radius: Theme.Theme.radius("albumArt", 10, width, height)
            source: Services.Media.artworkUrl
            progress: Services.Media.progress
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: Services.Media.available ? Services.Media.title || Services.Media.identity || "Media" : "Nothing playing"
                color: Theme.Theme.text
                font.family: Theme.Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: Services.Media.available ? Services.Media.artist : "Your media will appear here"
                color: Theme.Theme.subtext
                font.family: Theme.Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12
                Controls.MediaButton {
                    icon: "media-previous"; moduleId: "media"; available: Services.Media.canPrevious
                    onTriggered: Services.Media.previous()
                }
                Controls.MediaButton {
                    icon: Services.Media.playing ? "media-pause" : "media-play"
                    moduleId: "media"; available: Services.Media.canToggle
                    onTriggered: Services.Media.togglePlaying()
                }
                Controls.MediaButton {
                    icon: "media-next"; moduleId: "media"; available: Services.Media.canNext
                    onTriggered: Services.Media.next()
                }
            }
        }
    }
}
