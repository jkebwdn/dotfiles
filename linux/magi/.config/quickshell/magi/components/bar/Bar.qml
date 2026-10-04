
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
import "../notifications" as NotificationsUI
import "../calendar" as CalendarUI

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
    readonly property bool settingsReady: statusSurface.phase === 0 && calendarSurface.phase === 0 && !MagiServices.Calendar.opened && !registry.interactionBusy && !registry.presentationBusy
    readonly property var expandablePillRegistry: registry.modules
    readonly property bool combinedMode: expandableHostMode === "combined"
    readonly property var activeExpandablePill: combinedMode
        && registry.modules[MagiServices.MenuController.activeMenu]?.expandsOnClick
        ? registry.modules[MagiServices.MenuController.activeMenu] : null
    readonly property bool combinedMenuActive: activeExpandablePill !== null || MagiServices.Calendar.opened
    readonly property bool fullSurface: combinedMode || MagiServices.Calendar.opened || calendarSurface.absorbed
    property Item clockAnchor: null
    property Item dateAnchor: null
    function toggleCalendar(item) {
        if (!MagiServices.Calendar.opened) calendarSurface.anchorItem = item
        MagiServices.Calendar.toggle()
    }
    readonly property Item activeCombinedRegion:
        combinedMode && statusSurface.revealedHeight > 0 ? statusSurface : null
    readonly property bool catcherEnabled: combinedMenuActive
    readonly property bool combinedKeyboardEnabled:
        MagiServices.Calendar.opened || (activeExpandablePill !== null && activeExpandablePill.menuKeyboardFocus)

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
            item: calendarSurface.absorbed ? calendarSurface : null
            intersection: Intersection.Combine
        }
        Region {
            item: bar.catcherEnabled ? clickCatcher : null
            intersection: Intersection.Combine
        }
    }

    exclusiveZone: fullSurface ? 48 : 0
    exclusionMode: fullSurface
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

    implicitHeight: fullSurface
        ? Math.max(48, screen ? screen.height : 48)
        : 48
    color: "transparent"
    mask: fullSurface ? combinedInputMask : null

    IdleInhibitor {
        enabled: MagiServices.Caffeine.requested
        window: bar
    }
    Component.onDestruction: MagiServices.Caffeine.bound = false

    // ---------------------------------------------------------
    // Enabled plugins and positions
    // ---------------------------------------------------------

    property var placement: ({left: [], center: [], right: []})
    Component.onCompleted: {
        MagiServices.Caffeine.bound = true
        syncPlacement()
    }
    readonly property var leftPlugins: placement.left
    readonly property var centerPlugins: placement.center
    readonly property var rightPlugins: placement.right
    function syncPlacement() {
        if (MagiServices.MenuController.activeMenu !== "" || statusSurface.phase !== 0 || calendarSurface.phase !== 0
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
        target: calendarSurface
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
        "notifications": notificationsComponent,
        "controlcentre": controlCentreComponent
    })

    Component {
        id: clockComponent

        ClockPlugin.Clock {
            id: clockPill
            absorbed: calendarSurface.absorbed
            onTriggered: bar.toggleCalendar(clockPill)
            Component.onCompleted: bar.clockAnchor = clockPill
            Component.onDestruction: { if (bar.clockAnchor === clockPill) bar.clockAnchor = null }
        }
    }

    Component {
        id: dateComponent

        DatePlugin.CalendarDate {
            id: datePill
            absorbed: calendarSurface.absorbed
            onTriggered: bar.toggleCalendar(datePill)
            Component.onCompleted: bar.dateAnchor = datePill
            Component.onDestruction: { if (bar.dateAnchor === datePill) bar.dateAnchor = null }
        }
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
    Component { id: notificationsComponent; NotificationsUI.NotificationIndicator {} }

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
                calendar: {opened:MagiServices.Calendar.opened, phase:calendarSurface.phase,
                    absorbed:calendarSurface.absorbed, x:calendarSurface.x, y:calendarSurface.y,
                    width:calendarSurface.width, height:calendarSurface.height,
                    clockOpacity:bar.clockAnchor ? bar.clockAnchor.opacity : -1,
                    dateOpacity:bar.dateAnchor ? bar.dateAnchor.opacity : -1},
                modulePhases: phases})
        }
        function open(view: string): bool {
            if (view === "calendar") {
                const anchor = bar.clockAnchor || bar.dateAnchor
                if (!anchor) return false
                calendarSurface.anchorItem = anchor
                MagiServices.Calendar.open()
                return MagiServices.Calendar.opened
            }
            if (!registry.modules[view] || !registry.modules[view].expandsOnClick) return false
            MagiServices.MenuController.open(view)
            return true
        }
        function close(): void { MagiServices.MenuController.close() }
    }

    CalendarUI.CalendarSurface {
        id: calendarSurface
        objectName: "calendarSurface"
        service: MagiServices.Calendar
        clockItem: bar.clockAnchor
        dateItem: bar.dateAnchor
        z: 20
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
        move: Transition { NumberAnimation { properties: "x,y"; duration: 140; easing.type: Easing.OutCubic } }

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
        move: Transition { NumberAnimation { properties: "x,y"; duration: 140; easing.type: Easing.OutCubic } }

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
                id: statusRow
                // Same live delegates in both states. Only spacing/inset changes;
                // compact metrics never depend on animated spacing.
                readonly property int visibleItems: children.filter(item => item.visible && item.width > 0).length
                readonly property real itemWidths: children.reduce((sum, item) => sum + (item.visible ? item.width : 0), 0)
                readonly property real compactWidth: itemWidths + Math.max(0, visibleItems - 1) * MagiTheme.Theme.barSectionSpacing
                readonly property real expandedStatusWidth: itemWidths + Math.max(0, visibleItems - 1) * 12
                spacing: MagiTheme.Theme.barSectionSpacing + (12 - MagiTheme.Theme.barSectionSpacing) * statusSurface.expansion
                move: Transition {
                    enabled: !bar.combinedMode || statusSurface.phase === 0
                    NumberAnimation { properties: "x,y"; duration: 140; easing.type: Easing.OutCubic }
                }
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
