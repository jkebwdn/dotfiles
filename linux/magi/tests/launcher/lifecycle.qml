import QtQuick
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/launcher" as UI
ShellRoot {
    id: root
    property int step: -1
    FloatingWindow {
        visible: true; implicitWidth: 720; implicitHeight: 640
        Loader {
            id: content; anchors.fill: parent
            sourceComponent: UI.LauncherContent { service: Services.Launcher }
        }
    }
    Process {
        running: true
        command: ["python3", "-c", "from pathlib import Path; import sys; print(int(Path(sys.argv[1]).exists()))", Quickshell.env("MAGI_LIFECYCLE_RELOADED")]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "1") {
                    console.log("LIFECYCLE_RELOADED")
                    finish.start()
                } else root.step = 0
            }
        }
    }
    Timer {
        interval: 100; running: root.step >= 0; repeat: true
        onTriggered: {
            if (!Services.Settings.ready) return
            if (root.step === 0) {
                Services.Launcher.open(); root.step = 1
            } else if (root.step === 1 && Services.Launcher.results.length > 0) {
                Services.Launcher.launch(0); root.step = 2
            } else if (root.step === 2 && !Services.Launcher.busy) {
                if (Services.Launcher.error || Services.Hub.opened || Services.Launcher.opened)
                    throw new Error("Launch did not succeed and close Hub")
                content.active = false
                console.log("LIFECYCLE_UI_DESTROYED")
                root.step = -1; reloadDelay.start()
            }
        }
    }
    Timer { id: reloadDelay; interval: 1500; onTriggered: markReload.running = true }
    Process {
        id: markReload
        command: ["python3", "-c", "from pathlib import Path; import sys; Path(sys.argv[1]).touch()", Quickshell.env("MAGI_LIFECYCLE_RELOADED")]
        onExited: (code, status) => {
            if (code !== 0) throw new Error("Could not mark reload")
            Quickshell.reload(true)
        }
    }
    Timer { id: finish; interval: 500; onTriggered: Qt.quit() }
}
