
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink

    readonly property bool available: sink !== null
                                      && sink.ready
                                      && sink.audio !== null

    readonly property real volume: available
                                   ? sink.audio.volume
                                   : 0

    readonly property bool muted: available
                                  ? sink.audio.muted
                                  : false

    readonly property int volumePercent: Math.round(volume * 100)

    PwObjectTracker {
        objects: root.sink !== null ? [root.sink] : []
    }

    function toggleMute() {
        if (!available)
            return

        sink.audio.muted = !sink.audio.muted
    }

    
    function adjustVolume(steps) {
        if (!available)
            return

        const step = 0.05
        const nextVolume = Math.max(
            0,
            Math.min(1, volume + steps * step)
    )

    sink.audio.volume = Math.round(nextVolume * 100) / 100
    }

}
