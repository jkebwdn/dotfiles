pragma ComponentBehavior: Bound
import QtQuick
import "../../plugins/bar/controlcentre" as CC
import "../../services" as Services
import "../../theme" as Theme

Item {
    id: root
    required property string section
    property bool renderControls: true
    property bool playing: true
    property var entries: []
    property int columns: 4
    property real cellSize: 68
    property real cellWidth: cellSize
    property real gap: 12
    readonly property real naturalHeight: section === "profile" ? profileLoader.item ? profileLoader.item.implicitHeight : 0 : section === "media" ? mediaLoader.item ? mediaLoader.item.implicitHeight : 0 : Math.max(cellSize, Math.ceil(entries.length / columns) * (cellSize + 12) - 12)
    QtObject {
        id: media
        readonly property bool available: true
        readonly property bool playing: root.playing
        readonly property bool canPrevious: true
        readonly property bool canNext: true
        readonly property bool canToggle: true
        readonly property string title: "Midnight City · Preview"
        readonly property string artist: "M83 · Hurry Up, We're Dreaming"
        readonly property string identity: "Preview player"
        readonly property string artworkUrl: Qt.resolvedUrl("preview-artwork.svg").toString()
        readonly property real progress: .42
        function previous() {
        }
        function next() {
        }
        function togglePlaying() {
        }
    }
    Loader {
        id: profileLoader
        width: parent.width
        active: root.section === "profile"
        sourceComponent: Component {
            CC.ProfileHeader {
                id: profile
                objectName: root.section === "profile" ? "previewProfile" : ""
                width: parent.width
                visible: root.section === "profile"
                preview: true
                localHour: 19
                weatherSummary: "12°C · Cloudy"
                profile: ({
                        displayName: "Alex Morgan",
                        greetingStyle: Services.Settings.data.profile.greetingStyle,
                        subtitleMode: "custom",
                        subtitle: "A little room to make things yours",
                        avatar: null
                    })
            }
        }
    }
    Loader {
        id: mediaLoader
        width: parent.width
        active: root.section === "media"
        sourceComponent: Component {
            CC.MediaSection {
                id: player
                objectName: root.section === "media" ? "previewMedia" : ""
                width: parent.width
                visible: root.section === "media"
                service: media
                interactive: false
                enabled: false
            }
        }
    }
    Repeater {
        model: root.renderControls && !["profile", "media"].includes(root.section) ? root.entries : []
        CCControlPreview {
            required property var modelData
            required property int index
            entry: modelData
            family: root.section
            x: (index % root.columns) * (width + root.gap)
            y: Math.floor(index / root.columns) * (height + root.gap)
            width: root.cellWidth
            height: root.cellSize
        }
    }
}
