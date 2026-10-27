pragma ComponentBehavior: Bound

import QtQuick
import "../../../components/audio" as AudioUI
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
    title: "Audio"
    collapsedWidth: 30
    expandedWidth: 370
    property real audioContentHeight: 0
    readonly property real maximumMenuHeight: Math.min(560, barWindow && barWindow.outputScreen ? Math.max(160, barWindow.outputScreen.height - 100) : 560)
    menuHeight: Math.min(maximumMenuHeight, Math.ceil(audioContentHeight + viewTopPadding + viewBottomPadding))
    expandsOnClick: true
    onSecondaryTriggered: MagiServices.Audio.toggleMute()
    onWheelTriggered: steps => MagiServices.Audio.adjustVolume(steps)
    color: sharedSurface
        ? Qt.alpha(MagiTheme.Theme.statusPillBackground, MagiTheme.Theme.statusPillBackground.a * (1 - sharedSurface.expansion))
        : MagiTheme.Theme.statusPillBackground

    pillContent: Component {
        MagiControls.MorphingPillContent {
            pill: parent
            moduleId: "volume"
            icon: root.volumeIcon
            collapsedText: ""
            expandedTitle: ""
            expandedStatus: ""
            iconColor: root.muted
                ? MagiTheme.Theme.warning
                : MagiTheme.Theme.text
            statusColor: root.muted
                ? MagiTheme.Theme.warning
                : MagiTheme.Theme.muted
        }
    }

    menuContent: Component {
        AudioUI.AudioSurface {
            audioService: MagiServices.Audio
            width: parent ? parent.width : 340
            height: Math.max(0, root.menuHeight - root.viewTopPadding - root.viewBottomPadding)
            onContentHeightChanged: root.audioContentHeight = contentHeight
            Component.onCompleted: root.audioContentHeight = contentHeight
        }
    }
}
