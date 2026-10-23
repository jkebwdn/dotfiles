import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 FloatingWindow { id:win;visible:true;implicitWidth:1450;implicitHeight:950;color:Theme.Theme.background;UI.SettingsContent { anchors.fill:parent } }
 Timer { id:finish;interval:100;onTriggered:Qt.quit() }
 TestCase {
  name:"Phase12C";when:Services.Settings.ready
  function item(name){const x=findChild(win.contentItem,name);verify(x!==null,name);return x}
  function capture(name){wait(160);grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE12C_PREVIEWS")+"/"+name+".png")}
  function test_editor(){
   try {
    Services.SettingsWindowState.page="Bar";wait(300)
    verify(!Services.SettingsWindowState.inAppearance)
    const page=item("settingsPage-Bar"),canvas=item("barCanvas"),board=item("barOrder")
    capture("layout");capture("available")
    const original=JSON.stringify(Services.Settings.data.bar), originalRevision=Services.Settings.revision
    // A real pointer gesture crosses regions. Motion must not publish settings.
    const handle=item("barOrder-handle-wifi"),target=board.geometry.find(l=>l.id==="left")
    mousePress(handle,14,14,Qt.LeftButton)
    mouseMove(board,target.x+15,target.y+50,40);wait(30)
    verify(board.dragging);compare(JSON.stringify(Services.Settings.data.bar),original)
    capture("dragging")
    mouseRelease(board,target.x+15,target.y+50,Qt.LeftButton);wait(180)
    verify(Services.Settings.data.bar.left.includes("wifi"));verify(!Services.Settings.data.bar.right.includes("wifi"));compare(Services.Settings.revision,originalRevision+1)
    // Available -> Bar, Bar -> Available, singleton and empty-region semantics.
    for(const id of ["notifications","clipboard"]){Services.Settings.placeBar(id,"left",0);compare(Services.Settings.data.bar.left[0],id)}
    for(const lane of ["left","center","right"]){
     Services.Settings.placeBar("wifi",lane,0);Services.Settings.placeBar("bluetooth",lane,1)
     board.request("bluetooth",lane,0,true);compare(Services.Settings.data.bar[lane][0],"bluetooth")
     compare(Services.Settings.data.bar.left.concat(Services.Settings.data.bar.center,Services.Settings.data.bar.right).filter(x=>x==="wifi").length,1)
    }
    Services.Settings.placeBar("wifi","hidden");verify(!canvas.placed.includes("wifi"))
    verify(!Services.Settings.placeBar("bogus","left"))
    // Stale gesture cancellation before a release can overwrite the newer order.
    Services.Settings.placeBar("wifi","right");wait(150)
    const h=item("barOrder-handle-wifi")
    mousePress(h,14,14,Qt.LeftButton);mouseMove(board,30,50,40);verify(board.dragging)
    Services.Settings.placeBar("wifi","center",0);wait(20);verify(!board.dragging)
    mouseRelease(board,30,50,Qt.LeftButton);verify(Services.Settings.data.bar.center.includes("wifi"))
    const grip=item("barOrder-handle-wifi");grip.forceActiveFocus();keyClick(Qt.Key_Right,Qt.AltModifier);wait(150)
    verify(Services.Settings.data.bar.right.includes("wifi"))
    for(const lane of ["left","center","right"])Services.Settings.setValue("bar",lane,[])
    compare(canvas.placed.length,0)
    Services.Settings.resetSection("bar");wait(100)
    page.mode="Colours & Look";page.selection.select("");capture("host")
    const inspector=item("barFamilyInspector")
    const before=JSON.stringify(Services.Settings.data)
    const activeMenu=Services.MenuController.activeMenu
    mouseClick(item("barOrder-row-wifi"),15,15)
    compare(page.selection.instance,"wifi");compare(Services.MenuController.activeMenu,activeMenu)
    compare(JSON.stringify(Services.Settings.data),before)
    compare(page.selection.family,"statusPills");verify(item("barIdentityInspector").visible);verify(item("barMenuInspector").visible)
    const modules=JSON.parse(JSON.stringify(Services.Settings.data.bar.modules));modules.wifi.accentRole="red";modules.bluetooth.accentRole="lavender";Services.Settings.setValue("bar","modules",modules)
    Services.Settings.setRoundness("barPill",1.4)
    let visual=JSON.parse(JSON.stringify(Services.Settings.data.bar.visual));visual.statusPills.opacity=.55;Services.Settings.setValue("bar","visual",visual)
    compare(Theme.Theme.barAccent("wifi"),Theme.Theme.roles.red);compare(Theme.Theme.barAccent("bluetooth"),Theme.Theme.roles.lavender)
    compare(item("barPreview-wifi").presenter.radius,item("barPreview-bluetooth").presenter.radius)
    compare(item("barPreview-wifi").presenter.color,item("barPreview-bluetooth").presenter.color)
    verify(Math.abs(item("barPreview-wifi").presenter.color.a-.55)<.01)
    capture("wifi")
    page.selection.select("bluetooth");compare(page.selection.family,"statusPills");capture("bluetooth")
    page.selection.select("workspaces");compare(page.selection.family,"workspacePills");capture("workspace")
    let workspaceStyle=JSON.parse(JSON.stringify(Services.Settings.data.bar.visual));workspaceStyle.workspacePills.roundness=.5
    Services.Settings.setValue("bar","visual",workspaceStyle)
    compare(item("barPreview-workspaces").presenter.radius,4)
    compare(item("barPreview-wifi").presenter.radius,Theme.Theme.barPillRadius)
    const cells=item("barPreview-workspaces").presenter.children[0].children.filter(c=>c.radius!==undefined)
    compare(cells.length,3);for(const cell of cells)compare(cell.radius,4)
    page.selection.select("");visual=JSON.parse(JSON.stringify(Services.Settings.data.bar.visual));visual.host.enabled=true;visual.host.role="elevated";visual.host.opacity=.8;Services.Settings.setValue("bar","visual",visual);verify(Math.abs(item("barPreviewHost").color.a-.8)<.01);capture("background")
    visual=JSON.parse(JSON.stringify(visual));visual.statusPills.enabled=false;Services.Settings.setValue("bar","visual",visual);compare(Theme.Theme.statusPillBackground.a,0);capture("pills-off")
    for(const theme of ["catppuccin-mocha","everforest-dark-hard","rose-pine","nord","tokyo-night-moon","rose-pine-dawn"]){Services.Settings.setTheme(theme);capture(theme)}
    page.mode="Behaviour";Services.Settings.setValue("bar","position","bottom");Services.Settings.setValue("bar","horizontalInset",24);Services.Settings.setValue("bar","edgeOffset",12);capture("behaviour")
    page.mode="Colours & Look";page.selection.select("wifi");win.contentItem.Window.window.width=720;win.contentItem.Window.window.height=900;wait(200);capture("compact")
    verify(page.contentWidth<=page.width);verify(canvas.width<=page.width)
    win.contentItem.Window.window.width=1100;capture("normal")
    page.selection.select("wifi");Services.Settings.placeBar("wifi","hidden");compare(page.selection.scope,"host")
    tryCompare(Services.Settings,"saveState","saved")
    wait(200)
    const persisted=JSON.stringify(Services.Settings.data.bar), persistedRoundness=Services.Settings.data.appearance.roundness.roles.barPill
    Services.Settings.setRoundness("barPill",.25)
    Services.Settings.placeBar("wifi","left",0)
    verify(Services.Settings.discardAndReload());tryCompare(Services.Settings,"ready",true)
    compare(JSON.stringify(Services.Settings.data.bar),persisted);compare(Services.Settings.data.appearance.roundness.roles.barPill,persistedRoundness)
    console.log("Phase12C presentation PASS")
   } catch(e) {console.error("FAIL",e,e.stack)} finally {finish.start()}
  }
 }
}
