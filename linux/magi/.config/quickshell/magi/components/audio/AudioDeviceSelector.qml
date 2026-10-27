pragma ComponentBehavior: Bound
import QtQuick
import "../settings" as SettingsUI
SettingsUI.SettingsSelector {
    id: root
    required property var audioService
    required property var sources
    required property var selected
    width: parent.width
    enabled: sources.length > 0
    model: sources.map(node => {
        const detail = root.audioService.detail(node, sources)
        return root.audioService.name(node) + (detail ? " · " + detail : "")
    })
    currentIndex: sources.indexOf(selected)
}
