import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as UI
import "../../lockPresentation/LockLayout.js" as Model
UI.SettingsPage {
    id: root
    title: "Lock Screen"
    description: "Arrange your lock screen. This preview never locks your session."
    maximumBodyWidth: 1100
    readonly property var layout: Model.normalize(Services.Settings.data.lockScreen)
    property string selected: "time"
    property int previewState: 0
    property int aspectIndex: 0
    property bool depthPreview: false
    readonly property real aspect: aspectIndex===0 ? Math.max(.5,Screen.width/Math.max(1,Screen.height)) : [16/9,16/9,16/10,21/9][aspectIndex]
    readonly property var colors: ({background:Theme.Theme.background.toString(),surface:Theme.Theme.surface.toString(),text:Theme.Theme.text.toString(),subtext:Theme.Theme.subtext.toString(),accent:Theme.Theme.accent.toString(),danger:Theme.Theme.red.toString(),warning:Theme.Theme.yellow.toString()})
    function save(value) { Services.Settings.setLockLayout(value) }
    function effect(key,value) {
        const next=Model.copy(root.layout);next.effects[key]=value;root.save(next)
    }
    function edit(key,value) {
        canvas.begin()
        const next=Model.copy(canvas.draft)
        next.elements[selected][key]=value
        canvas.cancel();save(next)
    }
    Flow {
        Layout.fillWidth: true; Layout.preferredHeight: childrenRect.height; spacing: 8
        Repeater {
            model: ["centered","editorial","corner","split","minimal"]
            UI.SettingsChoiceCard {
                id: presetCard
                required property string modelData
                width: 124; height: 100; text: modelData.charAt(0).toUpperCase()+modelData.slice(1)
                selected: root.layout.preset===modelData
                onClicked: root.save(Model.preset(modelData))
                UI.LockLayoutCanvas { anchors.fill: parent; layout:Model.preset(presetCard.modelData); palette:root.colors;interactive:false }
            }
        }
    }
    Flow {
        Layout.fillWidth:true;Layout.preferredHeight:childrenRect.height;spacing:8
        UI.SettingsSelector {
            model:["Idle","Typing","Authenticating","Wrong password","Caps Lock","Preview weather","Preview media","Preview both"]
            currentIndex:root.previewState;Accessible.name:"Synthetic preview state"
            onActivated:root.previewState=currentIndex
        }
        UI.SettingsSelector {
            model:["Current display","16:9","16:10","Ultrawide"]
            currentIndex:root.aspectIndex;Accessible.name:"Preview aspect ratio"
            onActivated:root.aspectIndex=currentIndex
        }
    }
    GridLayout {
        Layout.fillWidth:true;columns:width>=790 ? 2 : 1;columnSpacing:20;rowSpacing:16
        ColumnLayout {
            Layout.fillWidth:true;Layout.minimumWidth:240;Layout.preferredWidth:700;Layout.alignment:Qt.AlignTop
            UI.LockLayoutCanvas {
                id:canvas;objectName:"lockLayoutCanvas"
                Layout.fillWidth:true;Layout.preferredHeight:width/root.aspect
                layout:root.layout;palette:root.colors;aspect:root.aspect;stateIndex:root.previewState;depthPreview:root.depthPreview
                selected:root.selected
                onSelectionRequested:id=>root.selected=id
                onCommitted:value=>root.save(value)
            }
            UI.SettingsHelp {text:"Drag to arrange · arrows to nudge · Shift for larger steps · Alt to ignore guides · Escape to cancel"}
        }
        ColumnLayout {
            Layout.fillWidth:true;Layout.preferredWidth:230;Layout.maximumWidth:330;Layout.alignment:Qt.AlignTop;spacing:10
            Label {color:Theme.Theme.text;text:root.layout.preset==="custom" ? "Custom layout" : "Selected element";font.bold:true}
            UI.SettingsSelector {
                model:["Time · clock & date","Identity · avatar & name","Authentication","Weather","Media"]
                currentIndex:Model.ids().indexOf(root.selected);Accessible.name:"Select lock screen element"
                onActivated:root.selected=Model.ids()[currentIndex]
            }
            Label {color:Theme.Theme.text;text:"Size"}
            UI.SettingsSelector {
                readonly property var sizes: root.selected==="authentication" ? [1,1.15,1.25] : [.75,1,1.15,1.25]
                model:root.selected==="authentication" ? ["Standard","Large","Hero"] : ["Compact","Standard","Large","Hero"]
                currentIndex:sizes.indexOf(root.layout.elements[root.selected].size)
                Accessible.name:"Selected element size"
                onActivated:root.edit("size",sizes[currentIndex])
            }
            UI.SettingsSelector {
                visible:root.selected==="time";model:["Left","Center","Right"]
                currentIndex:["left","center","right"].indexOf(root.layout.elements.time.alignment)
                Accessible.name:"Time alignment"
                onActivated:root.edit("alignment",["left","center","right"][currentIndex])
            }
            UI.SettingsToggle {
                text:root.selected==="media" ? "Show media information" : root.selected==="weather" ? "Show weather" : "Show element";enabled:root.selected!=="authentication"
                checked:root.layout.elements[root.selected].visible
                onClicked:root.edit("visible",checked)
            }
            UI.SettingsButton {
                text:root.layout.elements[root.selected].z===0 ? "Bring forward" : "Send backward"
                enabled:root.selected!=="authentication"
                onClicked:{
                    const next=Model.copy(root.layout), others=Model.ids().filter(id=>id!=="authentication" && id!==root.selected), other=others.find(id=>next.elements[id].z===(next.elements[root.selected].z<1 ? next.elements[root.selected].z+1 : -2))
                    const z=next.elements[other].z;next.elements[other].z=next.elements[root.selected].z;next.elements[root.selected].z=z
                    next.preset="custom";root.save(next)
                }
            }
            UI.SettingsHelp {text:root.selected==="authentication" ? "Dots, status and Caps Lock stay together, visible and in front." : "Hidden elements remain available in the element selector."}
            Flow {
                Layout.fillWidth:true;Layout.preferredHeight:childrenRect.height;spacing:6
                Repeater {
                    model:root.selected==="authentication" ? ["dots","line","segments","ring","minimal"] : root.selected==="identity" ? ["plain","ring","glow","frame"] : root.selected==="weather" ? ["compact","standard","minimal"] : root.selected==="media" ? ["compact","artwork","minimal"] : []
                    UI.SettingsChoiceCard {
                        id:styleCard
                        required property string modelData
                        readonly property string effectKey:root.selected==="authentication" ? "credential" : root.selected==="identity" ? "avatar" : root.selected
                        width:100;height:100;text:modelData.charAt(0).toUpperCase()+modelData.slice(1)
                        selected:root.layout.effects[effectKey]===modelData
                        onClicked:root.effect(effectKey,modelData)
                        UI.LockStylePreview {anchors.fill:parent;kind:styleCard.effectKey;choice:styleCard.modelData;palette:root.colors}
                    }
                }
            }
            UI.SettingsToggle {visible:root.selected==="weather";text:"Show city label";checked:root.layout.effects.location;onClicked:root.effect("location",checked)}
            UI.SettingsToggle {visible:root.selected==="media";text:"Show artwork";checked:root.layout.effects.artwork;onClicked:root.effect("artwork",checked)}
            UI.SettingsHelp {visible:root.selected==="media";text:"Opt in to showing track information while locked. Read-only; cached data may be older than the current track."}
            UI.SettingsHelp {visible:root.selected==="weather";text:"Uses Profile weather settings and cached observations. Preview content is synthetic."}
            UI.SettingsToggle {text:"Depth effect";enabled:false;checked:root.layout.effects.depth}
            UI.SettingsToggle {text:"Preview depth effect";checked:root.depthPreview;onClicked:root.depthPreview=checked}
            UI.SettingsHelp {text:"Depth is unavailable until this wallpaper has a prepared subject cutout. Try the synthetic preview to see the effect."}
            UI.SettingsSection {
                title:"Fine tune";collapsible:true
                UI.SettingsSelector {
                    model:Model.anchors();Accessible.name:"Position anchor"
                    currentIndex:Model.anchors().indexOf(root.layout.elements[root.selected].anchor)
                    onActivated:root.edit("anchor",model[currentIndex])
                }
                Label {color:Theme.Theme.text;text:"Horizontal offset (%)"}
                UI.SettingsNumber {from:-100;to:100;value:Math.round(root.layout.elements[root.selected].offsetX*100);Accessible.name:"Horizontal offset";onValueModified:root.edit("offsetX",value/100)}
                Label {color:Theme.Theme.text;text:"Vertical offset (%)"}
                UI.SettingsNumber {from:-100;to:100;value:Math.round(root.layout.elements[root.selected].offsetY*100);Accessible.name:"Vertical offset";onValueModified:root.edit("offsetY",value/100)}
            }
        }
    }
    UI.SettingsButton {text:"Reset lock screen";flat:true;onClicked:Services.Settings.resetSection("lockScreen")}
}
