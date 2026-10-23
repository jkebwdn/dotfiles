pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".." as SettingsUI
import "../../../services" as Services
SettingsUI.SettingsPage {
    id: root
    title: "Power & Idle"
    description: "Choose what happens when your computer is idle."
    property var draft: ({lockAfter:300, displayOffAfter:600, suspendAfter:0})
    readonly property var durations: [0,60,120,300,600,900,1800,3600]
    readonly property var suspendDurations: [0,300,600,900,1800,3600,7200]
    readonly property var enabledTimers: [draft.lockAfter,draft.displayOffAfter,draft.suspendAfter].filter(v => v > 0)
    readonly property bool validOrder: !enabledTimers.some((v,i) => i > 0 && v < enabledTimers[i-1])
    readonly property bool changed: ["lockAfter","displayOffAfter","suspendAfter"].some(k => draft[k] !== Services.Settings.data.powerIdle[k])
    function label(seconds) {
        return seconds === 0 ? "Never" : seconds === 60 ? "1 minute"
            : seconds < 3600 ? (seconds/60) + " minutes" : seconds === 3600 ? "1 hour" : "2 hours"
    }
    function resetDraft() { draft = Object.assign({}, Services.Settings.data.powerIdle) }
    Component.onCompleted: resetDraft()
    Connections { target: Services.Settings; function onDataChanged() { root.resetDraft() } }
    Repeater {
        model: [{key:"lockAfter",label:"Lock after"}, {key:"displayOffAfter",label:"Display off after"}, {key:"suspendAfter",label:"Suspend after"}]
        SettingsUI.SettingsRow {
            required property var modelData
            Label { text: parent.modelData.label; Layout.fillWidth: true }
            SettingsUI.SettingsSelector {
                readonly property string policyKey: parent.modelData.key
                readonly property var choices: policyKey === "suspendAfter" ? root.suspendDurations : root.durations
                objectName: "powerIdle-" + policyKey
                model: choices.map(root.label)
                currentIndex: choices.indexOf(root.draft[policyKey])
                onActivated: root.draft = Object.assign({}, root.draft, {[policyKey]: choices[currentIndex]})
            }
        }
    }
    SettingsUI.SettingsHelp { text: "Locks before sleep. “Never” disables only the selected timer." }
    SettingsUI.SettingsHelp {
        visible: !root.validOrder
        text: "Enabled timers must run in order: lock, display off, then suspend."
    }
    RowLayout {
        SettingsUI.SettingsButton {
            objectName: "powerIdle-apply"
            primary: true; text: "Apply"
            enabled: Services.Settings.ready && root.validOrder && Services.Settings.saveState !== "pending"
            onClicked: Services.Settings.setPowerIdle(root.draft)
        }
        SettingsUI.SettingsButton { text: "Cancel"; flat: true; enabled: root.changed; onClicked: root.resetDraft() }
    }
}
