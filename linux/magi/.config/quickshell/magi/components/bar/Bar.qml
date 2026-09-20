
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

    exclusionMode: ExclusionMode.Auto
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 48
    color: "transparent"

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

    // ---------------------------------------------------------
    // Left section
    // ---------------------------------------------------------

    Row {
        id: leftSection

        anchors {
            left: parent.left
            leftMargin: 16
            verticalCenter: parent.verticalCenter
        }

        spacing: 8

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

        anchors.centerIn: parent

        spacing: 8

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
            right: parent.right
            rightMargin: 16
            verticalCenter: parent.verticalCenter
        }

        spacing: 8

        // -----------------------------------------------------
        // Temporary expandable menu tests
        //
        // Each menu supplies its own content while the shared
        // component handles expansion, positioning and animation.
        // -----------------------------------------------------

        ExpandablePlugin {
            barWindow: bar

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
            barWindow: bar

            menuId: "test-controls"
            icon: "󰍛"
            title: "MAGI · Controls"

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
