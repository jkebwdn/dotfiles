pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Io
import ".." as UI
UI.SettingsPage {
    id: root
    title: "Security"
    description: "Manage fingerprints. Your password always remains available."
    property int fixture: 0
    property string enrollmentState: "idle"
    property int stages: 0
    property var fingers: []
    readonly property bool productionEnabled: true
    property string hostMessage: "Checking fingerprint reader…"
    property bool available: false
    property string selectedFinger: "left-index-finger"
    property bool confirmRemove: false
    readonly property var fingerNames: ["left-thumb","left-index-finger","left-middle-finger","left-ring-finger","left-little-finger","right-thumb","right-index-finger","right-middle-finger","right-ring-finger","right-little-finger"]
    function run(action) {
        if (worker.running || synthetic) return
        confirmRemove=false
        worker.command=["python3",Qt.resolvedUrl("../../../services/fingerprint.py").toString().replace("file://", ""),action]
            .concat(action === "enroll" || action === "remove" ? ["--finger",selectedFinger] : [])
        worker.running=true
    }
    Component.onCompleted: run("status")
    Process {
        id: worker
        stdout: SplitParser {
            onRead: line => {
                if (root.synthetic) return
                try {
                    const result=JSON.parse(line)
                    root.hostMessage=result.message || "Checking…"
                    if (result.fingers !== undefined) root.fingers=result.fingers
                    if (result.state === "available") root.available=true
                    if (result.state === "unavailable") root.available=false
                    root.stages=result.progress || 0
                    root.enrollmentState=result.state
                } catch (_) { root.hostMessage="Fingerprint response unavailable" }
            }
        }
    }
    readonly property bool synthetic: fixture !== 0
    readonly property string reader: fixture === 0 ? (available ? "Available" : "Unavailable") : fixture === 3 ? "Unavailable (synthetic)" : "Available (synthetic)"
    function selectFixture(index) {
        fixture=index; enrollmentState="idle"; stages=0
        fingers=index===1 ? ["right-index-finger"] : []
    }
    function beginEnrollment() { if(synthetic && fixture!==3) {enrollmentState="waiting";stages=0} }
    function stage() { if(enrollmentState==="waiting" || enrollmentState==="scanning") {++stages;enrollmentState="scanning"} }
    function complete() {
        if(enrollmentState!=="waiting" && enrollmentState!=="scanning") return
        if(fingers.indexOf("left-index-finger")>=0) enrollmentState="duplicate"
        else {fingers=fingers.concat(["left-index-finger"]);enrollmentState="complete"}
    }
    UI.SettingsSection {
        title: "Fingerprint"
        UI.SettingsHelp {text:"Touch the sensor when locked to use an enrolled fingerprint, or type your password immediately."}
        UI.SettingsRow {Label {text:"Reader";Layout.fillWidth:true} Label {text:root.reader}}
        UI.SettingsHelp {
            objectName:"fingerprintEnrollmentStatus"
            text:!root.synthetic ? root.hostMessage : root.fixture===3 ? "Enrollment unavailable · use password" : root.fingers.length + " enrolled fingerprint(s) · synthetic metadata only"
        }
    }
    UI.SettingsSection {
        title: "Manage fingerprints"
        visible: !root.synthetic
        Repeater {model:root.fingers;Label {required property string modelData;text:modelData.replace(/-/g," ") + " · Enrolled"}}
        UI.SettingsSelector {
            model:root.fingerNames.map(f=>f.replace(/-/g," "))
            currentIndex:root.fingerNames.indexOf(root.selectedFinger)
            Accessible.name:"Finger to enroll or remove"
            onActivated:{root.selectedFinger=root.fingerNames[currentIndex];root.confirmRemove=false}
        }
        Flow {
            Layout.fillWidth:true;Layout.preferredHeight:childrenRect.height;spacing:8
            UI.SettingsButton {objectName:"fingerprintRefresh";text:"Refresh";enabled:!worker.running;onClicked:root.run("status")}
            UI.SettingsButton {objectName:"fingerprintEnroll";text:"Enroll";enabled:root.available && !worker.running && !root.fingers.includes(root.selectedFinger);onClicked:root.run("enroll")}
            UI.SettingsButton {objectName:"fingerprintTest";text:"Test fingerprint";enabled:root.available && !worker.running && root.fingers.length>0;onClicked:root.run("verify")}
            UI.SettingsButton {objectName:"fingerprintRemove";text:root.confirmRemove ? "Confirm removal" : "Remove selected print";enabled:root.available && !worker.running && root.fingers.includes(root.selectedFinger);onClicked:{if(root.confirmRemove)root.run("remove");else root.confirmRemove=true}}
            UI.SettingsButton {text:"Cancel";visible:worker.running || root.confirmRemove;onClicked:{root.confirmRemove=false;if(worker.running)worker.signal(15)}}
        }
        UI.SettingsHelp {text:root.confirmRemove ? "Remove only the selected finger? Your password and other prints remain available." : "System authorization may be requested. Fingerprints stay with the system fingerprint service."}
    }
    UI.SettingsSection {
        title:"Manage fingerprints · synthetic preview"
        objectName: "fingerprintDemo"
        visible: root.synthetic
        collapsible: true
        UI.SettingsHelp {text:"These disposable examples never contact a sensor or change existing fingerprints. Password entry remains immediately available."}
        UI.SettingsSelector {
            objectName:"fingerprintFixture"
            model:["Host status (not queried)","Reader + existing enrollment","Reader + no enrollment","Reader unavailable"]
            currentIndex:root.fixture
            onActivated:root.selectFixture(currentIndex)
        }
        Repeater {model:root.fingers;Label {required property string modelData;text:modelData + " · Enrolled (synthetic)"}}
        UI.SettingsButton {objectName:"fingerprintAdd";text:"Preview adding left index finger";enabled:root.synthetic && root.fixture!==3;onClicked:root.beginEnrollment()}
        UI.SettingsHelp {objectName:"fingerprintProgress";text:root.enrollmentState==="idle" ? "No enrollment in progress" : root.enrollmentState==="waiting" ? "Touch the sensor · simulation only" : root.enrollmentState==="scanning" ? "Scan in progress · " + root.stages + " stages received (simulation)" : "Synthetic enrollment: " + root.enrollmentState}
        RowLayout {
            UI.SettingsButton {text:"Simulate scan stage";enabled:["waiting","scanning"].indexOf(root.enrollmentState)>=0;onClicked:root.stage()}
            UI.SettingsButton {text:"Simulate completion";enabled:["waiting","scanning"].indexOf(root.enrollmentState)>=0;onClicked:root.complete()}
            UI.SettingsButton {text:"Cancel preview";enabled:["waiting","scanning"].indexOf(root.enrollmentState)>=0;onClicked:root.enrollmentState="cancelled"}
        }
        UI.SettingsHelp {text:"Real enrollment, deletion and verification require the later hardware acceptance flow. No biometric data is stored by MAGI."}
    }
}
