import QtQuick
import QtQuick.Layouts
import "../../../components/controls" as Controls
import "../../../services" as Services
import "../../../theme" as Theme

Rectangle {
    id: root
    implicitHeight: 86
    radius: Theme.Theme.radius("controlTile", 10, width, height)
    color: Theme.Theme.elevated
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10
        Rectangle {
            Layout.preferredWidth: 70
            Layout.preferredHeight: 70
            radius: Theme.Theme.radius("action", 8, width, height)
            color: Theme.Theme.overlay
            clip: true
            Image {
                id: artwork
                anchors.fill: parent
                source: Services.Media.artworkUrl
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                sourceSize: Qt.size(140, 140)
            }
            Controls.Icon {
                anchors.centerIn: parent
                visible: !artwork.visible
                role: "media-play"
                moduleId: "media"
                size: 24
                color: Theme.Theme.subtext
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: Services.Media.title || Services.Media.identity
                color: Theme.Theme.text
                font.family: Theme.Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: Services.Media.artist || Services.Media.identity
                color: Theme.Theme.subtext
                font.family: Theme.Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
                visible: text.length > 0 && text !== Services.Media.title
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 4
                Controls.ActionChip {
                    icon: "media-previous"; moduleId: "media"; available: Services.Media.canPrevious
                    onTriggered: Services.Media.previous()
                }
                Controls.ActionChip {
                    icon: Services.Media.playing ? "media-pause" : "media-play"
                    moduleId: "media"; available: Services.Media.canToggle
                    onTriggered: Services.Media.togglePlaying()
                }
                Controls.ActionChip {
                    icon: "media-next"; moduleId: "media"; available: Services.Media.canNext
                    onTriggered: Services.Media.next()
                }
            }
        }
    }
}
