import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/components/hub" as Hub
import "../../.config/quickshell/magi/plugins/bar/workspaces" as Workspaces
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as CC
import "../../.config/quickshell/magi/components/lockPresentation" as Lock
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    FloatingWindow {
        visible:true;implicitWidth:1100;implicitHeight:700;color:Theme.Theme.background
        Rectangle {
            id: scene;anchors.fill:parent;color:Theme.Theme.background
            UI.ControlCentrePreview { id:cc; x:16;y:16;width:380;height:640;playing:false }
            Column {
                x:420;y:20;spacing:20
                Rectangle {
                    id:barSample;width:270;height:60;color:Theme.Theme.background
                    Bar.StatusPill {id:pill;x:10;y:16;width:120;height:28;Label{anchors.centerIn:parent;text:"Date & Time";color:Theme.Theme.text}}
                    Workspaces.Workspaces {id:workspaces;x:150;y:16;preview:true}
                }
                UI.SettingsSection { id:card;width:280;title:"Shared surface";UI.SettingsHelp{text:"Card background and border"} }
                Column {
                    id:actionSample;width:280;spacing:12
                    UI.SettingsButton{id:button;text:"Action button";width:240}
                    Controls.CompactToggle{id:toggle;checked:true}
                    UI.SettingsTextField{width:240;text:"Input field"}
                    CC.ActionButton{id:secondary;width:240;height:36;moduleId:"inhibit";icon:"inhibit";label:"Secondary control (focused sample)";toggle:true;active:true}
                }
                Hub.HubSelector {id:hub}
                Controls.ValueSlider {id:slider;width:270;value:.55}
                Controls.RoundedArtwork {id:header;width:270;height:150;source:Qt.resolvedUrl("test-artwork.ppm");radius:Services.Settings.data.launcher.headerRadius;borderWidth:2;placeholder:"image"}
            }
            Column {
                x:750;y:20;spacing:25
                Controls.RoundedArtwork{id:avatar;width:120;height:120;source:Qt.resolvedUrl("square.ppm");radius:Theme.Theme.radius("avatar",10,width,height);borderWidth:3}
                Controls.RoundedArtwork{id:album;width:120;height:120;source:Qt.resolvedUrl("portrait.ppm");radius:Theme.Theme.radius("albumArt",10,width,height);borderWidth:3}
                Item {
                    id:lockSample;width:280;height:170
                    Lock.LockTokens{id:tokens;palette:({avatarRadius:Math.min(48,12*(Services.Settings.data.appearance.roundness.roles.avatar ?? Services.Settings.data.appearance.roundness.master))})}
                    Lock.LockProfile {id:lockProfile;tokens:tokens;displayName:"Lock profile";width:280;scale:.75;transformOrigin:Item.TopLeft;treatment:Services.Settings.data.lockScreen.effects.avatar}
                }
                Lock.LockCredential {id:credential;width:280;tokens:tokens;characterCount:6;style:Services.Settings.data.lockScreen.effects.credential}
                UI.SwitchStylePicker {id:switches;width:280}
            }
        }
    }
    Timer{id:finish;interval:100;onTriggered:Qt.quit()}
    TestCase {
        name:"RoundnessImpact";when:Services.Settings.ready
        function assign(field,value) {
            if(field==="workspace") { const visual=JSON.parse(JSON.stringify(Services.Settings.data.bar.visual));visual.workspacePills.roundness=value;Services.Settings.setValue("bar","visual",visual) }
            else if(field==="header")Services.Settings.setValue("launcher","headerRadius",value)
            else Services.Settings.setRoundness(field,value)
        }
        function capture(target,path) {
            let saved=false
            verify(target.grabToImage(result=>{saved=result.saveToFile(path)}),"Begin item capture")
            tryVerify(()=>saved,5000,"Save item capture")
        }
        function test_matrix(){try{
            const input=Quickshell.env("MAGI_ROUNDNESS_VALUES")
            const saved=input?JSON.parse(input):{master:1,roles:{barPill:1,surface:null,controlTile:1.25,slider:1.2,action:1.2,avatar:1.2,albumArt:1.2,hubSelector:.4,secondaryControl:1.2},workspace:null,header:12}
            const fields=["master","barPill","surface","controlTile","slider","action","avatar","albumArt","hubSelector","secondaryControl","workspace","header"]
            const folder=Quickshell.env("MAGI_ROUNDNESS_CAPTURES")
            function reset(){
                Services.Settings.setValue("appearance","roundness",{master:saved.master,roles:saved.roles});assign("workspace",saved.workspace);assign("header",saved.header)
                Services.Settings.setValue("appearance","toggleStyle",saved.toggleStyle || "pill")
                const layout=JSON.parse(JSON.stringify(Services.Settings.data.lockScreen))
                layout.effects.avatar=saved.avatarStyle || "plain";layout.effects.credential=saved.credentialStyle || "dots"
                Services.Settings.setLockLayout(layout)
            }
            reset();Services.Settings.setTheme("nord");wait(100)
            for(const field of fields){
                const current=field==="master"?saved.master:field==="workspace"?saved.workspace:field==="header"?saved.header:saved.roles[field]
                for(const sample of [["min",0],["current",current],["max",field==="header"?75:2]]){
                    reset();assign(field,sample[1]);secondary.focus=false;if(field==="secondaryControl")secondary.forceActiveFocus();wait(50)
                    verify(avatar.outerRadius<=avatar.width/2);verify(album.outerRadius<=album.width/2)
                    compare(findChild(avatar,"artworkMask").radius,Math.max(0,avatar.outerRadius-avatar.frameWidth))
                    compare(hub.radius,Theme.Theme.radius("hubSelector",22,hub.width,hub.height))
                    compare(pill.radius,Theme.Theme.barPillRadius);compare(workspaces.radius,Theme.Theme.workspacePillRadius)
                    const target=({master:scene,barPill:barSample,workspace:barSample,surface:card,controlTile:cc,slider:cc,action:actionSample,avatar:scene,albumArt:album,hubSelector:hub,secondaryControl:secondary,header:header})[field]
                    if(folder)capture(target,folder+"/"+field+"-"+sample[0]+".png")
                }
            }
            reset()
            for(const example of [["avatar-style",["plain",saved.avatarStyle || "plain","frame"],lockSample,"avatar"],
                ["credential-style",["dots",saved.credentialStyle || "dots","minimal"],credential,"credential"],
                ["switch-style",["pill",saved.toggleStyle || "pill","minimal"],switches,"toggleStyle"]]) {
                for(let index=0;index<3;index++) {
                    if(example[3]==="toggleStyle")Services.Settings.setValue("appearance","toggleStyle",example[1][index])
                    else { const layout=JSON.parse(JSON.stringify(Services.Settings.data.lockScreen));layout.effects[example[3]]=example[1][index];Services.Settings.setLockLayout(layout) }
                    wait(40)
                    if(folder)capture(example[2],folder+"/"+example[0]+"-"+["first","current","last"][index]+".png")
                }
            }
            reset();tryCompare(Services.Settings,"saveState","saved")
            console.log("Roundness impact PASS");finish.start()
        }catch(e){console.error("FAIL:",e,e.stack);finish.start();throw e}}
    }
}
