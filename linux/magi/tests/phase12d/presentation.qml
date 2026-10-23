import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1450;implicitHeight:1000;color:Theme.Theme.background;UI.SettingsContent {anchors.fill:parent}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase12D";when:Services.Settings.ready
  function item(n){const x=findChild(win.contentItem,n);verify(x!==null,n);return x}
  function capture(n){verify(item("ccEditorTitle").mapToItem(win.contentItem,0,0).y>=0,"editor title stays in bounds");win.contentItem.opacity=.999;wait(30);win.contentItem.opacity=1;wait(180);grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE12D_PREVIEWS")+"/"+n+".png")}
  function test_editor(){try{
   Services.SettingsWindowState.page="Control Centre";wait(350)
   const page=item("settingsPage-Control Centre"),preview=item("controlCentrePreview")
   const board=preview.moduleBoard,original=JSON.stringify(Services.Settings.data.controlCentre)
   capture("layout");capture("available-controls")
   const handle=item("ccModuleBoard-handle-wifi"),target=board.geometry.find(l=>l.id==="actions")
   const revision=Services.Settings.revision
   mousePress(handle,12,12,Qt.LeftButton);mouseMove(board,target.x+15,target.y+40,40);wait(40)
   verify(board.dragging);compare(JSON.stringify(Services.Settings.data.controlCentre),original);capture("control-drag")
   mouseRelease(board,target.x+15,target.y+40,Qt.LeftButton);wait(180)
   verify(Services.Settings.data.controlCentre.actions.some(e=>e.module==="wifi"&&e.enabled));compare(Services.Settings.revision,revision+1)
   for(const destination of ["controls","available"]){
    const h=item("ccModuleBoard-handle-battery"),lane=board.geometry.find(l=>l.id===destination)
    mousePress(h,12,12,Qt.LeftButton);mouseMove(board,lane.x+15,lane.y+40,40);verify(board.dragging)
    mouseRelease(board,lane.x+15,lane.y+40,Qt.LeftButton);wait(180)
    compare(board.entryFor("battery").lane,destination)
   }
   for(const id of ["wifi","bluetooth","lock"]){
    for(const group of ["controls","actions","available","controls"]){
     verify(Services.Settings.placeCCModule(id,group,0));wait(20)
     const cc=Services.Settings.data.controlCentre,placed=cc.controls.concat(cc.actions,cc.sliders).filter(e=>e.module===id)
     compare(placed.length,1);compare(placed[0].enabled,group!=="available")
    }
   }
   verify(!Services.Settings.placeCCModule("volume","controls"));verify(!Services.Settings.placeCCModule("wifi","sliders"))
   board.request("brightness","sliders",0,true);compare(Services.Settings.data.controlCentre.sliders[0].module,"brightness")
   Services.Settings.placeCCModule("volume","available");Services.Settings.placeCCModule("volume","sliders",0)
   Services.Settings.placeCCModule("wifi","controls",0);wait(160)
   const stale=item("ccModuleBoard-handle-wifi")
   mousePress(stale,12,12,Qt.LeftButton);mouseMove(board,target.x+20,target.y+40,40);verify(board.dragging)
   Services.Settings.placeCCModule("bluetooth","actions",0);wait(30);verify(!board.dragging)
   mouseRelease(board,target.x+20,target.y+40,Qt.LeftButton)
   const grip=item("ccModuleBoard-handle-wifi");grip.forceActiveFocus();keyClick(Qt.Key_Right,Qt.AltModifier);wait(150)
   verify(Services.Settings.data.controlCentre.actions.some(e=>e.module==="wifi"))
   Services.Settings.placeCCModule("wifi","controls",0);Services.Settings.placeCCModule("bluetooth","controls",1)
   const a=Services.Settings.data.controlCentre.controls.find(e=>e.module==="wifi"),b=Services.Settings.data.controlCentre.controls.find(e=>e.module==="bluetooth")
   Services.Settings.editEntry("controls",a.key,"accent","red");Services.Settings.editEntry("controls",b.key,"accent","lavender")
   Services.Settings.setRoundness("controlTile",1.4);wait(100)
   compare(item("ccPreview-wifi").presenter.radius,item("ccPreview-bluetooth").presenter.radius)
   compare(item("ccPreview-wifi").presenter.accentRole,"red");compare(item("ccPreview-bluetooth").presenter.accentRole,"lavender")
   page.mode="Appearance"
   for(const id of ["","profile","controls","wifi","sliders","volume","actions","dnd","media"]){page.selection.select(id);capture(id||"host")}
   page.selection.select("wifi");capture("wifi-identity");page.contentY=0
   Services.Settings.setVisual("tileBorderWidth",2);wait(20)
   compare(item("ccPreview-wifi").presenter.border.width,2);compare(item("ccPreview-bluetooth").presenter.border.width,2)
   Services.Settings.setVisual("sliderTrack","blue");Services.Settings.setRoundness("slider",.7);wait(20)
   compare(item("ccPreview-volume").presenter.children[0].color,item("ccPreview-brightness").presenter.children[0].color)
   compare(item("ccPreview-volume").presenter.children[0].radius,item("ccPreview-brightness").presenter.children[0].radius)
   const before=JSON.stringify(Services.Settings.data);mouseClick(item("ccModuleBoard-row-wifi"),20,20);compare(page.selection.instance,"wifi");compare(JSON.stringify(Services.Settings.data),before)
   Services.Settings.setRoundness("secondaryControl",.5)
   Services.Settings.placeCCModule("wifi","actions",0);page.selection.select("wifi");wait(100)
   compare(page.selection.family,"actions");compare(item("ccPreview-wifi").presenter.accentRole,"red")
   compare(item("ccPreview-wifi").presenter.children[0].radius,Theme.Theme.radius("secondaryControl",10,item("ccPreview-wifi").presenter.width,item("ccPreview-wifi").presenter.height));capture("wifi-secondary")
   Services.Settings.placeCCModule("bluetooth","actions",1);Services.Settings.setVisual("secondaryBorderWidth",2);Services.Settings.setVisual("secondaryBackgroundOpacity",.4);wait(30)
   compare(item("ccPreview-wifi").presenter.children[0].radius,item("ccPreview-bluetooth").presenter.children[0].radius)
   compare(item("ccPreview-wifi").presenter.children[0].border.width,2);compare(item("ccPreview-bluetooth").presenter.children[0].border.width,2)
   verify(item("ccPreview-wifi").presenter.children[0].color!==item("ccPreview-bluetooth").presenter.children[0].color)
   Services.Settings.placeCCModule("bluetooth","controls",0)
   page.mode="Layout";capture("structure")
   const structure=preview.structureBoard,mediaHandle=item("ccStructureBoard-handle-media")
   const saved=JSON.stringify(Services.Settings.data.controlCentre.layout)
   mousePress(mediaHandle,12,12,Qt.LeftButton);mouseMove(structure,30,25,40);verify(structure.dragging)
   compare(JSON.stringify(Services.Settings.data.controlCentre.layout),saved);capture("structural-drag")
   mouseRelease(structure,30,25,Qt.LeftButton);wait(180);compare(Services.Settings.data.controlCentre.layout[0],"media");capture("media-first")
   const staleStructure=item("ccStructureBoard-handle-media")
   mousePress(staleStructure,12,12,Qt.LeftButton);mouseMove(structure,45,90,40);verify(structure.dragging)
   Services.Settings.placeCCSection("profile",0);wait(20);verify(!structure.dragging);mouseRelease(structure,45,90,Qt.LeftButton)
   for(const id of ["profile","media","sliders"]){const style=JSON.stringify(Services.Settings.data.appearance);Services.Settings.placeCCSection(id,-1);verify(!Services.Settings.data.controlCentre.layout.includes(id));Services.Settings.placeCCSection(id,0);compare(JSON.stringify(Services.Settings.data.appearance),style)}

   for(const entry of Services.Settings.data.controlCentre.controls.slice())Services.Settings.placeCCModule(entry.module,"available")
   wait(100);capture("empty-primary");verify(preview.moduleBoard.geometry.some(l=>l.id==="controls"))
   Services.Settings.placeCCModule("wifi","controls",0)
   tryCompare(Services.Settings,"saveState","saved");wait(200)
   const persisted=JSON.stringify(Services.Settings.data.controlCentre)
   Services.Settings.placeCCSection("profile",2);Services.Settings.setRoundness("controlTile",.1)
   verify(Services.Settings.discardAndReload());tryCompare(Services.Settings,"ready",true);compare(JSON.stringify(Services.Settings.data.controlCentre),persisted)
   for(const theme of ["catppuccin-mocha","everforest-dark-hard","rose-pine","nord","tokyo-night-moon","rose-pine-dawn"]){Services.Settings.setTheme(theme);capture(theme)}
   page.mode="Appearance";page.selection.select("media");capture("media-behaviour")
   page.mode="Appearance";Services.Settings.setTheme("rose-pine-dawn");capture("light")
   win.contentItem.Window.window.width=720;win.contentItem.Window.window.height=900;capture("compact")
   Services.Settings.resetSection("controlCentre");Services.Settings.resetSection("appearance")
   for(const size of [Qt.size(1080,780),Qt.size(720,500)]) {
    win.contentItem.Window.window.width=size.width;win.contentItem.Window.window.height=size.height
    for(const mode of ["Layout","Appearance"]) {
     page.mode=mode;;wait(180)
     verify(preview.composition.height*preview.fitScale<=preview.height+1,"entire composition fits vertically")
     verify(preview.sceneWidth*preview.fitScale<=preview.width+1,"canvas and palette fit horizontally")
     const inspector=item("controlCentreEditor")
     if(mode!=="Layout") {
      verify(inspector.visible)
      verify(inspector.mapToItem(page,0,0).x>=preview.mapToItem(page,preview.width,0).x,"inspector stays to the right")
      compare(Math.round(inspector.mapToItem(page,0,0).y),Math.round(preview.mapToItem(page,0,0).y))
     }
     if(size.width===1080)capture("fit-"+({"Layout":"layout","Appearance":"look","Behaviour":"behaviour"})[mode])
    }
   }
   console.log("Phase12D presentation PASS")
  }catch(e){console.error("FAIL",e,e.stack)}finally{finish.start()}}
 }
}
