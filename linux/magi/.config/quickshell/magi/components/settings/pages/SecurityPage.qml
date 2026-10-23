pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".." as UI
UI.SettingsPage {
    id: root
    title: "Security"
    description: "Fingerprint groundwork · MAGI Lock remains password-only."
    property int fixture: 0
    property string enrollmentState: "idle"
    property int stages: 0
    property var fingers: []
    readonly property bool productionEnabled: false
    readonly property bool synthetic: fixture !== 0
    readonly property string reader: fixture === 0 ? "Not queried in this session" : fixture === 3 ? "Unavailable (synthetic)" : "Available (synthetic)"
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
        UI.SettingsRow {
            Label {text:"Fingerprint unlock";Layout.fillWidth:true}
            Switch {objectName:"fingerprintEnable";checked:false;enabled:false;Accessible.name:"Fingerprint unlock unavailable until hardware acceptance"}
        }
        UI.SettingsHelp {text:"Framework available · production enablement deferred to Phase 11B. Enrollment does not enable unlock."}
        UI.SettingsRow {Label {text:"Reader";Layout.fillWidth:true} Label {text:root.reader}}
        UI.SettingsHelp {
            objectName:"fingerprintEnrollmentStatus"
            text:!root.synthetic ? "Existing enrollment: unknown. Read-only host audit could not access D-Bus. Existing fingerprints are protected." : root.fixture===3 ? "Enrollment unavailable · use password" : root.fingers.length + " enrolled fingerprint(s) · synthetic metadata only"
        }
    }
    UI.SettingsSection {
        title:"Manage fingerprints · synthetic preview"
        objectName: "fingerprintDemo"
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
