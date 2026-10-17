import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../../../components/controls" as Controls
import "../../../services" as Services
import "../../../theme" as Theme

Rectangle {
    id: root
    property var service: Services.Media
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
            placeholder: "media-play"
            source: root.service.artworkUrl
            progress: root.service.available ? root.service.progress : -1
            borderColor: Theme.Theme.border
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            spacing: 2
            Text {
                objectName: "mediaTitle"
                Layout.fillWidth: true
                text: root.service.available ? root.service.title || root.service.identity || "Media" : "Nothing playing"
                color: Theme.Theme.text
                font.family: Theme.Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
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
                font.pixelSize: 11
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.alignment: Qt.AlignLeft
                visible: root.service.available
                spacing: 8
                Controls.MediaButton {
                    objectName: "mediaPrevious"
                    icon: "media-previous"; moduleId: "media"; available: root.service.canPrevious
                    onTriggered: root.service.previous()
                }
                Controls.MediaButton {
                    objectName: "mediaToggle"
                    icon: root.service.playing ? "media-pause" : "media-play"
                    moduleId: "media"; available: root.service.canToggle
                    onTriggered: root.service.togglePlaying()
                }
                Controls.MediaButton {
                    objectName: "mediaNext"
                    icon: "media-next"; moduleId: "media"; available: root.service.canNext
                    onTriggered: root.service.next()
                }
            }
        }
    }
}
