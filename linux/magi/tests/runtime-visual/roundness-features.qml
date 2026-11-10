import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/components/hub" as Hub
import "../../.config/quickshell/magi/components/launcher" as Launcher
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as CC
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    Bar.Bar { id:bar;expandableHostMode:"combined" }
    FloatingWindow {
        id:sample;visible:true;implicitWidth:720;implicitHeight:630;color:Theme.Theme.background
        Rectangle {
            id:scene;anchors.fill:parent;color:Theme.Theme.background
            Column {
                x:20;y:20;width:330;spacing:12
                Label {text:"Shared action role · affected";color:Theme.Theme.text}
                UI.SettingsButton {id:button;text:"Settings button";width:300}
                UI.SettingsTextField {width:300;text:"Settings input"}
                UI.SettingsNumber {from:0;to:75;value:12}
                UI.SettingsSelector {width:300;model:["Settings selector"];currentIndex:0}
                Hub.HubSearchField {width:300;text:"Hub search";cursorVisible:false}
                Launcher.LauncherItem {width:300;height:56;app:({name:"Launcher result",genericName:"Shared action corners"});preferences:Services.Settings.data.launcher;selected:true;iconPresentation:({source:"",fallbackText:"L"})}
                Controls.ActionChip {id:chip;label:"Bar/menu action chip";icon:"wifi";active:true}
                Row {spacing:12;Controls.IconButton{id:icon;label:"Icon button"} Controls.MediaButton{id:media;icon:"media-play"}}
            }
            Column {
                x:380;y:20;width:320;spacing:12
                Label{text:"Shared switch tracks + handles";color:Theme.Theme.text}
                Repeater {
                    model:["pill","filled","minimal"]
                    Row {required property string modelData;spacing:12
                        Label{text:parent.modelData;color:Theme.Theme.text;width:80}
                        Controls.CompactToggle {toggleStyle:parent.modelData;checked:false}
                        Controls.CompactToggle {toggleStyle:parent.modelData;checked:true}
                    }
                }
                Label{text:"Independent roles · unchanged";color:Theme.Theme.text}
                CC.ControlTile {id:tile;width:64;height:64;icon:"wifi";title:"Primary";active:true}
                CC.ActionButton {id:secondary;width:280;height:38;moduleId:"inhibit";icon:"inhibit";label:"Secondary controls";toggle:true;active:true}
                Controls.RoundedArtwork {id:avatar;width:96;height:96;radius:Theme.Theme.radius("avatar",10,width,height);borderWidth:2;placeholder:"profile"}
                Label{text:"Native lock uses avatar, not action.";color:Theme.Theme.text;wrapMode:Text.Wrap;width:300}
            }
        }
    }
    Timer{id:finish;interval:100;onTriggered:Qt.quit()}
    TestCase {
        name:"FeatureRoundnessGeometry";when:Services.Settings.ready
        function collect(node,predicate){let out=predicate(node)?[node]:[];for(const child of node.children || [])out=out.concat(collect(child,predicate));return out}
        function capture(target,name){const folder=Quickshell.env("MAGI_ROUNDNESS_FEATURE_CAPTURES");if(!folder)return;let saved=false;verify(target.grabToImage(result=>{saved=result.saveToFile(folder+"/"+name+".png")}));tryVerify(()=>saved)}
        function test_geometry(){try{
            const original=JSON.parse(JSON.stringify(Services.Settings.data))
            Services.Settings.setRoundness("controlTile",1.25);Services.Settings.setRoundness("secondaryControl",1.2);Services.Settings.setRoundness("avatar",1.2)
            const tileRadius=tile.radius,secondaryRadius=secondary.children[0].radius,avatarRadius=avatar.radius
            for(const theme of ["nord","one-light"]){
                Services.Settings.setTheme(theme)
                for(const pair of [["min",0],["current",1.2000000000000002],["max",2]]){
                    Services.Settings.setRoundness("action",pair[1]);wait(80)
                    compare(button.background.radius,Theme.Theme.radius("action",8,button.width,button.height))
                    compare(chip.radius,Math.min(13*pair[1],chip.width/2,chip.height/2))
                    compare(tile.radius,tileRadius);compare(secondary.children[0].radius,secondaryRadius);compare(avatar.radius,avatarRadius)
                    icon.forceActiveFocus();capture(scene,theme+"-action-"+pair[0])
                    media.forceActiveFocus();capture(media,theme+"-media-button-"+pair[0])
                }
            }
            Services.Settings.setTheme("nord")
            const visual=JSON.parse(JSON.stringify(Services.Settings.data.bar.visual));visual.workspacePills.roundness=null;Services.Settings.setValue("bar","visual",visual)
            const workspace=findChild(bar.contentItem,"testWorkspaces");verify(workspace!==null)
            for(const width of [720,1200]){
                bar.contentItem.Window.window.width=width;tryCompare(bar,"width",width)
                for(const radius of [0,1,2]){
                    Services.Settings.setRoundness("barPill",radius);wait(60)
                    compare(workspace.radius,Theme.Theme.barPillRadius)
                    for(const selected of [1,2,3]){
                        workspace.testCurrent=selected;wait(30)
                        const cells=collect(workspace,item=>item.modelData!==undefined && item.isActive!==undefined)
                        compare(cells.filter(c=>c.isActive).length,1)
                        for(const cell of cells)compare(cell.radius,workspace.radius)
                    }
                    capture(workspace,"workspace-"+width+"-"+radius)
                    Services.MenuController.open("controlcentre");tryCompare(bar.statusPresentation,"phase",3);wait(60)
                    compare(bar.statusPresentation.paintedBackground.radius,Theme.RenderTokens.outerRadius)
                    verify(bar.statusPresentation.width<=bar.width)
                    capture(bar.statusPresentation,"connected-"+width+"-"+radius)
                    Services.MenuController.close();tryCompare(bar.statusPresentation,"phase",0)
                    compare(Services.Settings.data.bar.visual.workspacePills.roundness,null)
                }
            }
            Services.Settings.setValue("appearance","roundness",original.appearance.roundness)
            Services.Settings.setValue("bar","visual",original.bar.visual);Services.Settings.setTheme(original.appearance.theme)
            tryCompare(Services.Settings,"saveState","saved")
            console.log("Feature roundness geometry PASS");finish.start()
        }catch(e){console.error("FAIL:",e,e.stack);finish.start();throw e}}
    }
}
