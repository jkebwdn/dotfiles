
import QtQuick

import Quickshell
import Quickshell.Wayland

import "../../plugins/bar/clock" as ClockPlugin
import "../../plugins/bar/date" as DatePlugin
import "../../plugins/bar/workspaces" as WorkspacePlugin
import "../../plugins/bar/wifi" as WifiPlugin
import "../../plugins/bar/volume" as VolumePlugin
import "../../plugins/bar/battery" as BatteryPlugin
import "../../services" as MagiServices

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
        combinedMenuActive && activeExpandablePill.revealedHeight > 0
            ? activeExpandablePill.combinedMenuRegion
            : null
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
        "wifi": wifiComponent,
        "volume": volumeComponent,
        "battery": batteryComponent
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

        WifiPlugin.Wifi {}
    }

    Component {
        id: volumeComponent

        VolumePlugin.Volume {}
    }

    Component {
        id: batteryComponent

        BatteryPlugin.Battery {}
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
            leftMargin: 16
            verticalCenter: barStrip.verticalCenter
        }

        spacing: 8
        z: 10

        Repeater {
            model: bar.leftPlugins

            Loader {
                required property string modelData

                sourceComponent: bar.pluginComponents[modelData]
            }
        }
    }

    // ---------------------------------------------------------
    // Centre section
    // ---------------------------------------------------------

    Row {
        id: centerSection

        anchors.centerIn: barStrip

        spacing: 8
        z: 10

        Repeater {
            model: bar.centerPlugins

            Loader {
                required property string modelData

                sourceComponent: bar.pluginComponents[modelData]
            }
        }
    }

    // ---------------------------------------------------------
    // Right section
    // ---------------------------------------------------------

    Row {
        id: rightSection

        anchors {
            right: barStrip.right
            rightMargin: 16
            verticalCenter: barStrip.verticalCenter
        }

        spacing: 8
        z: 10

        // -----------------------------------------------------
        // Temporary expandable menu tests
        //
        // Each menu supplies its own content while the shared
        // component handles expansion, positioning and animation.
        // -----------------------------------------------------

        ExpandablePlugin {
            barWindow: bar
            menuCoordinator: bar
            hostMode: bar.expandableHostMode

            menuId: "test-settings"
            icon: "󰒓"
            title: "MAGI · Settings"

            menuContent: Component {
                Column {
                    width: parent ? parent.width : 0
                    spacing: 12

                    Text {
                        text: "Settings"

                        color: "#d3c6aa"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 1

                        color: "#d3c6aa"
                        opacity: 0.2
                    }

                    Text {
                        width: parent.width

                        text: "This content belongs to the Settings plugin."

                        color: "#d3c6aa"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        ExpandablePlugin {
            id: controlsMenu

            barWindow: bar
            menuCoordinator: bar
            hostMode: bar.expandableHostMode

            menuId: "test-controls"
            icon: "󰍛"
            title: "MAGI · Controls"

            // M2 API demo: right-click the closed pill to switch between
            // its original icon-only width and a richer compact state.
            property bool wideCollapsed: false

            collapsedWidth: wideCollapsed ? 104 : 28

            pillContent: Component {
                Text {
                    readonly property var pill: parent

                    anchors.centerIn: parent

                    text: pill && pill.phase === 0
                        ? (pill.collapsedWidth > 28
                            ? "󰍛  Controls"
                            : pill.icon)
                        : pill ? pill.title : ""

                    color: "#d3c6aa"
                    font.pixelSize: 12

                    width: pill
                        ? Math.max(0, pill.availableWidth - 12)
                        : 0
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    clip: true
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                enabled: controlsMenu.phase === 0

                onTapped: controlsMenu.wideCollapsed =
                    !controlsMenu.wideCollapsed
            }

            menuContent: Component {
                Column {
                    width: parent ? parent.width : 0
                    spacing: 12

                    Text {
                        text: "Controls"

                        color: "#d3c6aa"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 1

                        color: "#d3c6aa"
                        opacity: 0.2
                    }

                    Text {
                        width: parent.width

                        text: "This content belongs to the Controls plugin."

                        color: "#d3c6aa"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        // -----------------------------------------------------
        // Existing right-hand plugins
        //
        // Wi-Fi, Volume and Battery remain unchanged.
        // -----------------------------------------------------

        Repeater {
            model: bar.rightPlugins

            Loader {
                required property string modelData

                sourceComponent: bar.pluginComponents[modelData]
            }
        }
    }
}
