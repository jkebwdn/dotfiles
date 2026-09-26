pragma ComponentBehavior: Bound

import QtQuick

import "../../../components/bar" as MagiBar
import "../../../components/controls" as MagiControls
import "../../../services" as MagiServices
import "../../../theme" as MagiTheme

MagiBar.ExpandablePlugin {
    id: root

    menuId: "controlcentre"
    icon: "󰒓"
    title: "Control Centre"
    collapsedWidth: 30
    expandedWidth: MagiTheme.RenderTokens.controlWidth
    menuHeight: MagiTheme.RenderTokens.controlBodyHeight
    viewPadding: MagiTheme.RenderTokens.padding
    viewBottomPadding: MagiTheme.RenderTokens.padding
    viewRadius: MagiTheme.RenderTokens.outerRadius
    viewSurfaceColor: MagiTheme.RenderTokens.surface
    color: sharedSurface
        ? Qt.alpha(MagiTheme.Theme.surface, 1 - sharedSurface.expansion)
        : MagiTheme.Theme.surface

    readonly property string volumeIcon: {
        if (!MagiServices.Audio.available
                || MagiServices.Audio.muted
                || MagiServices.Audio.volumePercent === 0) {
            return "󰖁"
        }
        if (MagiServices.Audio.volumePercent < 34)
            return "󰕿"
        if (MagiServices.Audio.volumePercent < 67)
            return "󰖀"
        return "󰕾"
    }

    pillContent: Component {
        MagiControls.MorphingPillContent {
            pill: parent
            icon: root.icon
            expandedTitle: "Control Centre"
            expandedStatus: MagiServices.Battery.available
                ? MagiServices.Battery.percentage + "%"
                : ""
            iconColor: MagiTheme.Theme.text
        }
    }

    menuContent: Component {
        Column {
            width: parent ? parent.width : 0

            Grid {
                width: parent.width
                columns: 4
                spacing: Math.max(0,
                    (width - 4 * MagiTheme.RenderTokens.tileSize) / 3)

                ControlTile {
                    icon: MagiServices.Network.icon
                    title: "Wi-Fi"
                    subtitle: MagiServices.Network.connected
                        ? MagiServices.Network.ssid
                        : MagiServices.Network.wifiEnabled ? "On" : "Off"
                    active: MagiServices.Network.wifiEnabled
                    activeColor: MagiTheme.RenderTokens.wifi
                    rimColor: MagiTheme.RenderTokens.wifiRim
                    available: MagiServices.Network.wifiHardwareEnabled
                    onPrimaryTriggered:
                        MagiServices.Network.setWifiEnabled(
                            !MagiServices.Network.wifiEnabled)
                    onSecondaryTriggered:
                        MagiServices.MenuController.navigate("wifi")
                }

                ControlTile {
                    icon: MagiServices.Battery.icon
                    title: "Power"
                    subtitle: MagiServices.Battery.available
                        ? MagiServices.Battery.percentage + "%" : "Unknown"
                    active: MagiServices.Battery.available
                    activeColor: MagiTheme.RenderTokens.power
                    rimColor: MagiTheme.RenderTokens.powerRim
                    available: MagiServices.Battery.available
                    interactive: false
                }

                ControlTile {
                    icon: root.volumeIcon
                    title: "Sound"
                    subtitle: MagiServices.Audio.muted
                        ? "Muted" : MagiServices.Audio.volumePercent + "%"
                    active: MagiServices.Audio.available && !MagiServices.Audio.muted
                    activeColor: MagiTheme.RenderTokens.sound
                    rimColor: MagiTheme.RenderTokens.soundRim
                    available: MagiServices.Audio.available
                    onPrimaryTriggered: MagiServices.Audio.toggleMute()
                }

                ControlTile {
                    icon: MagiServices.Bluetooth.enabled ? "󰂯" : "󰂲"
                    title: "Bluetooth"
                    subtitle: !MagiServices.Bluetooth.enabled ? "Off"
                        : MagiServices.Bluetooth.connectedCount > 0
                            ? MagiServices.Bluetooth.connectedCount + " linked" : "On"
                    active: MagiServices.Bluetooth.enabled
                    activeColor: MagiTheme.RenderTokens.bluetooth
                    rimColor: MagiTheme.RenderTokens.bluetoothRim
                    available: MagiServices.Bluetooth.available
                    onPrimaryTriggered:
                        MagiServices.Bluetooth.setEnabled(!MagiServices.Bluetooth.enabled)
                    onSecondaryTriggered:
                        MagiServices.MenuController.navigate("bluetooth")
                }
            }

            Item { width: 1; height: MagiTheme.RenderTokens.tileSliderGap }

            Row {
                width: parent.width
                spacing: MagiTheme.RenderTokens.sliderGap
                MagiControls.IconSlider {
                    width: (parent.width - parent.spacing) / 2
                    icon: root.volumeIcon
                    value: MagiServices.Audio.volume
                    interactive: MagiServices.Audio.available
                    onValueMoved: value => MagiServices.Audio.setVolume(value)
                }
                MagiControls.IconSlider {
                    width: (parent.width - parent.spacing) / 2
                    icon: "󰃟"
                    value: MagiServices.Brightness.percent / 100
                    interactive: MagiServices.Brightness.available
                    onValueMoved: value =>
                        MagiServices.Brightness.setPercent(value * 100)
                }
            }

            Item { width: 1; height: MagiTheme.RenderTokens.powerGap }

            // Existing read-only power information, without an invented action
            // strip or a placeholder for the render's unimplemented media module.
            Item {
                width: parent.width
                height: MagiTheme.RenderTokens.powerHeight
                Text {
                    id: powerIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: MagiServices.Battery.icon
                    color: MagiTheme.RenderTokens.foreground
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 24
                }
                Text {
                    anchors.left: powerIcon.right
                    anchors.leftMargin: 10
                    anchors.right: remainingTime.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: MagiServices.Battery.stateText
                    color: MagiTheme.RenderTokens.secondary
                    font.family: MagiTheme.RenderTokens.textFamily
                    font.pixelSize: MagiTheme.RenderTokens.secondarySize
                    elide: Text.ElideRight
                }
                Text {
                    id: remainingTime
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: MagiServices.Battery.timeText !== ""
                        ? MagiServices.Battery.timeText
                        : MagiServices.Battery.available
                            ? MagiServices.Battery.percentage + "%" : "Unavailable"
                    color: MagiTheme.RenderTokens.secondary
                    font.family: MagiTheme.RenderTokens.textFamily
                    font.pixelSize: MagiTheme.RenderTokens.secondarySize
                }
            }
        }
    }
}
