import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/settings/SettingsSchema.js" as Schema
ShellRoot {
    UI.SettingsWindow { id: window }
    FileView { id: saved; path: Services.Settings.path; blockLoading: true; blockWrites: true }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "ControlCentreWorkflow"
        when: Services.Settings.ready
        function item(name) { const found=findChild(window.contentItem,name);verify(found!==null,name);return found }
        function reveal(control,p) {
            p.contentY=Math.max(0,Math.min(p.contentHeight-p.height,control.mapToItem(p.contentItem,0,0).y-40));wait(150)
        }
        function capture(name) {
            const dir=Quickshell.env("MAGI_CC_WORKFLOW_CAPTURES")
            if(dir){wait(150);grabImage(window.contentItem).save(dir+"/"+name+".png")}
        }
        function drag(board,key,laneId,targetKey,after) {
            const p=board.viewport,handle=item(board.objectName+"-handle-"+key)
            reveal(handle,p)
            const point=handle.mapToItem(window.contentItem,handle.width/2,Math.min(handle.height/2,16))
            const revision=Services.Settings.revision
            console.log("DRAG",key,laneId,point.x,point.y,handle.width,handle.height,handle.visible)
            capture("before-drag-"+key+"-"+laneId)
            mousePress(window.contentItem,point.x,point.y)
            mouseMove(window.contentItem,point.x-12,point.y,30)
            tryCompare(board,"dragging",true)
            let last
            for(let i=0;i<180;i++){
                const lane=board.geometry.find(l=>l.id===laneId)
                verify(lane!==undefined,"Destination "+laneId)
                const slot=targetKey?board.location(targetKey):null
                const x=slot?slot.x+slot.width/2:lane.x+lane.width/2
                const y=slot?slot.y+slot.height*(after?.8:.2):lane.y+Math.min(lane.height/2,16)
                const dest=board.mapToItem(p,x,y)
                last=p.mapToItem(window.contentItem,dest.x,Math.max(12,Math.min(p.height-12,dest.y)))
                mouseMove(window.contentItem,last.x,last.y,20);wait(20)
                if(dest.y>32 && dest.y<p.height-32){wait(150);if(board.targetLane===laneId)break}
            }
            console.log("DROP",key,laneId,"actual",board.targetLane,"pointer",board.boardPointer.x,board.boardPointer.y,"scroll",p.contentY)
            verify(board.dragging);compare(board.targetLane,laneId)
            verify(item(board.objectName+"-insertion").visible)
            compare(Services.Settings.revision,revision,"Drag preview never saves intermediate order")
            capture("drag-"+key+"-"+laneId)
            mouseRelease(window.contentItem,last.x,last.y);wait(180)
            verify(!board.dragging);compare(Services.Settings.revision,revision+1,"One deliberate drop writes once")
        }
        function hierarchy(p) {
            const names=["ccAvailableControls","ccSelectedInspector","ccGlobalControls","ccRoundness","decorationSettings"]
            let bottom=-1
            for(const name of names){const c=item(name);if(!c.visible)continue;const top=c.mapToItem(p.contentItem,0,0).y;verify(top>=bottom,name+" order");bottom=top+c.height}
        }
        function paletteGeometry(preview) {
            const card=item("ccAvailableControls"), board=preview.moduleBoard
            const contentTop=card.controlsArea.mapToItem(card,0,0).y
            for(const key of board.order("available")) {
                const row=board.rowFor(key), presenter=findChild(row,"ccPreview-"+key)
                verify(presenter!==null,key+" presenter")
                verify(presenter.height>0,key+" initial Loader geometry")
                verify(presenter.mapToItem(card,0,0).y>=contentTop-1,key+" stays below description")
            }
        }
        function test_workflow(){try{
            const original=JSON.stringify(Services.Settings.data),raw=saved.text(),revision=Services.Settings.revision
            Services.SettingsWindowState.shown=true;Services.SettingsWindowState.page="Control Centre";wait(200)
            const p=item("settingsPage-Control Centre"),preview=item("controlCentrePreview"),board=preview.moduleBoard,structure=preview.structureBoard
            paletteGeometry(preview)
            verify(p.mode===undefined);verify(!item("ccSelectedInspector").visible);hierarchy(p)
            for(const id of ["profile","controls","sliders","actions","media","wifi",""]){p.selection.select(id);wait(30)}
            item("ccGlobalControls").expanded=true;item("ccRoundness").expanded=true;wait(30)
            compare(JSON.stringify(Services.Settings.data),original);compare(Services.Settings.revision,revision)
            saved.reload();compare(saved.text(),raw,"Passive page visits and selection preserve exact file bytes")
            const available=item("ccAvailableControls"), roundness=item("ccRoundness"), border=item("ccGlobalBorder")
            verify(available.collapsible);verify(available.expanded)
            available.disclosureButton.forceActiveFocus();keyClick(Qt.Key_Space);wait(160)
            verify(!available.expanded);capture("available-collapsed")
            for(const key of board.order("available"))verify(!board.rowFor(key).visible,"Collapsed catalogue hides external delegate "+key)
            available.disclosureButton.forceActiveFocus();keyClick(Qt.Key_Space);wait(160)
            verify(available.expanded);paletteGeometry(preview)
            verify(border.collapsible);verify(!border.expanded)
            border.disclosureButton.forceActiveFocus();keyClick(Qt.Key_Space);verify(border.expanded)
            border.disclosureButton.forceActiveFocus();keyClick(Qt.Key_Space);verify(!border.expanded)
            verify(!roundness.collapsible);verify(roundness.expanded)
            for(const group of ["controls","artwork"]){
                const heading=item("ccRoundness-"+group)
                verify(heading.disclosureButton.visible);heading.expanded=false
                heading.disclosureButton.forceActiveFocus();keyClick(Qt.Key_Space);verify(heading.expanded)
                keyClick(Qt.Key_Space);verify(!heading.expanded);verify(heading.disclosureButton.visible)
            }
            p.contentY=0;wait(150)
            const primary=item("ccAppearanceRegion-controls")
            // The gap between tiles selects the module; a tile selects only itself.
            mouseClick(primary,preview.size("controls")+6,10);wait(100)
            compare(p.selection.instance,"controls");verify(item("ccFamilyInspector").visible)
            mouseClick(item("ccModuleBoard-handle-wifi"),12,12);wait(100)
            compare(p.selection.instance,"wifi");verify(!item("ccFamilyInspector").visible);verify(item("ccInstanceAccent").visible);capture("primary-button-only")
            compare(JSON.stringify(Services.Settings.data),original);compare(Services.Settings.revision,revision)
            Services.Settings.setValue("profile","displayName","Workflow review")
            Services.Settings.setValue("profile","subtitle","Private fixture")
            Services.Settings.resetSection("controlCentre");wait(180)
            for(const id of ["profile","controls","sliders","actions","media"]){
                const region=item("ccAppearanceRegion-"+id),before=Services.Settings.revision
                reveal(region,p);region.forceActiveFocus();keyClick(Qt.Key_Return);wait(80)
                compare(p.selection.instance,id);verify(item("ccSelectedInspector").visible);hierarchy(p)
                compare(Services.Settings.revision,before)
            }
            p.contentY=0;wait(120)
            mouseClick(preview,preview.decorationSpace*preview.fitScale+preview.canvasWidth*preview.fitScale/2,3)
            compare(p.selection.instance,"");verify(!item("ccSelectedInspector").visible)
            const order=Services.Settings.data.controlCentre.layout.slice()
            for(const key of ["media","sliders","actions","controls","profile"]){
                const target=Services.Settings.data.controlCentre.layout.find(id=>id!==key && preview.composition.positions[id]!==undefined)
                if(Services.Settings.data.controlCentre.layout[0]===key)continue
                drag(structure,key,"structure",target,false)
                compare(Services.Settings.data.controlCentre.layout[0],key)
                compare(new Set(Services.Settings.data.controlCentre.layout).size,order.length)
                compare(preview.order,Services.Settings.data.controlCentre.layout)
            }
            const moduleHandle=item("ccStructureBoard-handle-media")
            reveal(moduleHandle,p);moduleHandle.forceActiveFocus();keyClick(Qt.Key_Home,Qt.AltModifier);wait(160)
            compare(Services.Settings.data.controlCentre.layout[0],"media")
            verify(!structure.canPlace("controls","availableStructure"));verify(!structure.canPlace("actions","availableStructure"))
            const protectedOrder=JSON.stringify(Services.Settings.data.controlCentre.layout)
            structure.request("controls","availableStructure",0,true)
            compare(JSON.stringify(Services.Settings.data.controlCentre.layout),protectedOrder)
            Services.Settings.resetSection("controlCentre");wait(180)
            verify(board.entryFor("suspend").lane==="available")
            drag(board,"suspend","actions",board.order("actions")[0],false)
            compare(board.entryFor("suspend").lane,"actions")
            available.expanded=false;wait(160)
            drag(board,"suspend","available",null,false)
            verify(available.expanded,"Collapsed removal card opens on valid drag")
            compare(board.entryFor("suspend").lane,"available")
            verify(!board.canPlace("volume","controls"));verify(!board.canPlace("wifi","sliders"))
            const invalidBefore=JSON.stringify(Services.Settings.data)
            board.request("volume","controls",0,true)
            compare(JSON.stringify(Services.Settings.data),invalidBefore)
            // Removal and re-addition share the catalogue and original placement writer.
            drag(structure,"media","availableStructure",null,false)
            verify(!Services.Settings.data.controlCentre.layout.includes("media"))
            drag(structure,"media","structure","controls",true)
            verify(Services.Settings.data.controlCentre.layout.includes("media"))
            for(const name of ["controls","actions","sliders"]){
                p.selection.select(name);wait(80);verify(item("ccSelectedInspector").visible)
            }
            for(const role of ["controlTile","secondaryControl","slider","albumArt","avatar"]){
                const control=item("roundness-"+role)
                compare(control.from,0);compare(control.to,2);compare(control.stepSize,.05)
            }
            tryCompare(Services.Settings,"saveState","saved",10000)
            const persisted=JSON.stringify(Services.Settings.data.controlCentre)
            Services.Settings.discardAndReload();tryCompare(Services.Settings,"ready",true);wait(150)
            compare(JSON.stringify(Services.Settings.data.controlCentre),persisted)
            for(const theme of ["nord","one-light"]){
                Services.Settings.setTheme(theme)
                for(const size of [[720,600],[1000,760],[1400,900]]){
                    window.contentItem.Window.window.width=size[0];window.contentItem.Window.window.height=size[1];wait(180)
                    verify(preview.fitScale*preview.sceneWidth<=preview.width+1)
                    verify(preview.fitScale*preview.composition.height<=preview.height+1)
                    for(const id of ["","profile","controls","wifi","media"]){
                        p.selection.select(id);wait(100);hierarchy(p);p.contentY=0
                        capture(theme+"-"+size[0]+"-"+(id||"none"))
                    }
                    for(const card of ["ccGlobalControls","ccRoundness","decorationSettings"]){
                        item(card).expanded=true;reveal(item(card),p);capture(theme+"-"+size[0]+"-"+card)
                    }
                    paletteGeometry(preview)
                    const available=item("ccAvailableControls"),rect=preview.paletteRect(available)
                    const lane=board.geometry.find(l=>l.id==="available")
                    for(const axis of ["x","y","width","height"]) verify(Math.abs(lane[axis]-rect[axis])<.01,"Available card "+axis+": "+lane[axis]+" vs "+rect[axis])
                    for(const key of board.order("available")){
                        const row=board.rowFor(key)
                        tryVerify(()=>Math.abs(row.x-row.slot.x)<.01 && Math.abs(row.y-row.slot.y)<.01)
                        const top=row.mapToItem(available,0,0),end=row.mapToItem(available,row.width,row.height)
                        verify(top.x>=0 && top.y>=0 && end.x<=available.width+1 && end.y<=available.height+1,"Catalogue contained: "+key)
                    }
                }
            }
            Services.Settings.commit(JSON.parse(original));tryCompare(Services.Settings,"saveState","saved",10000)
            Services.Settings.discardAndReload();tryCompare(Services.Settings,"ready",true);compare(JSON.stringify(Services.Settings.data),original)
            console.log("Control Centre workflow PASS")
        }catch(error){console.error("FAIL:",error,error.stack)}finally{finish.start()}}
    }
}
