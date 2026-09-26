
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland

import "../../plugins/bar/clock" as ClockPlugin
import "../../plugins/bar/date" as DatePlugin
import "../../plugins/bar/workspaces" as WorkspacePlugin
import "../../plugins/bar/wifi" as WifiPlugin
import "../../plugins/bar/volume" as VolumePlugin
import "../../plugins/bar/battery" as BatteryPlugin
import "../../plugins/bar/bluetooth" as BluetoothPlugin
import "../../plugins/bar/controlcentre" as ControlCentrePlugin
import "../../services" as MagiServices
import "../../theme" as MagiTheme

PanelWindow {
    id: bar

    // Set to "anchored" to retain the native 48px bar and PopupWindow host.
    property string expandableHostMode: "anchored"

    property var expandablePillRegistry: ({})

    readonly property bool combinedMode:
        expandableHostMode === "combined"
    readonly property var activeExpandablePill: {
        if (!combinedMode || MagiServices.MenuController.activeMenu === "")
            return null

        return expandablePillRegistry[
            MagiServices.MenuController.activeMenu
        ] || null
    }
    readonly property bool combinedMenuActive:
        activeExpandablePill !== null
        && activeExpandablePill.hostMode === "combined"
    readonly property Item activeCombinedRegion:
        combinedMode && statusSurface.revealedHeight > 0 ? statusSurface : null
    readonly property bool catcherEnabled: combinedMenuActive
    readonly property bool combinedKeyboardEnabled:
        combinedMenuActive && activeExpandablePill.menuKeyboardFocus

    function registerExpandablePill(menuId, pill) {
        if (menuId === "" || !pill)
            return

        const next = Object.assign({}, expandablePillRegistry)
        next[menuId] = pill
        expandablePillRegistry = next
    }

    function unregisterExpandablePill(menuId, pill) {
        if (expandablePillRegistry[menuId] !== pill)
            return

        const next = Object.assign({}, expandablePillRegistry)
        delete next[menuId]
        expandablePillRegistry = next
    }

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

    readonly property var leftPlugins:
        MagiServices.Settings.barLeftPlugins

    readonly property var centerPlugins:
        MagiServices.Settings.barCenterPlugins

    readonly property var rightPlugins:
        MagiServices.Settings.barRightPlugins

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

        WifiPlugin.Wifi {
            barWindow: bar
            menuCoordinator: bar
            hostMode: bar.expandableHostMode
            sharedSurface: bar.combinedMode ? statusSurface : null
        }
    }

    Component {
        id: volumeComponent

        VolumePlugin.Volume {
            barWindow: bar
            menuCoordinator: bar
            hostMode: bar.expandableHostMode
            sharedSurface: bar.combinedMode ? statusSurface : null
        }
    }

    Component {
        id: batteryComponent

        BatteryPlugin.Battery {
            sharedExpansion: bar.combinedMode ? statusSurface.expansion : 0
        }
    }

    Component {
        id: bluetoothComponent

        BluetoothPlugin.Bluetooth {
            barWindow: bar
            menuCoordinator: bar
            hostMode: bar.expandableHostMode
            sharedSurface: bar.combinedMode ? statusSurface : null
        }
    }

    Component {
        id: controlCentreComponent

        ControlCentrePlugin.ControlCentre {
            barWindow: bar
            menuCoordinator: bar
            hostMode: bar.expandableHostMode
            sharedSurface: bar.combinedMode ? statusSurface : null
        }
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
                readonly property var pluginItem: item

                sourceComponent: bar.pluginComponents[modelData]
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
                readonly property var pluginItem: item

                sourceComponent: bar.pluginComponents[modelData]
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
                        readonly property var pluginItem: item
                        sourceComponent: bar.pluginComponents[modelData]
                        visible: !pluginItem
                                || pluginItem["barVisible"] === undefined
                            ? true : pluginItem["barVisible"]
                    }
                }
            }
        }
    }
}
