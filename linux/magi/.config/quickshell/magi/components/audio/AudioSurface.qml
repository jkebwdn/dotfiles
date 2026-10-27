pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
Flickable {
    id: root
    required property var audioService
    contentWidth: width; contentHeight: content.implicitHeight
    clip: true; boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
    Column {
        id: content
        width: root.width - 10
        spacing: 16
        Column {
            width: parent.width; spacing: 8
            Text { text: "Output"; color: Theme.Theme.subtext; font.pixelSize: 12 }
            AudioDeviceSelector {
                audioService: root.audioService
                objectName: "audioOutputSelector"
                sources: root.audioService.outputs; selected: root.audioService.sink
                Accessible.name: "Output device"
                displayText: currentIndex >= 0 ? currentText : "No output available"
                onActivated: index => root.audioService.selectOutput(sources[index])
            }
            AudioLevel { audioService: root.audioService; node: root.audioService.sink; label: "Output volume"; showLabel: false }
        }
        Column {
            visible: root.audioService.inputs.length > 0
            width: parent.width; spacing: 8
            Text { text: "Input"; color: Theme.Theme.subtext; font.pixelSize: 12 }
            AudioDeviceSelector {
                audioService: root.audioService
                objectName: "audioInputSelector"
                sources: root.audioService.inputs; selected: root.audioService.source
                Accessible.name: "Input device"
                displayText: currentIndex >= 0 ? currentText : "Select input"
                onActivated: index => root.audioService.selectInput(sources[index])
            }
            AudioLevel { audioService: root.audioService; node: root.audioService.source; label: "Input volume"; showLabel: false }
        }
        Text {
            width: parent.width; visible: text.length > 0; text: root.audioService.error
            color: Theme.Theme.warning; font.pixelSize: 11; wrapMode: Text.WordWrap; textFormat: Text.PlainText
        }
        Rectangle { visible: root.audioService.applications.length > 0; width: parent.width; height: 1; color: Theme.Theme.border }
        Column {
            visible: root.audioService.applications.length > 0
            width: parent.width; spacing: 12
            Text { text: "Applications"; color: Theme.Theme.subtext; font.pixelSize: 12 }
            Repeater {
                objectName: "audioApplications"
                model: root.audioService.applications
                delegate: AudioLevel {
                    required property var modelData
                    audioService: root.audioService
                    group: modelData
                    node: modelData.nodes[0] || null
                    label: modelData.label
                    application: true
                }
            }
        }
    }
}
