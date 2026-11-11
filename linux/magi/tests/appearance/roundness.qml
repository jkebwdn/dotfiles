import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    UI.SettingsWindow { id: window }
    FileView { id: savedFile; path: Services.Settings.path; blockLoading:true; blockWrites:true }
    Timer { id:finish;interval:100;onTriggered:Qt.quit() }
    TestCase {
        name:"FeatureRoundness";when:Services.Settings.ready
        readonly property var owners:({surface:"Appearance",hubSelector:"Hub",barPill:"Bar",controlTile:"Control Centre",secondaryControl:"Control Centre",slider:"Control Centre",albumArt:"Control Centre",avatar:"Control Centre",header:"Launcher"})
        readonly property var pages:["Appearance","Hub","Bar","Control Centre","Launcher"]
        function item(name){const value=findChild(window.contentItem,name);verify(value!==null,name);return value}
        function page(name){return item("settingsPage-"+(name==="Launcher"?"Application Launcher":name))}
        function visit(name,key){
            Services.SettingsWindowState.page=name;wait(60)
            const p=page(name)
            if(name==="Hub"){p.mode="Appearance";p.selection.select("selector")}
            if(name==="Control Centre"){
                item("ccRoundness").expanded=true
                for(const group of ["controls","artwork"])item("ccRoundness-"+group).expanded=group===(["avatar","albumArt"].includes(key)?"artwork":"controls")
            }
            if(name==="Launcher")item("launcherArtwork").expanded=true
            wait(30);return p
        }
        function viewport(){const n=Services.SettingsWindowState.page;return n==="Hub"?item("hubEditorInspector"):n==="Control Centre"?item("ccInspectorScroll"):page(n)}
        function reveal(value){const p=viewport(),y=value.mapToItem(p,0,0).y+p.contentY;p.contentY=Math.max(0,Math.min(p.contentHeight-p.height,y-20));waitForPolish(window.contentItem.Window.window)}
        function current(key){return key==="header"?Services.Settings.data.launcher.headerRadius:Services.Settings.data.appearance.roundness.roles[key]}
        function set(key,value){if(key==="header")Services.Settings.setValue("launcher","headerRadius",value);else Services.Settings.setRoundness(key,value)}
        function reload(){let requested=false;tryVerify(()=>{if(!requested)requested=Services.Settings.discardAndReload();return requested});tryCompare(Services.Settings,"ready",true)}
        function capture(name){const folder=Quickshell.env("MAGI_APPEARANCE_CAPTURES");if(!folder)return;wait(220);let done=false;item("settingsApplicationPane").grabToImage(result=>{done=result.saveToFile(folder+"/"+name+".png")});tryVerify(()=>done)}
        function editors(node){let result=[];if(/^roundness-(surface|hubSelector|barPill|workspace|controlTile|secondaryControl|action|slider|albumArt|avatar|header)$/.test(node.objectName))result.push(node.objectName);for(const child of node.children)result=result.concat(editors(child));return result}
        function test_controls(){try{
            const original=JSON.parse(JSON.stringify(Services.Settings.data)),revision=Services.Settings.revision,raw=savedFile.text()
            Services.SettingsWindowState.shown=true
            for(const name of pages){
                const p=visit(name)
                const expected=Object.keys(owners).filter(key=>owners[key]===name).map(key=>"roundness-"+key).sort()
                compare(editors(p).sort(),expected,"Unique feature ownership "+name)
                verify(findChild(p,"masterRoundnessPrecision")===null);verify(findChild(p,"roundnessChoice-0")===null)
            }
            compare(editors(window.contentItem).length,9)
            compare(item("roundnessPicker").title,"Roundness");compare(item("roundnessPicker").description,"Default roundness for MAGI controls and shared UI.")
            compare(Services.Settings.revision,revision);compare(Services.Settings.data,original)
            savedFile.reload();compare(savedFile.text(),raw,"Passive visits preserve bytes, nulls and absent values")
            for(const theme of ["nord","one-light"]){
                Services.Settings.setTheme(theme)
                for(const size of [[720,600],[1000,760],[1400,900]]){
                    window.contentItem.Window.window.width=size[0];window.contentItem.Window.window.height=size[1];wait(80)
                    for(const name of pages){
                        const keys=Object.keys(owners).filter(key=>owners[key]===name)
                        for(const key of keys){
                            visit(name,key);const control=item("roundness-"+key);reveal(control);verify(control.width>=40)
                            const p=viewport();verify(control.mapToItem(p,0,0).x>=0);verify(control.mapToItem(p,control.width,0).x<=p.width+1,"Contained "+key+" at "+size[0])
                        }
                        visit(name,keys[0]);reveal(item(({Appearance:"roundnessPicker",Hub:"hubSelectorAppearance",Bar:"barRoundness","Control Centre":"ccRoundness",Launcher:"launcherArtwork"})[name]));capture(theme+"-"+size[0]+"-"+name.replace(/ /g,"-"))
                    }
                }
            }
            Services.Settings.setTheme(original.appearance.theme)
            for(const key of Object.keys(owners)){
                visit(owners[key],key);const control=item("roundness-"+key),old=current(key)
                compare(control.from,0);compare(control.to,key==="header"?75:2);compare(control.stepSize,key==="header"?1:.05)
                if(key!=="header" && key!=="surface"){
                    const inherit=item("roundnessInherit-"+key),value=item("roundnessValue-"+key)
                    compare(inherit.checked,old==null);compare(control.enabled,old!=null)
                    if(!inherit.checked){reveal(inherit);inherit.forceActiveFocus();keyClick(Qt.Key_Space)}
                    compare(current(key),null);verify(inherit.checked);verify(!control.enabled);compare(control.value,value.inheritedValue)
                    reveal(inherit);inherit.forceActiveFocus();keyClick(Qt.Key_Space);verify(!inherit.checked);verify(control.enabled);compare(current(key),value.inheritedValue)
                    keyClick(Qt.Key_Tab);verify(control.activeFocus,"Tab enters enabled override")
                    keyClick(Qt.Key_Backtab);verify(inherit.activeFocus,"Reverse tab to inheritance")
                }
                if(key==="surface"){verify(!item("roundnessInherit-surface").visible);verify(control.enabled)}
                reveal(control);control.forceActiveFocus();const before=control.value;keyClick(key==="header"?Qt.Key_Up:Qt.Key_Right);wait(20)
                const expected=Math.min(control.to,before+control.stepSize);verify(Math.abs(current(key)-expected)<.000001,key)
                if(key!=="header"){
                    const preview=item("roundnessPreview-"+key),value=item("roundnessValue-"+key)
                    compare(preview.radius,Theme.Theme.radius(key,value.reference,preview.width,preview.height))
                }else compare(item("roundnessPreview-header").radius,current(key)/2)
                if(key==="barPill"){compare(Services.Settings.data.bar.visual.workspacePills.roundness,null);compare(Theme.Theme.workspacePillRadius,Theme.Theme.barPillRadius)}
                tryCompare(Services.Settings,"saveState","saved");reload();verify(Math.abs(current(key)-expected)<.000001,"Disk reload "+key)
                if(key!=="header" && key!=="surface"){
                    const inherit=item("roundnessInherit-"+key);reveal(inherit);inherit.forceActiveFocus();keyClick(Qt.Key_Space);compare(current(key),null)
                    keyClick(Qt.Key_Space);compare(current(key),item("roundnessValue-"+key).inheritedValue,"No stale custom cache")
                }
                set(key,old)
            }
            compare(Services.Settings.data.appearance.roundness.master,original.appearance.roundness.master)
            compare(Services.Settings.data.bar.visual.workspacePills.roundness,original.bar.visual.workspacePills.roundness)
            // A separate saved Workspace override must never be silently merged.
            visit("Bar");const visual=JSON.parse(JSON.stringify(Services.Settings.data.bar.visual));visual.workspacePills.roundness=.25;Services.Settings.setValue("bar","visual",visual)
            verify(!item("roundness-barPill").enabled);verify(!item("roundnessInherit-barPill").enabled)
            compare(Services.Settings.data.bar.visual.workspacePills.roundness,.25);Services.Settings.setValue("bar","visual",original.bar.visual)
            visit("Hub");verify(findChild(page("Hub"),"switchStylePicker")!==null)
            Services.SettingsWindowState.page="Lock Screen";wait(80);verify(item("lockOption-avatarStyle")!==null);verify(item("lockCredentialStyle")!==null)
            tryCompare(Services.Settings,"saveState","saved");savedFile.setText(raw);reload();wait(100)
            savedFile.reload();compare(savedFile.text(),raw);compare(Services.Settings.data,original)
            console.log("Feature roundness PASS");finish.start()
        }catch(e){console.error("FAIL:",e,e.stack);finish.start();throw e}}
    }
}
