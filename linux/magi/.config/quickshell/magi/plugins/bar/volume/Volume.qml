pragma ComponentBehavior: Bound

import QtQuick
import "../../../icons" as Icons

import "../../../components/bar" as MagiBar
import "../../../components/controls" as MagiControls
import "../../../services" as MagiServices
import "../../../theme" as MagiTheme

MagiBar.ExpandableModule {
    id: root

    readonly property int volume: MagiServices.Audio.volumePercent
    readonly property bool muted: MagiServices.Audio.muted
    readonly property bool available: MagiServices.Audio.available

    readonly property string volumeIcon: Icons.IconRegistry.volumeRole(available, muted, volume)

    menuId: "volume"
    icon: volumeIcon
    title: "Volume"
    collapsedWidth: 30
    expandedWidth: 280
    menuHeight: 100
    color: sharedSurface
        ? Qt.alpha(MagiTheme.Theme.surface, 1 - sharedSurface.expansion)
        : MagiTheme.Theme.surface

    pillContent: Component {
        MagiControls.MorphingPillContent {
            pill: parent
            moduleId: "volume"
            icon: root.volumeIcon
            collapsedText: ""
            expandedTitle: "Volume"
            expandedStatus: root.muted ? "Muted" : root.volume + "%"
            iconColor: root.muted
                ? MagiTheme.Theme.warning
                : MagiTheme.Theme.text
            statusColor: root.muted
                ? MagiTheme.Theme.warning
                : MagiTheme.Theme.muted
        }
    }

    menuContent: Component {
        Column {
            width: parent ? parent.width : 0
            spacing: 8

            Item {
                width: parent.width
                height: 26

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.available
                        ? root.muted ? "Output muted" : "Default output"
                        : "Audio unavailable"
                    color: root.muted
                        ? MagiTheme.Theme.warning
                        : MagiTheme.Theme.muted
                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 9
                }

                MagiControls.ActionChip {
                    moduleId: "volume"
                    id: muteButton

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    width: 30
                    icon: root.muted ? "volume-muted" : "volume"
                    active: root.muted
                    activeColor: MagiTheme.Theme.warning
                    available: root.available
                    onTriggered: MagiServices.Audio.toggleMute()
                }
            }

            Rectangle {
                width: parent.width
                height: 48
                radius: MagiTheme.Theme.radiusMedium
                color: MagiTheme.Theme.background

                MagiControls.Icon {
                    id: lowVolumeIcon

                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    role: "volume-low"
                    moduleId: "volume"
                    color: MagiTheme.Theme.muted
                    size: 12
                }

                MagiControls.ValueSlider {
                    anchors {
                        left: lowVolumeIcon.right
                        leftMargin: 10
                        right: highVolumeIcon.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    value: MagiServices.Audio.volume
                    interactive: root.available
                    fillColor: root.muted
                        ? MagiTheme.Theme.muted
                        : MagiTheme.Theme.accent
                    trackColor: MagiTheme.Theme.elevated
                    onValueMoved: value =>
                        MagiServices.Audio.setVolume(value)
                }

                MagiControls.Icon {
                    id: highVolumeIcon

                    anchors {
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    role: "volume"
                    moduleId: "volume"
                    color: MagiTheme.Theme.muted
                    size: 12
                }
            }
        }
    }
}
