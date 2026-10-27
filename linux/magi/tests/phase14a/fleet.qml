import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/components/tray" as Tray
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 QtObject {id:internal;property string name:"eDP-1";property int width:1280;property int height:800;property var monitor:({activeWorkspace:{id:1}})}
 QtObject {id:external;property string name:"HDMI-A-1";property int width:1280;property int height:800;property var monitor:({activeWorkspace:{id:1}})}
 Tray.TrayPreviewModel {id:fixture}
 Bar.BarFleet {id:fleet;screens:[internal,external]}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"TrayFleet";when:Services.Settings.ready && fleet.mainBar!==null
  function test_outputs(){try{
   Services.Settings.setValue('bar','externalDisplays',true)
   Services.Settings.placeBar('tray','right',0)
   Services.TrayService.items=fixture.items.concat(fixture.items)
   wait(300)
   compare(fleet.presentations.length,2)
   verify(fleet.mainBar.trayPresenter.barVisible)
   verify(!fleet.barFor(external).trayPresenter.barVisible)
   for(const lane of ['left','center','right']){
    Services.Settings.placeBar('tray',lane,0);wait(150)
    compare(Services.Settings.data.bar.left.concat(Services.Settings.data.bar.center,Services.Settings.data.bar.right).filter(x=>x==='tray').length,1)
    verify(fleet.mainBar.trayPresenter.barVisible)
   }
   fleet.focusedMonitor={name:external.name}
   verify(fleet.openFromShortcut('tray'));verify(fleet.mainBar.trayKeyboardMode)
   fleet.mainBar.close();verify(!fleet.mainBar.trayOpened)
   const previous=Services.TrayService.items
   fleet.mainBar.trayPresenter.overflowRequested();wait(50);verify(fleet.mainBar.trayOpened)
   verify(fleet.mainBar.catcherEnabled);verify(fleet.mainBar.combinedKeyboardEnabled)
   fleet.mainBar.closeActiveCombinedMenu();verify(!fleet.mainBar.trayOpened)
   fleet.mainBar.trayPresenter.overflowRequested();verify(fleet.mainBar.trayOpened)
   fleet.screens=[external];wait(250)
   compare(fleet.mainScreen,external);verify(fleet.mainBar.trayPresenter.barVisible);verify(!fleet.mainBar.trayOpened)
   compare(Services.TrayService.items,previous)
   for(const position of ['top','bottom']){
    Services.Settings.setValue('bar','position',position)
    Services.Settings.setValue('bar','edgeOffset',12);Services.Settings.setValue('bar','horizontalInset',16);wait(100)
    compare(fleet.mainBar.exclusiveZone,60)
    compare(fleet.mainBar.trayPresenter.bottomUp,position==='bottom')
   }
   Services.TrayService.items=[];wait(80);verify(!fleet.mainBar.trayPresenter.barVisible)
   Services.TrayService.items=previous;wait(80);verify(fleet.mainBar.trayPresenter.barVisible)
   fleet.screens=[];wait(150);compare(fleet.presentations.length,0);compare(Services.TrayService.items,previous)
   fleet.screens=[internal];wait(200);verify(fleet.mainBar.trayPresenter.barVisible)
   Services.Settings.placeBar('tray','hidden');wait(100);compare(fleet.mainBar.trayPresenter,null)
   console.log('Phase14A fleet PASS')
  }catch(e){console.error('FAIL',e,e.stack)}finally{finish.start()}}
 }
}
