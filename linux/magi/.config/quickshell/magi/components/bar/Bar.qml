
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland

import "../../plugins/bar/clock" as ClockPlugin
import "../../plugins/bar/date" as DatePlugin
import "../../plugins/bar/workspaces" as WorkspacePlugin
import "../../plugins/bar/battery" as BatteryPlugin
import "../../modules" as Modules
import "../../services" as MagiServices
import "../../theme" as MagiTheme
import "../calendar" as CalendarUI
import "../tray" as TrayUI
import "OutputPolicy.js" as OutputPolicy

PanelWindow {
    id: bar

    property var outputScreen: screen
    readonly property bool ownsMenu: !outputScreen || MagiServices.SurfaceOrigin.menuTarget() === outputScreen
    readonly property bool bottomBar: MagiServices.Settings.data.bar.position === "bottom"
    readonly property real minimumBarWidth: Math.max(
        leftSection.implicitWidth + statusSurface.collapsedWidth + 3 * MagiTheme.Theme.barEdgeMargin,
        2 * Math.max(leftSection.implicitWidth, statusSurface.collapsedWidth) + centerSection.implicitWidth + 4 * MagiTheme.Theme.barEdgeMargin)
    readonly property var geometry: OutputPolicy.geometry(width, height,
        MagiServices.Settings.data.bar.horizontalInset, MagiServices.Settings.data.bar.edgeOffset,
        bottomBar, minimumBarWidth)
    readonly property alias statusPresentation: statusSurface
    readonly property real barY: geometry.y
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
    readonly property var activeExpandablePill: combinedMode && ownsMenu
        && registry.modules[MagiServices.MenuController.activeMenu]?.expandsOnClick
        ? registry.modules[MagiServices.MenuController.activeMenu] : null
    readonly property bool combinedMenuActive: activeExpandablePill !== null || (ownsMenu && MagiServices.Calendar.opened)
    readonly property bool fullSurface: trayOpened || combinedMode || (ownsMenu && MagiServices.Calendar.opened) || calendarSurface.absorbed
    property var trayPresenter: null
    property bool trayOpened: false
    readonly property bool trayConfigured: placement.left.includes("tray") || placement.center.includes("tray") || placement.right.includes("tray")
    readonly property bool trayShown: trayOnOutput && (MagiServices.TrayService.presentationOverride === null
        ? trayConfigured : MagiServices.TrayService.presentationOverride)
    readonly property bool trayOnOutput: outputScreen === MagiServices.SurfaceOrigin.mainScreen
    function closeTray() { trayOpened = false }
    onTrayOnOutputChanged: closeTray()
    onOutputScreenChanged: closeTray()
    property Item clockAnchor: null
    property Item dateAnchor: null
    function toggleCalendar(item) {
        calendarSurface.anchorItem = item
        MagiServices.Calendar.toggle(bar.outputScreen)
    }
    readonly property Item activeCombinedRegion:
        combinedMode && statusSurface.revealedHeight > 0 ? statusSurface : null
    readonly property bool previewPinned: MagiServices.SettingsWindowState.controlCentrePreview
        && MagiServices.MenuController.activeMenu === "controlcentre"
    readonly property bool catcherEnabled: trayOpened || (combinedMenuActive && !previewPinned)
    readonly property bool combinedKeyboardEnabled:
        trayOpened || (ownsMenu && MagiServices.Calendar.opened) || (activeExpandablePill !== null && activeExpandablePill.menuKeyboardFocus)

    function closeActiveCombinedMenu() {
        closeTray()
        if (combinedMenuActive && !previewPinned)
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
        Region { item: trayOverflow.visible ? trayOverflow : null; intersection: Intersection.Combine }
        Region {
            item: bar.catcherEnabled ? clickCatcher : null
            intersection: Intersection.Combine
        }
    }

    exclusiveZone: fullSurface ? geometry.reservation : 0
    exclusionMode: fullSurface
        ? ExclusionMode.Normal
        : ExclusionMode.Auto
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: combinedKeyboardEnabled
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    anchors {
        top: !bar.bottomBar
        bottom: bar.bottomBar
        left: true
        right: true
    }

    implicitHeight: fullSurface
        ? Math.max(48, screen ? screen.height : 48)
        : 48
    color: "transparent"
    mask: fullSurface ? combinedInputMask : null
    BackgroundEffect.blurRegion: MagiTheme.Theme.sharedBlur ? paintedBlur : null
    Region {
        id: paintedBlur
        Region { regions: pillBlurRegions.instances }
        PaintedBlurRegion { target: trayOverflow; painted: trayOverflow.visible; cornerRadius: trayOverflow.radius }
        PaintedBlurRegion { target: barStrip; painted: barStrip.color.a > 0; cornerRadius: barStrip.radius }
        PaintedBlurRegion { target: statusSurface.paintedBackground; painted: bar.combinedMode && statusSurface.phase !== 0; cornerRadius: statusSurface.paintedBackground.radius }
        PaintedBlurRegion { target: calendarSurface.paintedBackground; painted: calendarSurface.absorbed; cornerRadius: calendarSurface.paintedBackground.radius }
    }
    Variants {
        id: pillBlurRegions
        model: [...(leftSection.opacity > 0 ? leftSection.children : []),
            ...(centerSection.opacity > 0 ? centerSection.children : []),
            ...(statusSurface.phase === 0 ? statusSurface.paintedPills : [])].filter(child => child["item"] !== undefined && child.item && child.visible)
        delegate: PaintedBlurRegion {
            required property var modelData
            target: modelData.item
            painted: MagiTheme.Theme.barVisual.statusPills.enabled || modelData.modelData === "workspaces"
            cornerRadius: MagiTheme.Theme.barPillRadius
        }
    }


    // ---------------------------------------------------------
    // Enabled plugins and positions
    // ---------------------------------------------------------

    property var placement: ({left: [], center: [], right: []})
    Component.onCompleted: {
        syncPlacement()
    }
    readonly property var leftPlugins: placement.left
    readonly property var centerPlugins: placement.center
    readonly property var rightPlugins: !trayConfigured && trayShown ? placement.right.concat(["tray"]) : placement.right
    function syncPlacement() {
        if (MagiServices.MenuController.activeMenu !== "" || statusSurface.phase !== 0 || calendarSurface.phase !== 0
                || registry.interactionBusy || registry.presentationBusy) return
        const next = {
            left: MagiServices.Settings.data.bar.left,
            center: MagiServices.Settings.data.bar.center,
            right: MagiServices.Settings.data.bar.right
        }
        if (JSON.stringify(placement) !== JSON.stringify(next)) placement = next
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
        function onActiveMenuChanged() { if (MagiServices.MenuController.activeMenu) bar.closeTray(); Qt.callLater(bar.syncPlacement) }
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
        "clipboard": clipboardComponent,
        "controlcentre": controlCentreComponent,
        "tray": trayComponent
    })

    Component {
        id: trayComponent
        TrayUI.TrayGroup {
            id: tray
            readonly property bool barVisible: bar.trayShown && items.length > 0
            showEmpty: false
            items: MagiServices.TrayService.items
            maximumWidth: Math.max(cellWidth + 8, Math.min(240, (bar.width - 2 * MagiServices.Settings.data.bar.horizontalInset) * .18))
            bottomUp: bar.bottomBar
            visible: barVisible
            onOverflowRequested: {
                MagiServices.MenuController.close()
                bar.trayOpened = !bar.trayOpened
            }
            onBarVisibleChanged: if (!barVisible) bar.closeTray()
            onOverflowItemsChanged: if (!overflowItems.length) bar.closeTray()
            Component.onCompleted: bar.trayPresenter = tray
            Component.onDestruction: { bar.closeTray(); if (bar.trayPresenter === tray) bar.trayPresenter = null }
        }
    }
    TrayUI.TrayOverflow {
        id: trayOverflow
        objectName: "trayOverflowSurface"
        z: 30
        items: bar.trayPresenter ? bar.trayPresenter.overflowItems : []
        opened: bar.trayOpened
        bottomUp: bar.bottomBar
        height: Math.min(implicitHeight, Math.max(0, bar.height - 48 - bar.geometry.edgeOffset - 8))
        x: {
            const opened = bar.trayOpened
            if (!bar.trayPresenter || !bar.trayPresenter.visible) return Math.max(0, bar.width - width - bar.geometry.inset - 8)
            const p = bar.trayPresenter.mapToItem(bar.contentItem, 0, 0)
            return Math.max(0, Math.min(bar.width - width, p.x))
        }
        y: bar.bottomBar ? bar.barY - height - 4 : bar.barY + 48 + 4
        onCloseRequested: bar.closeTray()
    }
    Component { id: notificationsComponent; UtilityPill { outputScreen: bar.outputScreen; mode: "notifications"; label: "Notifications" } }
    Component { id: clipboardComponent; UtilityPill { outputScreen: bar.outputScreen; mode: "clipboard"; label: "Clipboard" } }

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

        WorkspacePlugin.Workspaces { outputScreen: bar.outputScreen }
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
        if (view === "audio") view = "volume"
        if (view === "tray") {
            if (!trayOnOutput) return false
            MagiServices.TrayService.presentationOverride = true
            return true
        }
        if (view === "calendar") {
            const anchor = bar.clockAnchor || bar.dateAnchor
            if (!anchor) return false
            calendarSurface.anchorItem = anchor
            MagiServices.Calendar.open(bar.outputScreen)
            return MagiServices.Calendar.opened
        }
        if (!registry.modules[view] || !registry.modules[view].expandsOnClick) return false
        MagiServices.MenuController.open(view, bar.outputScreen)
        return true
    }
    function toggle(view: string): void {
        if (view === "audio") view = "volume"
        if (view === "tray") {
            if (trayOnOutput) {
                closeTray()
                MagiServices.TrayService.presentationOverride = !trayShown
            }
            return
        }
        if (ownsMenu && MagiServices.MenuController.activeMenu === view) MagiServices.MenuController.close()
        else open(view)
    }
    function close(): void { closeTray(); MagiServices.MenuController.close() }

    CalendarUI.CalendarSurface {
        id: calendarSurface
        objectName: "calendarSurface"
        service: MagiServices.Calendar
        presentationEnabled: bar.ownsMenu
        bottomUp: bar.bottomBar
        clockItem: bar.clockAnchor
        dateItem: bar.dateAnchor
        z: 20
    }
    Item {
        id: clickCatcher
        objectName: "statusDismissCatcher"

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

        x: bar.geometry.inset
        y: bar.barY
        width: bar.geometry.width
        height: 48
        z: 9
        color: MagiTheme.Theme.barBackground
    }

    // ---------------------------------------------------------
    // Left section
    // ---------------------------------------------------------

    Row {
        id: leftSection
        opacity: bar.geometry.width >= implicitWidth + statusSurface.collapsedWidth + 3 * MagiTheme.Theme.barEdgeMargin ? 1 : 0
        enabled: opacity > 0

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
        opacity: bar.geometry.width >= 2 * Math.max(leftSection.implicitWidth, statusSurface.collapsedWidth) + implicitWidth + 4 * MagiTheme.Theme.barEdgeMargin ? 1 : 0
        enabled: opacity > 0

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
        x: Math.max(0, bar.width - bar.geometry.inset - MagiTheme.Theme.barEdgeMargin - width)
        y: bar.bottomBar ? bar.barY + (48 + MagiTheme.Theme.barPillHeight) / 2 - height
            : bar.barY + (48 - MagiTheme.Theme.barPillHeight) / 2
        transformOrigin: Item.TopRight
        scale: phase === 0 ? Math.min(1, Math.max(0, bar.geometry.width - 2 * MagiTheme.Theme.barEdgeMargin) / Math.max(1, collapsedWidth)) : 1
        bottomUp: bar.bottomBar
        presentationEnabled: bar.ownsMenu
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
                readonly property real expandedStatusWidth: itemWidths + Math.max(0, visibleItems - 1) * 4
                spacing: MagiTheme.Theme.barSectionSpacing + (4 - MagiTheme.Theme.barSectionSpacing) * statusSurface.expansion
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
