import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as CC
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/settings/SettingsSchema.js" as Schema
ShellRoot {
    UI.SettingsWindow { id: window }
    QtObject { id: output; property int width: 1920; property int height: 1080 }
    CC.ControlCentre { id: live; barWindow: output; hostMode: "combined" }
    FloatingWindow {
        id: comparison; visible: false; implicitWidth: 1300; implicitHeight: 1000
        Loader { id: runtime; width: live.expandedWidth - 2 * live.viewPadding; sourceComponent: live.menuContent }
        UI.ControlCentrePreview { id: preview; x: 650; width: 620; height: 950; outputWidth: output.width; outputHeight: output.height }
    }
    FileView { id: saved; path: Services.Settings.path; blockLoading: true; blockWrites: true }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "SettingsRefinement"; when: Services.Settings.ready
        function item(name) {const value=findChild(window.contentItem,name);verify(value!==null,name);return value}
        function page(name) {Services.SettingsWindowState.page=name;wait(80);return item("settingsPage-"+name)}
        function reveal(control,p) {p.contentY=Math.max(0,Math.min(p.contentHeight-p.height,control.mapToItem(p,0,0).y+p.contentY-20));wait(30)}
        function capture(name) {const dir=Quickshell.env("MAGI_REFINEMENT_CAPTURES");if(dir){wait(100);grabImage(window.contentItem).save(dir+"/"+name+".png")}}
        function checkGeometry() {
            wait(80)
            compare(preview.geometry.width,live.expandedWidth)
            compare(preview.geometry.height,live.menuHeight)
            compare(preview.geometry.sections,live.sectionLayout)
            const names={controls:"runtimePrimarySection",actions:"runtimeActionSection",sliders:"runtimeSliderSection"}
            for(const group of ["controls","sliders","actions"]){
                const actual=findChild(runtime.item,names[group]),region=preview.regionGeometry().find(r=>r.id===group)
                if(!region || region.emptyTarget){verify(!actual.visible);continue}
                compare(region.y,actual.y+live.viewTopPadding)
                const cells=actual.children.filter(c=>c.moduleId!==undefined)
                compare(cells.map(c=>c.moduleId),preview.moduleBoard.order(group))
                for(const cell of cells){
                    const position=preview.moduleLocation(cell.moduleId,preview.regionGeometry())
                    verify(Math.abs(position.x-cell.x-live.viewPadding)<.01,group+" x "+cell.moduleId)
                    verify(Math.abs(position.y-actual.y-cell.y-live.viewTopPadding)<.01,group+" y "+cell.moduleId)
                    verify(Math.abs(position.width-cell.width)<.01,group+" width "+cell.moduleId)
                    verify(Math.abs(position.height-cell.height)<.01,group+" height "+cell.moduleId)
                }
            }
        }
        function test_refinement(){try{
            const original=JSON.parse(JSON.stringify(Services.Settings.data)),raw=saved.text(),revision=Services.Settings.revision
            Services.SettingsWindowState.shown=true
            for(const name of ["Bar","Wallpaper","Appearance","Control Centre"])page(name)
            compare(Services.Settings.data,original);compare(Services.Settings.revision,revision)
            saved.reload();compare(saved.text(),raw)
            let bar=page("Bar")
            verify(bar.mode===undefined)
            for(const id of ["barLayoutCard","barAvailableItems","barBehaviourControls","barRoundness","barGlobalOptions"])verify(item(id).visible)
            verify(item("barAvailableItems").mapToItem(bar.body,0,0).y>=item("barLayoutCard").mapToItem(bar.body,0,item("barLayoutCard").height).y)
            const globalBefore=JSON.stringify(Services.Settings.data),globalRevision=Services.Settings.revision
            const background=item("barGlobal-host"),status=item("barGlobal-statusPills")
            verify(background.collapsible);verify(status.collapsible)
            verify(!item("visualSetting-statusIconSize").visible)
            verify(!background.expanded);verify(!status.expanded)
            verify(background.mapToItem(bar.body,0,0).y<status.mapToItem(bar.body,0,0).y)
            for(const section of [background,status]){
                reveal(section,bar);section.disclosureButton.forceActiveFocus();keyClick(Qt.Key_Space);wait(30)
                verify(section.expanded);verify(item("barGlobalRole-"+section.modelData).visible)
                if(section===status){
                    const size=item("visualSetting-statusIconSize")
                    verify(size.visible)
                    verify(size.mapToItem(status,0,0).y<item("settingsToggle-Show status-pill backgrounds").mapToItem(status,0,0).y)
                }
                mouseClick(section.disclosureButton,10,10);wait(30)
                verify(!section.expanded);verify(!item("barGlobalRole-"+section.modelData).visible)
            }
            const placement=item("barPlacement")
            verify(placement.collapsible);verify(!placement.expanded);verify(!item("barPosition").visible)
            verify(item("barBehaviourHelp").mapToItem(bar.body,0,0).y<placement.mapToItem(bar.body,0,0).y)
            verify(item("barGlobalForegroundHelp").mapToItem(bar.body,0,0).y<background.mapToItem(bar.body,0,0).y)
            reveal(placement,bar);placement.disclosureButton.forceActiveFocus();keyClick(Qt.Key_Space);wait(30)
            verify(item("barPosition").visible);verify(item("horizontalInset").visible);verify(item("edgeOffset").visible)
            keyClick(Qt.Key_Space);wait(30);verify(!placement.expanded)
            compare(JSON.stringify(Services.Settings.data),globalBefore);compare(Services.Settings.revision,globalRevision)
            for(const theme of ["nord","one-light"]){
                Services.Settings.setTheme(theme)
                for(const size of [[720,600],[1000,760],[1400,900]]){
                    window.contentItem.Window.window.width=size[0];window.contentItem.Window.window.height=size[1]
                    for(const name of ["Bar","Wallpaper","Appearance","Control Centre"]){
                        const p=page(name);p.contentY=0
                        if(name==="Bar"){
                            p.selection.select("");capture(theme+"-"+size[0]+"-bar-global")
                            const board=item("barOrder"),host=item("barPreviewHost"),layout=item("barLayoutCard"),available=item("barAvailableItems")
                            const centre=item("barOrder-heading-center"),workspace=item("barOrder-row-workspaces")
                            compare(centre.horizontalAlignment,Text.AlignHCenter)
                            compare(item("barOrder-heading-left").horizontalAlignment,Text.AlignLeft)
                            compare(item("barOrder-heading-right").horizontalAlignment,Text.AlignRight)
                            verify(Math.abs(centre.mapToItem(board,centre.width/2,0).x-board.width/2)<.01)
                            tryVerify(()=>Math.abs(workspace.mapToItem(board,workspace.width/2,0).x-board.width/2)<.01,1000,"Workspace preview settles at the exact Bar midpoint")
                            const bottom=host.mapToItem(layout,0,host.height).y
                            verify(layout.height-bottom>=12 && layout.height-bottom<20,"Tight safe preview bottom padding")
                            const palette=board.geometry.find(l=>l.id==="hidden")
                            if(palette.keys.length){
                                const first=board.rowFor(palette.keys[0])
                                tryVerify(()=>Math.abs(first.mapToItem(available,0,0).y-40)<.01,1000,"Available items do not reserve a second heading")
                                verify(available.height-first.mapToItem(available,0,first.height).y>=11.9)
                            }
                            reveal(item("barGlobalOptions"),p);capture(theme+"-"+size[0]+"-bar-disclosures")
                            item("barGlobal-statusPills").expanded=true;wait(30)
                            reveal(item("barGlobalOptions"),p);capture(theme+"-"+size[0]+"-bar-status-items")
                            item("barGlobal-statusPills").expanded=false;wait(30)
                            for(const id of ["bluetooth","volume","battery"]){
                                p.contentY=0;wait(30);mouseClick(item("barOrder-row-"+id),10,10);compare(p.selection.instance,id);waitForPolish(window.contentItem.Window.window)
                                const card=item("barIdentityInspector");verify(card.visible);verify(!item("barColourRefinement").carded)
                                const inspector=item("barAppearanceInspector"),canvas=item("barCanvas")
                                verify(inspector.mapToItem(p.body,0,0).y>=canvas.mapToItem(p.body,0,canvas.height).y)
                                verify(item("barBehaviourControls").mapToItem(p.body,0,0).y>=inspector.mapToItem(p.body,0,inspector.height).y)
                                verify(item("barGlobalOptions").mapToItem(p.body,0,0).y>card.mapToItem(p.body,0,0).y)
                                reveal(card,p);verify(card.width<=p.width);capture(theme+"-"+size[0]+"-bar-"+id)
                            }
                            p.contentY=0;wait(30);const canvas=item("barCanvas");mouseClick(canvas,canvas.width-18,item("barLayoutCard").height-10)
                            compare(p.selection.instance,"");verify(!item("barAppearanceInspector").visible)
                        }else {
                            if(name==="Appearance")reveal(item("roundnessPicker"),p)
                            capture(theme+"-"+size[0]+"-"+name.replace(/ /g,"-"))
                        }
                    }
                }
            }
            bar=page("Bar");bar.selection.select("bluetooth");wait(30)
            const inherited=item("barBackgroundInherited"),picker=item("barItemBackground")
            verify(inherited.checked);verify(!picker.enabled)
            reveal(inherited,bar);inherited.forceActiveFocus();keyClick(Qt.Key_Space)
            verify(!inherited.checked);verify(picker.enabled)
            picker.currentIndex=picker.model.indexOf("red");picker.activated(picker.currentIndex)
            compare(Services.Settings.data.bar.modules.bluetooth.backgroundRole,"red")
            inherited.forceActiveFocus();keyClick(Qt.Key_Space);compare(Services.Settings.data.bar.modules.bluetooth.backgroundRole,null)
            verify(inherited.checked);verify(!picker.enabled)
            const accent=item("barForegroundInherited");reveal(accent,bar)
            verify(accent.checked);accent.forceActiveFocus();keyClick(Qt.Key_Space);verify(!accent.checked);verify(item("barInstanceAccent").enabled)
            item("barInstanceAccent").currentIndex=item("barInstanceAccent").model.indexOf("green");item("barInstanceAccent").activated(item("barInstanceAccent").currentIndex)
            accent.forceActiveFocus();keyClick(Qt.Key_Space);compare(Services.Settings.data.bar.modules.bluetooth.accentRole,"accent")
            page("Appearance");verify(!item("roundnessInherit-surface").visible);verify(item("roundness-surface").enabled)
            compare(item("roundnessPicker").description,"Cards, Menus, Notifications & Pop Ups.")
            comparison.visible=true
            const defaults=Schema.defaults().controlCentre
            Services.Settings.setValue("profile","displayName","Review profile")
            Services.Settings.setValue("profile","subtitle","Current-layout geometry fixture")
            for(const width of [360,1920]){
                output.width=width
                for(const count of [0,2,4,6]){
                    Services.Settings.setValue("controlCentre","controls",Schema.controlDefinitions().filter(d=>d.presentations.includes("tile")).slice(0,count).map(d=>({key:d.id,module:d.id,presentation:"tile",enabled:true,accent:d.accent})))
                    for(const media of [true,false]){
                        Services.Settings.setControlSection("media",media)
                        for(const editing of [false,true]){preview.editing=editing;checkGeometry()}
                    }
                }
            }
            Services.Settings.setValue("controlCentre","controls",defaults.controls)
            Services.Settings.setControlSection("media",true);output.width=1920;preview.editing=true;checkGeometry()
            compare(live.controls.length,4);compare(live.rows,1)
            // Operator shape: four enabled primary controls, a disabled battery,
            // two sliders, five actions, profile and media. No personal data.
            Services.Settings.setValue("controlCentre","actionColumns",5)
            Services.Settings.setValue("controlCentre","actions",defaults.actions.filter(e=>e.module!=="vpn"))
            Services.Settings.setValue("controlCentre","controls",defaults.controls.concat([{key:"battery",module:"battery",presentation:"tile",accent:"red",enabled:false}]))
            checkGeometry();compare(live.controls.length,4);compare(live.actions.length,5)
            compare(preview.geometry.actionColumns,5)
            verify(preview.moduleBoard.canonicalKeys("available").includes("suspend"))
            Services.Settings.placeCCModule("suspend","actions");checkGeometry()
            verify(live.actions.some(e=>e.module==="suspend"));verify(!preview.moduleBoard.canonicalKeys("available").includes("suspend"))
            Services.Settings.placeCCModule("suspend","available");checkGeometry()
            verify(!live.actions.some(e=>e.module==="suspend"))
            comparison.visible=false
            tryCompare(Services.Settings,"saveState","saved")
            verify(Services.Settings.commit(JSON.parse(raw)))
            tryCompare(Services.Settings,"saveState","saved")
            let requested=false;tryVerify(()=>{if(!requested)requested=Services.Settings.discardAndReload();return requested});tryCompare(Services.Settings,"ready",true)
            compare(Services.Settings.data,original)
            console.log("Settings refinement PASS");finish.start()
        }catch(e){console.error("FAIL:",e,e.stack);finish.start();throw e}}
    }
}
