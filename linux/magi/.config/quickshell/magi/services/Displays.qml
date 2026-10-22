pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Scope {
    id: root
    property bool active: false
    property var state: ({proposed:[],observed:[],profiles:[],warnings:[],profileErrors:[],transaction:{state:"idle"},fixtures:[],selected:"",error:"",validation:"",remaining:0})
    readonly property var selected: state.proposed.find(o => o.name === state.selected) || null
    function send(request) { if (worker.running) worker.write(JSON.stringify(request) + "\n") }
    Process {
        id: worker
        running: root.active
        command: ["python3", Qt.resolvedUrl("../displays/backend.py").toString().replace(/^file:\/\//, "")]
        stdinEnabled: true
        stdout: SplitParser { onRead: data => { try { root.state = JSON.parse(data) } catch(e) { console.warn("Invalid display preview response") } } }
    }
}
