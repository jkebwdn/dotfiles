import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/hub" as HubUI
import "../../.config/quickshell/magi/components/calendar" as CalendarUI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
 BarUI.Bar {id:bar;expandableHostMode:"combined"}
 HubUI.HubWindow {id:hub;readyToOpen:bar.settingsReady;previewSurface:bar.activeCombinedRegion}
 FloatingWindow {visible:true;implicitWidth:360;implicitHeight:450;CalendarUI.CalendarContent {anchors.fill:parent;service:Services.Calendar}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase12BSurfaces"
  when:Services.Settings.ready
  function test_surfaces(){try{
   Services.Media.available=true;Services.Media.title="Synthetic track";Services.Media.artist="Preview artist"
   for(const theme of Theme.ThemeRegistry.themes){
    Services.Settings.setTheme(theme.id);wait(20)
    for(const mode of Services.Hub.modes){
     Services.Hub.open(mode);tryCompare(hub,"visible",true);wait(35)
     verify(hub.content.currentContent.visible)
     compare(Theme.Theme.background,theme.roles.background)
    }
    Services.Hub.close();wait(30)
    Services.MenuController.open("controlcentre");tryCompare(bar.expandablePillRegistry.controlcentre,"phase",3)
    const mediaTitle=findChild(bar.contentItem,"mediaTitle");verify(mediaTitle!==null);compare(mediaTitle.color,Theme.Theme.text)
    Services.MenuController.close();tryCompare(bar.expandablePillRegistry.controlcentre,"phase",0)
   }
   compare(Services.QuickActions.executed.length,0)
   console.log("Phase12B surfaces PASS")
  }catch(e){console.error("FAIL:",e,e.stack)}finish.start()}
 }
}
