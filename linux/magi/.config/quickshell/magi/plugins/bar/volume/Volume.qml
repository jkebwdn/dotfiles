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
    expandsOnClick: false
    onPrimaryTriggered: MagiServices.Audio.toggleMute()
    onWheelTriggered: steps => MagiServices.Audio.adjustVolume(steps)
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

}
