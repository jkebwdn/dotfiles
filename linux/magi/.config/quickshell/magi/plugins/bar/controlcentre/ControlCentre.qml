pragma ComponentBehavior: Bound
import QtQuick
import "../../../components/bar" as MagiBar
import "../../../components/controls" as Controls
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../modules" as Modules
import "../../../icons" as Icons
MagiBar.ExpandableModule {
    id: root
    onSecondaryTriggered: Services.SettingsWindowState.open()
    menuId: "controlcentre"
    icon: "settings"
    title: "Control Centre"
    collapsedWidth: 30
    property bool configurationBusy: false
    property var layout: Services.Settings.data.controlCentre
    function syncLayout() {
        if (!configurationBusy && JSON.stringify(layout) !== JSON.stringify(Services.Settings.data.controlCentre))
            layout = Services.Settings.data.controlCentre
    }
    Connections { target: Services.Settings; function onDataChanged() { Qt.callLater(root.syncLayout) } }
    onConfigurationBusyChanged: Qt.callLater(root.syncLayout)
    readonly property var controls: layout.controls.filter(e => e.enabled && Modules.ControlCatalog.definition(e.module))
    readonly property var sliders: layout.sliders.filter(e => e.enabled)
    readonly property real tileGap: 18
    readonly property real availableWidth: barWindow ? Math.max(88, barWindow.width - 28) : 1200
    readonly property int columns: Math.max(1, Math.min(layout.columns,
        Math.floor((availableWidth - 2 * viewPadding + tileGap) / (Theme.RenderTokens.tileSize + tileGap))))
    readonly property int rows: Math.ceil(controls.length / columns)
    readonly property real gridHeight: rows ? rows * Theme.RenderTokens.tileSize + (rows - 1) * tileGap : 0
    readonly property real naturalHeight: gridHeight + (sliders.length ? (rows ? 24 : 0) + 48 : 0)
    readonly property real availableHeight: barWindow && hostMode === "combined" ? Math.max(80, barWindow.height - 90) : 700
    expandedWidth: Math.min(availableWidth, Math.max(200,
        columns * Theme.RenderTokens.tileSize + (columns - 1) * tileGap + 2 * viewPadding))
    menuHeight: Math.min(availableHeight, Math.max(42, naturalHeight + viewTopPadding + viewBottomPadding))
    viewPadding: Theme.RenderTokens.padding
    viewTopPadding: 6
    viewBottomPadding: Theme.RenderTokens.padding
    viewRadius: Theme.RenderTokens.outerRadius
    viewSurfaceColor: Theme.Theme.surface
    color: sharedSurface ? Qt.alpha(Theme.Theme.surface, 1 - sharedSurface.expansion) : Theme.Theme.surface
    pillContent: Component {
        Controls.MorphingPillContent {
            pill: parent; icon: root.icon; moduleId: "controlcentre"
            expandedTitle: "Control Centre"
        }
    }
    menuContent: Component {
        Flickable {
            width: parent ? parent.width : 0
            height: Math.max(0, root.menuHeight - root.viewTopPadding - root.viewBottomPadding)
            contentHeight: content.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: content
                width: parent.width
                spacing: root.rows && root.sliders.length ? 24 : 0
                Grid {
                    columns: root.columns
                    columnSpacing: root.tileGap
                    rowSpacing: root.tileGap
                    Repeater {
                        model: root.controls
                        ControlTile {
                            required property var modelData
                            readonly property var definition: Modules.ControlCatalog.definition(modelData.module)
                            readonly property var live: Modules.ControlCatalog.state(modelData.module)
                            moduleId: modelData.module
                            icon: live.icon
                            title: definition.label
                            subtitle: live.status
                            active: live.active
                            available: live.available
                            interactive: modelData.module !== "battery"
                            accentRole: definition.accent
                            activeColor: Theme.Theme.roles[accentRole]
                            rimColor: Theme.Theme.controlRim(activeColor)
                            onPrimaryTriggered: Modules.ControlCatalog.primary(modelData.module)
                            onSecondaryTriggered: Modules.ControlCatalog.secondary(modelData.module)
                        }
                    }
                }
                Row {
                    width: parent.width
                    spacing: Theme.RenderTokens.sliderGap
                    Repeater {
                        model: root.sliders
                        Controls.IconSlider {
                            required property var modelData
                            readonly property bool audio: modelData.module === "volume"
                            width: (content.width - (root.sliders.length - 1) * Theme.RenderTokens.sliderGap) / Math.max(1, root.sliders.length)
                            moduleId: modelData.module
                            icon: audio ? Icons.IconRegistry.volumeRole(Services.Audio.available,Services.Audio.muted,Services.Audio.volumePercent) : "brightness"
                            value: audio ? Services.Audio.volume : Services.Brightness.percent / 100
                            interactive: audio ? Services.Audio.available : Services.Brightness.available
                            onValueMoved: value => audio ? Services.Audio.setVolume(value) : Services.Brightness.setPercent(value * 100)
                        }
                    }
                }
            }
        }
    }
}
