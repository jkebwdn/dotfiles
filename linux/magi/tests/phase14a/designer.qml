import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1450;implicitHeight:950;color:Theme.Theme.background;UI.SettingsContent {anchors.fill:parent}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"TrayDesigner";when:Services.Settings.ready
  function item(name){const value=findChild(win.contentItem,name);verify(value!==null,name);return value}
  function test_designer(){try{
   Services.SettingsWindowState.page='Bar';wait(250)
   const board=item('barOrder'),canvas=item('barCanvas'),page=item('settingsPage-Bar')
   verify(!canvas.placed.includes('tray'))
   for(const lane of ['left','center','right','hidden']){
    const handle=item('barOrder-handle-tray'),target=board.geometry.find(l=>l.id===lane)
    mousePress(handle,14,14,Qt.LeftButton)
    mouseMove(board,target.x+15,target.y+50,40);wait(30);verify(board.dragging)
    mouseRelease(board,target.x+15,target.y+50,Qt.LeftButton);wait(180)
    if(lane==='hidden')verify(!canvas.placed.includes('tray'))
    else {verify(Services.Settings.data.bar[lane].includes('tray'));compare(canvas.placed.filter(x=>x==='tray').length,1)}
   }
   Services.Settings.placeBar('tray','right',0);wait(100)
   page.mode='Appearance';page.selection.select('tray');wait(100)
   compare(page.selection.family,'statusPills');verify(!item('barInstanceAccent').visible)
   page.selection.select('statusPills');wait(100);verify(item('barFamilyInspector').expanded)
   grabImage(win.contentItem).save(Quickshell.env('MAGI_PHASE14A_PREVIEWS')+'/designer.png')
   console.log('Phase14A designer PASS')
  }catch(e){console.error('FAIL',e,e.stack)}finally{finish.start()}}
 }
}
