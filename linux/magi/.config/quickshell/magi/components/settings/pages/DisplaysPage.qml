pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".." as UI
import "../../../services" as Services
import "../../../theme" as Theme
UI.SettingsPage {
    id: root
    title: "Displays"
    description: "Preview only · Hyprmon manages your displays."
    readonly property var state: Services.Displays.state
    readonly property var output: Services.Displays.selected
    readonly property bool pending: state.transaction.state === "pending"
    readonly property var names: state.proposed.map(o=>o.name)
    readonly property var resolutions: output ? [...new Set(output.modes.map(m=>m.width+"×"+m.height))] : []
    readonly property var currentMode: output ? output.modes.find(m=>m.width+"x"+m.height+"@"+(m.refresh/1000)===output.mode) : null
    readonly property var refreshModes: output && currentMode ? output.modes.filter(m=>m.width===currentMode.width && m.height===currentMode.height) : []
    readonly property var mirrors: ["None"].concat(state.proposed.filter(o=>o.enabled && o.name!==state.selected && !o.mirror).map(o=>o.name))
    property int profileIndex: 0
    function edit(key,value) { Services.Displays.send({op:"edit",key:key,value:value}) }
    Component.onCompleted: Services.Displays.active=true
    UI.SettingsRow {
        Label {text:"Preview setup";Layout.fillWidth:true}
        UI.SettingsSelector { model:root.state.fixtures; currentIndex:root.state.fixtures.indexOf(root.state.fixture); enabled:!root.pending; onActivated: Services.Displays.send({op:"fixture",name:currentText}) }
    }
    UI.SettingsButton {text:"Read connected displays";enabled:!root.pending;onClicked:Services.Displays.send({op:"discover"})}
    UI.DisplayCanvas {
        objectName:"displayCanvas"
        Layout.fillWidth:true
        outputs:root.state.proposed
        selected:root.state.selected
        editable:!root.pending
        onSelectOutput:name=>Services.Displays.send({op:"select",name:name})
        onMoveOutput:(name,x,y)=>Services.Displays.send({op:"move",name:name,x:x,y:y})
    }
    UI.SettingsHelp {text:root.state.dirty ? "Unsaved layout · drag displays or use placement buttons below." : "Select a display to edit its preview."}
    UI.SettingsRow {
        Label {text:"Selected display";Layout.fillWidth:true}
        UI.SettingsSelector {model:root.names;currentIndex:root.names.indexOf(root.state.selected);onActivated:Services.Displays.send({op:"select",name:currentText})}
    }
    UI.SettingsRow {
        Label {text:"Display enabled";Layout.fillWidth:true}
        CheckBox {text:"Enabled";checked:root.output ? root.output.enabled : false;enabled:!!root.output && !root.pending;onClicked:root.edit("enabled",checked)}
    }
    UI.SettingsRow {
        Label {text:"Resolution";Layout.fillWidth:true}
        UI.SettingsSelector {
            Accessible.name:"Display resolution"
            model:root.resolutions
            enabled:!!root.output && !root.pending
            currentIndex:root.currentMode ? root.resolutions.indexOf(root.currentMode.width+"×"+root.currentMode.height) : -1
            onActivated: {const m=root.output.modes.find(m=>m.width+"×"+m.height===currentText);root.edit("mode",m.width+"x"+m.height+"@"+(m.refresh/1000))}
        }
    }
    UI.SettingsRow {
        Label {text:"Refresh rate";Layout.fillWidth:true}
        UI.SettingsSelector {
            Accessible.name:"Refresh rate"
            model:root.refreshModes.map(m=>(m.refresh/1000)+" Hz")
            enabled:!!root.output && !root.pending
            currentIndex:root.currentMode ? root.refreshModes.findIndex(m=>m.refresh===root.currentMode.refresh) : -1
            onActivated: {const m=root.refreshModes[currentIndex];root.edit("mode",m.width+"x"+m.height+"@"+(m.refresh/1000))}
        }
    }
    UI.SettingsRow {
        Label {text:"Scale";Layout.fillWidth:true}
        UI.SettingsSelector {property var values:[1,1.25,1.5,1.75,2,2.5,3];model:values.map(String);currentIndex:root.output ? values.indexOf(root.output.scale) : -1;enabled:!!root.output && !root.pending;onActivated:root.edit("scale",values[currentIndex])}
    }
    UI.SettingsRow {
        Label {text:"Rotation";Layout.fillWidth:true}
        UI.SettingsSelector {model:["Landscape","Portrait left","Upside down","Portrait right","Flipped","Flipped 90°","Flipped 180°","Flipped 270°"];currentIndex:root.output ? root.output.transform : 0;enabled:!!root.output && !root.pending;onActivated:root.edit("transform",currentIndex)}
    }
    UI.SettingsRow {
        Label {text:"Mirror";Layout.fillWidth:true}
        UI.SettingsSelector {model:root.mirrors;currentIndex:root.output ? Math.max(0,root.mirrors.indexOf(root.output.mirror || "None")) : 0;enabled:!!root.output && !root.pending;onActivated:root.edit("mirror",currentIndex===0 ? "" : currentText)}
    }
    UI.SettingsRow {
        Label {text:"Place relative to";Layout.fillWidth:true}
        UI.SettingsSelector {id:relative;model:root.names.filter(n=>n!==root.state.selected)}
    }
    RowLayout {
        Layout.fillWidth:true
        Repeater {model:["left","right","above","below"];UI.SettingsButton {required property string modelData;text:({left:"← Left",right:"Right →",above:"↑ Above",below:"↓ Below"})[modelData];Accessible.name:"Place "+modelData;enabled:relative.currentText.length>0 && !root.pending;onClicked:Services.Displays.send({op:"place",target:relative.currentText,direction:modelData})}}
    }
    UI.SettingsHelp {visible:root.state.warnings.length>0;text:root.state.warnings.join("\n")}
    UI.SettingsHelp {visible:!!root.state.error || !!root.state.validation;text:root.state.error || root.state.validation}
    UI.SettingsButton {visible:root.state.warnings.length>0;text:"Acknowledge review";enabled:!root.pending;onClicked:Services.Displays.send({op:"review"})}
    UI.SettingsRow {
        UI.SettingsButton {
            actionKind: "reset";text:"Revert edits";enabled:!root.pending;onClicked:Services.Displays.send({op:"reset"})}
        UI.SettingsButton {objectName:"displayApplyPreview";text:"Apply preview";enabled:!root.pending && !root.state.validation && !root.state.warnings.length;onClicked:Services.Displays.send({op:"apply"})}
        Label {text:"No changes to physical displays";color:Theme.Theme.text;Layout.fillWidth:true;wrapMode:Text.Wrap}
    }
    UI.SettingsHelp {visible:root.pending;text:"Keep this preview layout? Reverting in "+root.state.remaining+" seconds…"}
    UI.SettingsRow {
        visible:root.pending
        UI.SettingsButton {text:"Revert";onClicked:Services.Displays.send({op:"revert",token:root.state.transaction.token})}
        UI.SettingsButton {objectName:"displayKeepPreview";text:"Keep preview";onClicked:Services.Displays.send({op:"keep",token:root.state.transaction.token})}
    }
    UI.SettingsHelp {visible:root.state.transaction.state==="recovery-required";color:Theme.Theme.danger;font.bold:true;text:root.state.transaction.error || "Preview recovery is required."}
    Label {text:"Profiles";font.bold:true;color:Theme.Theme.text}
    UI.SettingsRow {
        UI.SettingsSelector {model:root.state.profiles.map(p=>p.name+" · "+p.matching);currentIndex:root.profileIndex;onActivated:root.profileIndex=currentIndex;Layout.fillWidth:true}
        UI.SettingsButton {text:"Preview";enabled:root.state.profiles.length>root.profileIndex && !root.pending;onClicked:Services.Displays.send({op:"profile",id:root.state.profiles[root.profileIndex].id})}
    }
    UI.SettingsRow {
        TextField {id:profileName;placeholderText:"Profile name";Accessible.name:"Profile name";Layout.fillWidth:true;maximumLength:80}
        UI.SettingsButton {text:"Save as…";enabled:profileName.text.trim().length>0 && !root.pending;onClicked:Services.Displays.send({op:"save",name:profileName.text})}
        UI.SettingsButton {text:"Rename";enabled:root.state.profiles.length>root.profileIndex && profileName.text.trim().length>0;onClicked:Services.Displays.send({op:"rename",id:root.state.profiles[root.profileIndex].id,name:profileName.text})}
        UI.SettingsButton {destructive:true;text:"Delete";enabled:root.state.profiles.length>root.profileIndex;onClicked:Services.Displays.send({op:"delete",id:root.state.profiles[root.profileIndex].id})}
    }
    UI.SettingsHelp {visible:root.state.profileErrors.length>0;text:root.state.profileErrors.join("\n")}
    UI.SettingsButton {text:"Inspect Hyprmon profiles";onClicked:Services.Displays.send({op:"import"})}
    Repeater {
        model:root.state.report || []
        UI.SettingsHelp {required property var modelData;text:modelData.name+": "+((modelData.warnings || []).join("; ") || "Conversion ready for review")+" · source unchanged"}
    }
}
