import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1100;implicitHeight:1000;color:"#1e1e2e";UI.SettingsContent {anchors.fill:parent}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"DisplayPreview"
  when:Services.Settings.ready
  function request(value) {Services.Displays.send(value);wait(250)}
  function capture(name){wait(200);grabImage(win.contentItem).save(Quickshell.env("MAGI_DISPLAY_PREVIEWS")+"/"+name+".png")}
  function test_page() {
   try {
    Services.SettingsWindowState.page="Displays";tryVerify(()=>Services.Displays.state.proposed.length===2,5000)
    const page=findChild(win.contentItem,"settingsPage-Displays"),canvas=findChild(page,"displayCanvas")
    verify(page && page.visible);verify(canvas);compare(Services.Displays.state.authoritative,false)
    capture("dual")
    request({op:"select",name:"HDMI-A-1"});capture("external")
    let rect=findChild(canvas,"displayRect-HDMI-A-1")
    const original=Services.Displays.selected.x
    // Actual pointer drag right, preserving separation; conversion happens once on drop.
    const start=rect.mapToItem(canvas,rect.width/2,rect.height/2), factor=canvas.factor
    mousePress(canvas,start.x,start.y)
    mouseMove(canvas,start.x+40,start.y,100)
    mouseRelease(canvas,start.x+40,start.y)
    wait(350);compare(Services.Displays.state.selected,"HDMI-A-1");compare(Services.Displays.selected.x,Math.round(original+40/factor))
    request({op:"reset"});compare(Services.Displays.selected.x,original)
    request({op:"save",name:"Office"});compare(Services.Displays.state.profiles.length,1)
    page.contentY=Math.max(0,page.contentHeight-page.height);capture("profiles")
    request({op:"apply"});compare(Services.Displays.state.transaction.state,"pending");capture("confirmation")
    const token=Services.Displays.state.transaction.token
    request({op:"keep",token:token});compare(Services.Displays.state.transaction.state,"kept")
    request({op:"fixture",name:"Laptop"});compare(Services.Displays.state.proposed.length,1)
    request({op:"reset"});page.contentY=0;capture("laptop")
    request({op:"profile",id:Services.Displays.state.profiles[0].id});verify(Services.Displays.state.warnings.length>0)
    page.contentY=Math.min(250,page.contentHeight-page.height);capture("missing")
    request({op:"reset"});request({op:"fixture",name:"Dual"});request({op:"reset"})
    request({op:"edit",key:"enabled",value:false});compare(Services.Displays.state.selected,"HDMI-A-1")
    request({op:"edit",key:"enabled",value:false});verify(Services.Displays.state.error.length>0)
    console.log("Display UI drag, selection, profiles, confirmation and degraded state PASS")
   } catch(e) {console.error("FAIL",e,e.stack)}
   finish.start()
  }
 }
}
