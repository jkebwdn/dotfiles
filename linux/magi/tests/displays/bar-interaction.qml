import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 QtObject {id:internal;property string name:"eDP-1";property int width:1920;property int height:1080;property var monitor:({activeWorkspace:{id:1}})}
 QtObject {id:external;property string name:"HDMI-A-1";property int width:2560;property int height:1440;property var monitor:({activeWorkspace:{id:2}})}
 QtObject {id:reconnected;property string name:"HDMI-A-1";property int width:2560;property int height:1440;property var monitor:({activeWorkspace:{id:2}})}
 BarUI.BarFleet {id:fleet;screens:[internal]}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"DisplayBarInteraction"
  when:Services.Settings.ready && !!fleet.mainBar
  function test_lifecycle(){
   try {
    Services.Displays.active=true;tryVerify(()=>Services.Displays.state.observed.length===2,5000)
    Services.Settings.setValue("bar","externalDisplays",true);wait(400)
    // Only the isolated harness projects simulated outputs to screen objects.
    // Production Displays never writes BarFleet.screens or SurfaceOrigin.
    fleet.screens=[internal,external];wait(500);compare(fleet.presentations.length,2)
    fleet.focusedMonitor={name:"HDMI-A-1"};verify(fleet.openFromShortcut("controlcentre"));wait(500)
    compare(Services.SurfaceOrigin.menuTarget(),external)
    Services.Displays.send({op:"fixture",name:"Laptop"});tryVerify(()=>Services.Displays.state.observed.length===1,3000)
    compare(Services.Displays.state.observed.length,1);fleet.screens=[internal];wait(500)
    compare(fleet.presentations.length,1);compare(Services.MenuController.activeMenu,"");compare(Services.SurfaceOrigin.shortcutTarget(),internal)
    Services.Displays.send({op:"fixture",name:"Dual"});wait(250);compare(Services.Displays.state.observed.length,2)
    fleet.screens=[internal,reconnected];wait(500);compare(fleet.presentations.length,2)
    compare(fleet.mainScreen,internal);compare(fleet.barFor(reconnected).exclusiveZone,48)
    const strip=findChild(fleet.barFor(reconnected).contentItem,"workspaceStrip");compare(strip.activeWorkspace.id,2)
    console.log("Display model to Phase 10B lifecycle PASS")
   } catch(e){console.error("FAIL:",e,e.stack)}
   finish.start()
  }
 }
}
