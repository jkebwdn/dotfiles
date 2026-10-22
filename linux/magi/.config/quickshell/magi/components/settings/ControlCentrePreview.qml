pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme
import "../../settings/SettingsSchema.js" as Schema
import "../../plugins/bar/controlcentre/SectionLayout.js" as SectionLayout
import "../../plugins/bar/controlcentre" as CC
import "../controls" as Controls

Rectangle {
    id: root
    color: Theme.Theme.surface
    radius: Theme.Theme.radius("surface", 11, width, height)
    implicitHeight: body.implicitHeight + 28
    property bool playing: true
    readonly property var layout: Services.Settings.data.controlCentre
    readonly property var controls: layout.controls.filter(e => e.enabled)
    readonly property var sliders: layout.sliders.filter(e => e.enabled)
    readonly property var actions: layout.actions.filter(e => e.enabled)
    // Fit width at readable tile size. Many columns use runtime's width clamp.
    readonly property int columns: Math.max(1, Math.min(layout.columns, Math.floor((width - 28 + 12) / (Theme.RenderTokens.tileSize + 12))))
    readonly property var sectionLayout: SectionLayout.arrange([profile.visible, quick.visible, sliderGrid.visible, actionGrid.visible, player.visible], [profile.implicitHeight, quick.implicitHeight, sliderGrid.implicitHeight, actionGrid.implicitHeight, player.implicitHeight], [Theme.Theme.visual.profileControlsGap, Theme.Theme.visual.controlsSlidersGap, Theme.Theme.visual.slidersActionsGap, Theme.Theme.visual.actionsMediaGap])
    signal moveRequested(string group, string key, int position)
    function definition(id) {
        return Schema.controlDefinitions().find(e => e.id === id);
    }
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
    Flickable {
        anchors.fill: parent
        anchors.margins: 14
        clip: true
        contentWidth: width
        contentHeight: body.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        Column {
            id: body
            width: Math.min(parent.width, Math.max(300 - 28, root.columns * Theme.RenderTokens.tileSize + (root.columns - 1) * 12))
            x: (parent.width - width) / 2
            Text {
                text: "LIVE PREVIEW · " + root.columns + " columns"
                color: Theme.Theme.subtext
                font.pixelSize: 12
                height: 28
            }
            Item {
                width: parent.width
                implicitHeight: root.sectionLayout.height
                CC.ProfileHeader {
                    id: profile
                    y: root.sectionLayout.positions[0]
                    objectName: "previewProfile"
                    width: parent.width
                    visible: root.layout.sections.profile
                    preview: true
                    localHour: 19
                    weatherSummary: "12°C · Cloudy"
                    profile: ({
                            displayName: "jkebwdn",
                            greetingStyle: Services.Settings.data.profile.greetingStyle,
                            subtitleMode: "custom",
                            subtitle: "A little room to make things yours",
                            avatar: Services.Settings.data.profile.avatar
                        })
                }
                PreviewControlGrid {
                    id: quick
                    y: root.sectionLayout.positions[1]
                    itemWidth: Theme.RenderTokens.tileSize
                    objectName: "previewControls"
                    width: parent.width
                    group: "controls"
                    entries: root.controls
                    visible: root.layout.sections.quickControls && entries.length > 0
                    columns: root.columns
                    cellHeight: Theme.RenderTokens.tileSize
                    onMoveRequested: (group, key, position) => root.moveRequested(group, key, position)
                    presenter: Component {
                        CC.ControlTile {
                            readonly property var entry: parent.entry
                            readonly property var definition: root.definition(entry.module)
                            moduleId: entry.module
                            icon: definition.icon
                            title: definition.label
                            subtitle: ["wifi", "bluetooth"].includes(entry.module) ? "On" : "Off"
                            interactive: false
                            toggle: ["wifi", "bluetooth", "power-saver", "airplane-mode", "vpn", "dnd", "caffeine"].includes(entry.module)
                            active: ["wifi", "bluetooth"].includes(entry.module)
                            available: true
                            accentRole: entry.accent || definition.accent
                            activeColor: Theme.Theme.primaryAccent(accentRole, definition.accent)
                        }
                    }
                }
                PreviewControlGrid {
                    id: sliderGrid
                    y: root.sectionLayout.positions[2]
                    objectName: "previewSliders"
                    width: parent.width
                    group: "sliders"
                    entries: root.sliders
                    visible: root.layout.sections.sliders && entries.length > 0
                    columns: Math.max(1, root.sliders.length)
                    gap: Theme.RenderTokens.sliderGap
                    cellHeight: Theme.RenderTokens.sliderHeight
                    onMoveRequested: (group, key, position) => root.moveRequested(group, key, position)
                    presenter: Component {
                        Controls.IconSlider {
                            readonly property var entry: parent.entry
                            interactive: false
                            moduleId: entry.module
                            icon: entry.module === "volume" ? "volume" : "brightness"
                            value: entry.module === "volume" ? .65 : .8
                        }
                    }
                }
                PreviewControlGrid {
                    id: actionGrid
                    y: root.sectionLayout.positions[3]
                    itemWidth: Theme.RenderTokens.actionSize
                    objectName: "previewActions"
                    width: parent.width
                    group: "actions"
                    entries: root.actions
                    visible: root.layout.sections.actions && entries.length > 0
                    columns: Math.max(1, Math.min(root.layout.actionColumns, root.actions.length, Math.floor((width + 8) / (Theme.RenderTokens.actionSize + 8))))
                    gap: 8
                    cellHeight: Theme.RenderTokens.actionSize
                    onMoveRequested: (group, key, position) => root.moveRequested(group, key, position)
                    presenter: Component {
                        CC.ActionButton {
                            readonly property var entry: parent.entry
                            readonly property var definition: root.definition(entry.module)
                            moduleId: entry.module
                            icon: definition.icon
                            label: definition.label
                            toggle: false
                            available: true
                        }
                    }
                }
                CC.MediaSection {
                    id: player
                    y: root.sectionLayout.positions[4]
                    objectName: "previewMedia"
                    width: parent.width
                    visible: root.layout.sections.media && Services.Settings.data.media.enabled
                    service: media
                    interactive: false
                    enabled: false
                }
            }
            Text {
                width: parent.width
                height: 44
                wrapMode: Text.Wrap
                text: "Drag handles arrange controls. No system actions run."
                color: Theme.Theme.subtext
                font.pixelSize: 11
            }
        }
    }
}
