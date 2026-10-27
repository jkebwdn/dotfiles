pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../controls" as Controls
import "../../theme" as Theme
import "../../icons" as Icons
Column {
    id: root
    required property var audioService
    property var node: null
    property string label: "Volume"
    property bool application: false
    property var group: null
    property bool showLabel: true
    readonly property bool usable: group ? audioService.groupNodes(group).length > 0 : audioService.usable(node)
    readonly property real level: group ? audioService.groupVolume(group) : node && node.audio ? node.audio.volume : 0
    readonly property bool muted: group ? audioService.groupMuted(group) : !!(node && node.audio && node.audio.muted)
    spacing: 5
    width: parent ? parent.width : 300
    Row {
        visible: root.showLabel
        width: parent.width; spacing: 8
        Image {
            id: art
            visible: root.application && status === Image.Ready
            width: visible ? 20 : 0; height: 20
            source: root.application && root.audioService.appIcon(root.node) ? Quickshell.iconPath(root.audioService.appIcon(root.node), true) : ""
            sourceSize.width: 20; sourceSize.height: 20
            fillMode: Image.PreserveAspectFit
        }
        Controls.Icon { visible: root.application && !art.visible; role: "volume"; size: 18 }
        Text {
            width: Math.max(0, parent.width - (root.application ? 28 : 0))
            text: root.label; textFormat: Text.PlainText; elide: Text.ElideRight
            color: Theme.Theme.text; font.pixelSize: 12
        }
    }

    Row {
        width: parent.width; spacing: 8
        Controls.IconSlider {
            objectName: "audioLevel-" + root.label
            width: parent.width
            height: Theme.RenderTokens.sliderHeight
            icon: Icons.IconRegistry.volumeRole(root.usable, root.muted, Math.round(value * 100)); moduleId: "volume"
            iconActionEnabled: true
            iconActionName: (root.muted ? "Unmute " : "Mute ") + root.label
            onIconTriggered: root.group ? root.audioService.toggleGroupMute(root.group) : root.audioService.toggleNodeMute(root.node)
            Accessible.name: root.label + " volume"
            value: root.level
            interactive: root.usable
            onValueMoved: value => root.group ? root.audioService.setGroupVolume(root.group, value) : root.audioService.setNodeVolume(root.node, value)
        }
    }
}
