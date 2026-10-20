import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../../../components/controls" as Controls
import "../../../services" as Services
import "../../../theme" as Theme

Rectangle {
    id: root
    property var service: Services.Media
    readonly property int contentPadding: 10
    implicitHeight: Math.max(Theme.RenderTokens.mediaArtworkSize, metadata.implicitHeight) + contentPadding * 2
    radius: Theme.Theme.radius("controlTile", 10, width, height)
    color: Theme.Theme.elevated
    RowLayout {
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: 10
        Controls.RoundedArtwork {
            objectName: "runtimeAlbumArt"
            Layout.preferredWidth: Theme.RenderTokens.mediaArtworkSize
            Layout.preferredHeight: Theme.RenderTokens.mediaArtworkSize
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.Theme.radius("albumArt", 10, width, height)
            placeholder: "media-play"
            source: root.service.artworkUrl
            progressColor: Theme.Theme.mediaProgressColor
            progress: root.service.available ? root.service.progress : -1
            borderColor: Theme.Theme.border
            borderWidth: Theme.Theme.visual.mediaProgressBorderWidth
        }
        ColumnLayout {
            id: metadata
            Layout.fillHeight: false
            objectName: "mediaMetadataStack"
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2
            Text {
                objectName: "mediaTitle"
                Layout.fillWidth: true
                text: root.service.available ? root.service.title || root.service.identity || "Media" : "Nothing playing"
                color: Theme.Theme.text
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.visual.mediaTitleSize
                font.weight: Theme.Theme.visual.mediaTitleWeight
                textFormat: Text.PlainText
                elide: Text.ElideRight
                ToolTip.visible: titleHover.hovered && truncated
                ToolTip.text: text
                HoverHandler { id: titleHover }
            }
            Text {
                Layout.fillWidth: true
                text: root.service.available ? root.service.artist || root.service.identity : "Your media will appear here"
                color: Theme.Theme.subtext
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.visual.mediaArtistSize
                font.weight: Theme.Theme.visual.mediaArtistWeight
                objectName: "mediaArtist"
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
            RowLayout {
                Layout.alignment: Qt.AlignLeft
                visible: Services.Settings.data.media.controlsVisibility === "always"
                    || Services.Settings.data.media.controlsVisibility === "active" && root.service.available
                spacing: 8
                Controls.MediaButton {
                    objectName: "mediaPrevious"
                    icon: "media-previous"; moduleId: "media"; available: root.service.available && root.service.canPrevious
                    onTriggered: root.service.previous()
                }
                Controls.MediaButton {
                    objectName: "mediaToggle"
                    icon: root.service.playing ? "media-pause" : "media-play"
                    moduleId: "media"; available: root.service.available && root.service.canToggle
                    onTriggered: root.service.togglePlaying()
                }
                Controls.MediaButton {
                    objectName: "mediaNext"
                    icon: "media-next"; moduleId: "media"; available: root.service.available && root.service.canNext
                    onTriggered: root.service.next()
                }
            }
        }
    }
}
