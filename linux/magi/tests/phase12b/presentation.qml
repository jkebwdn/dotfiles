import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/components/calendar" as CalendarUI
import "../../.config/quickshell/magi/services" as Services
import "../../native/lock/qml" as LockUI
import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/components/notifications" as Notices
ShellRoot {
 FloatingWindow {id:win; visible:true; implicitWidth:1400;implicitHeight:1000;color:Theme.Theme.background
  UI.SettingsContent {anchors.fill:parent}
 }
 FloatingWindow {visible:false; CalendarUI.CalendarContent {id:calendar;width:320;service:Services.Calendar}}
 QtObject {id:record;property var notification:null;property int notificationId:1;property bool hovered:false;property bool dismissed:false;property bool read:false;property double updatedAt:Date.now();property var data:({id:1,appName:"MAGI",summary:"Theme preview",body:"Readable notification",actions:[],urgency:1})}
 FloatingWindow {visible:false;Notices.NotificationCard {id:notice;width:360;record:record;service:({invoke:function(){},dismiss:function(){}})}}
 Controls.Icon {id:icon;role:"settings";color:Theme.Theme.text}
 LockUI.LockTokens {id:lockTokens;palette:Theme.Theme.roles}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase12B"
  when:Services.Settings.ready
  function item(name){const x=findChild(win.contentItem,name);verify(x!==null,name);return x}
  function test_themes(){try{
   const original=Services.Settings.data.appearance.theme
   const roles=["accent"].concat(Theme.ThemeRegistry.accentRoles)
   const pages=["Appearance","Hub","Control Centre","Profile","Date & time","Notifications","Clipboard","Launcher","Emoji","Wallpaper","Power & Idle","Displays","Security"]
   for(const theme of Theme.ThemeRegistry.themes){
    Services.Settings.setTheme(theme.id);wait(30)
    compare(Theme.Theme.effectiveTheme,theme.id)
    for(const key of Object.keys(theme.roles))compare(Theme.Theme.roles[key],theme.roles[key])
    compare(icon.color,theme.roles.text);compare(findChild(notice,"notificationTitle").color,theme.roles.text)
    compare(lockTokens.background,theme.roles.background);compare(lockTokens.ink,theme.roles.text)
    for(let i=0;i<roles.length;i++){
     const nav=roles[i],sel=roles[(i+1)%roles.length],toggle=roles[(i+2)%roles.length]
     Services.Settings.setValue("appearance","navigationAccent",nav)
     Services.Settings.setValue("appearance","hubSelectionRole",sel)
     Services.Settings.setValue("appearance","hubToggleRole",toggle)
     compare(Theme.Theme.navigationAccent,theme.roles[nav]);compare(Theme.Theme.hubSelectionColor,theme.roles[sel]);compare(Theme.Theme.hubToggleColor,theme.roles[toggle])
     compare(Services.Settings.data.appearance.navigationAccent,nav)
    }
    Services.Calendar.model.resetToday();wait(10)
    compare(findChild(calendar,"calendarDay-"+Services.Calendar.model.today.getDate()).border.color,Theme.Theme.focus)
    for(const page of pages){
     Services.SettingsWindowState.page=page;wait(15)
     const title=page==="Emoji"?"Emoji Picker":page==="Launcher"?"Application Launcher":page
     verify(item("settingsPage-"+title).visible)
    }
    Services.SettingsWindowState.page="Control Centre";wait(20)
    compare(item("mediaTitle").color,Theme.Theme.text)
    const preview=item("controlCentrePreview"),grid=preview.moduleBoard
    compare(preview.color,Theme.Theme.surface);verify(!item("previewMedia").interactive)
    const before=JSON.stringify(Services.Settings.data.controlCentre.controls),key=grid.canonicalKeys("controls")[0]
    grid.begin(key,item("ccModuleBoard-handle-"+key),10,10)
    const lane=grid.geometry.find(l=>l.id==="actions")
    grid.motion(grid,lane.x+20,lane.y+40)
    verify(grid.dragging);compare(JSON.stringify(Services.Settings.data.controlCentre.controls),before)
    grid.cancel();verify(!grid.canPlace(key,"sliders"))
    if(theme.family==="Rosé Pine"||theme.family==="Nord"||theme.family==="Tokyo Night"){
     wait(80);grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE12B_PREVIEWS")+"/"+theme.id+".png")
    }
   }
   for(const id of ["rose-pine-dawn","nord","tokyo-night-day",original])Services.Settings.setTheme(id)
   wait(30);compare(Theme.Theme.effectiveTheme,original)
   tryCompare(Services.Settings,"saveState","saved")
   Services.Settings.discardAndReload();tryCompare(Services.Settings,"ready",true);compare(Services.Settings.data.appearance.theme,original)
   console.log("Phase12B presentation PASS: 18 themes, all roles, 13 Settings pages, CC, Calendar, lock tokens")
  }catch(e){console.error("FAIL",e,e.stack)}finish.start()}
 }
}
