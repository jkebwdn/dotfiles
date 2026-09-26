pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property int percent: 0
    property int requestedPercent: 0

    function parseState(text) {
        const line = text.trim().split("\n")[0]
        const fields = line.split(",")

        if (fields.length < 4) {
            available = false
            return
        }

        const parsed = parseInt(fields[3].replace("%", ""))
        if (isNaN(parsed)) {
            available = false
            return
        }

        available = true
        percent = Math.max(0, Math.min(100, parsed))
        requestedPercent = percent
    }

    function refresh() {
        if (!queryProcess.running)
            queryProcess.exec(["brightnessctl", "-m"])
    }

    function setPercent(value) {
        if (!available)
            return

        requestedPercent = Math.max(1, Math.min(100, Math.round(value)))
        percent = requestedPercent
        writeTimer.restart()
    }

    Process {
        id: queryProcess

        stdout: StdioCollector {
            onStreamFinished: root.parseState(text)
        }

    }

    Process {
        id: writeProcess
    }

    Timer {
        id: writeTimer

        interval: 60
        onTriggered: {
            if (writeProcess.running) {
                restart()
                return
            }

            writeProcess.exec([
                "brightnessctl",
                "set",
                root.requestedPercent + "%"
            ])
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
