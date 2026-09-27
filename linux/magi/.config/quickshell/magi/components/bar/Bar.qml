
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import "../../plugins/bar/clock" as ClockPlugin
import "../../plugins/bar/date" as DatePlugin
import "../../plugins/bar/workspaces" as WorkspacePlugin
import "../../plugins/bar/battery" as BatteryPlugin
import "../../modules" as Modules
import "../../services" as MagiServices
import "../../theme" as MagiTheme

PanelWindow {
    id: bar

    // Set to "anchored" to retain the native 48px bar and PopupWindow host.
    property string expandableHostMode: "anchored"

    Modules.ModuleRegistry {
        id: registry
        barWindow: bar
        hostMode: bar.expandableHostMode
        sharedSurface: bar.combinedMode ? statusSurface : null
    }
    readonly property var expandablePillRegistry: registry.modules
    readonly property bool combinedMode: expandableHostMode === "combined"
    readonly property var activeExpandablePill: combinedMode
        ? registry.modules[MagiServices.MenuController.activeMenu] || null : null
    readonly property bool combinedMenuActive: activeExpandablePill !== null
    readonly property Item activeCombinedRegion:
        combinedMode && statusSurface.revealedHeight > 0 ? statusSurface : null
    readonly property bool catcherEnabled: combinedMenuActive
    readonly property bool combinedKeyboardEnabled:
        combinedMenuActive && activeExpandablePill.menuKeyboardFocus

    function closeActiveCombinedMenu() {
        if (combinedMenuActive)
            MagiServices.MenuController.close()
    }

    property var combinedInputMask: Region {
        item: barStrip

        Region {
            item: bar.activeCombinedRegion
            intersection: Intersection.Combine
        }

        Region {
            item: bar.catcherEnabled ? clickCatcher : null
            intersection: Intersection.Combine
        }
    }

    exclusiveZone: combinedMode ? 48 : 0
    exclusionMode: combinedMode
        ? ExclusionMode.Normal
        : ExclusionMode.Auto
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: combinedKeyboardEnabled
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: combinedMode
        ? Math.max(48, screen ? screen.height : 48)
        : 48
    color: "transparent"
    mask: combinedMode ? combinedInputMask : null

    // ---------------------------------------------------------
    // Enabled plugins and positions
    // ---------------------------------------------------------

    property var placement: ({left: [], center: [], right: []})
    Component.onCompleted: syncPlacement()
    readonly property var leftPlugins: placement.left
    readonly property var centerPlugins: placement.center
    readonly property var rightPlugins: placement.right
    function syncPlacement() {
        if (MagiServices.MenuController.activeMenu !== "" || statusSurface.phase !== 0
                || registry.interactionBusy || registry.presentationBusy) return
        if (JSON.stringify(placement) !== JSON.stringify(MagiServices.Settings.data.bar))
            placement = MagiServices.Settings.data.bar
    }
    Connections {
        target: MagiServices.Settings
        function onDataChanged() { Qt.callLater(bar.syncPlacement) }
    }
    Connections {
        target: statusSurface
        function onPhaseChanged() { Qt.callLater(bar.syncPlacement) }
    }
    Connections {
        target: registry
        function onInteractionBusyChanged() { Qt.callLater(bar.syncPlacement) }
        function onPresentationBusyChanged() { Qt.callLater(bar.syncPlacement) }
    }
    Connections {
        target: MagiServices.MenuController
        function onActiveMenuChanged() { Qt.callLater(bar.syncPlacement) }
    }

    // ---------------------------------------------------------
    // Plugin components
    // ---------------------------------------------------------

    readonly property var pluginComponents: ({
        "clock": clockComponent,
        "date": dateComponent,
        "workspaces": workspacesComponent,
        "volume": volumeComponent,
        "wifi": wifiComponent,
        "bluetooth": bluetoothComponent,
        "battery": batteryComponent,
        "controlcentre": controlCentreComponent
    })

    Component {
        id: clockComponent

        ClockPlugin.Clock {}
    }

    Component {
        id: dateComponent

        DatePlugin.CalendarDate {}
    }

    Component {
        id: workspacesComponent

        WorkspacePlugin.Workspaces {}
    }

    Component {
        id: wifiComponent

        ModulePill { module: registry.modules.wifi }
    }

    Component {
        id: volumeComponent

        ModulePill { module: registry.modules.volume }
    }

    Component {
        id: batteryComponent

        BatteryPlugin.Battery {
            sharedExpansion: bar.combinedMode ? statusSurface.expansion : 0
        }
    }

    Component {
        id: bluetoothComponent

        ModulePill { module: registry.modules.bluetooth }
    }

    Component {
        id: controlCentreComponent

        ModulePill { module: registry.modules.controlcentre }
    }

    IpcHandler {
        target: "magi"
        function status(): string {
            const phases = {}
            for (const id of Object.keys(registry.modules)) phases[id] = registry.modules[id].phase
            return JSON.stringify({mode: bar.expandableHostMode,
                modules: Object.keys(registry.modules),
                pills: Object.keys(registry.modules).filter(id => registry.modules[id].pill !== null),
                active: MagiServices.MenuController.activeMenu,
                phase: statusSurface.phase, catcher: bar.catcherEnabled,
                keyboard: bar.combinedKeyboardEnabled,
                width: bar.width, height: bar.height, reservation: bar.exclusiveZone,
                viewWidth: statusSurface.width, viewHeight: statusSurface.height,
                interactive: statusSurface.interactive,
                theme: MagiTheme.Theme.effectiveTheme, themeDiagnostic: MagiTheme.Theme.diagnostic,
                surfaceColor: MagiTheme.Theme.surface.toString(),
                pillRadius: MagiTheme.Theme.barPillRadius,
                modulePhases: phases})
        }
        function open(view: string): bool {
            if (!registry.modules[view]) return false
            MagiServices.MenuController.open(view)
            return true
        }
        function close(): void { MagiServices.MenuController.close() }
    }

    Item {
        id: clickCatcher

        anchors.fill: parent
        visible: bar.catcherEnabled
        z: 0

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onClicked: bar.closeActiveCombinedMenu()
        }
    }

    Rectangle {
        id: barStrip

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: 48
        z: 9
        color: "transparent"
    }

    // ---------------------------------------------------------
    // Left section
    // ---------------------------------------------------------

    Row {
        id: leftSection

        anchors {
            left: barStrip.left
            leftMargin: MagiTheme.Theme.barEdgeMargin
            verticalCenter: barStrip.verticalCenter
        }

        spacing: MagiTheme.Theme.barSectionSpacing
        z: 10

        Repeater {
            model: bar.leftPlugins

            Loader {
                required property string modelData
                readonly property var pluginItem: registry.modules[modelData] || item

                sourceComponent: bar.pluginComponents[modelData] || null
                active: !registry.modules[modelData] || registry.modules[modelData].barVisible
                visible: !pluginItem
                        || pluginItem["barVisible"] === undefined
                    ? true
                    : pluginItem["barVisible"]
            }
        }
    }

    // ---------------------------------------------------------
    // Centre section
    // ---------------------------------------------------------

    Row {
        id: centerSection

        anchors.centerIn: barStrip

        spacing: MagiTheme.Theme.barSectionSpacing
        z: 10

        Repeater {
            model: bar.centerPlugins

            Loader {
                required property string modelData
                readonly property var pluginItem: registry.modules[modelData] || item

                sourceComponent: bar.pluginComponents[modelData] || null
                active: !registry.modules[modelData] || registry.modules[modelData].barVisible
                visible: !pluginItem
                        || pluginItem["barVisible"] === undefined
                    ? true
                    : pluginItem["barVisible"]
            }
        }
    }

    // ---------------------------------------------------------
    // Right section
    // ---------------------------------------------------------

    SharedStatusSurface {
        id: statusSurface
        x: bar.width - MagiTheme.Theme.barEdgeMargin - width
        y: (48 - MagiTheme.Theme.barPillHeight) / 2
        z: 10
        combined: bar.combinedMode
        requestedModule: bar.activeExpandablePill
        modules: Object.values(bar.expandablePillRegistry)

        statusContent: Component {
            Row {
                spacing: MagiTheme.Theme.barSectionSpacing
                Repeater {
                    model: bar.rightPlugins
                    Loader {
                        required property string modelData
                        readonly property var pluginItem: registry.modules[modelData] || item
                        sourceComponent: bar.pluginComponents[modelData] || null
                        active: !registry.modules[modelData] || registry.modules[modelData].barVisible
                        visible: !pluginItem
                                || pluginItem["barVisible"] === undefined
                            ? true : pluginItem["barVisible"]
                    }
                }
            }
        }
    }
}
