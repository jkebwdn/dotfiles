pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire
AudioModel {
    id: root
    // Final Phase14B native acceptance reload: routing remains user-initiated.
    sourceNodes: Pipewire.nodes.values
    sink: Pipewire.defaultAudioSink
    source: Pipewire.defaultAudioSource
    // Routing writes occur only for explicit user selection, never initialization.
    // Application groups are presentation state; stream writes require user input.
    onOutputRequested: node => { Pipewire.preferredDefaultAudioSink = node }
    onInputRequested: node => { Pipewire.preferredDefaultAudioSource = node }
    // Properties and controls are valid only while bound. This tracks audio
    // metadata/controls, never samples audio or instantiates a peak monitor.
    property PwObjectTracker tracker: PwObjectTracker {
        objects: root.sourceNodes.filter(n => n && n.audio)
    }
}
