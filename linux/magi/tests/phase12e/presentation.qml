import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1080;implicitHeight:780;color:Theme.Theme.background;UI.SettingsContent {anchors.fill:parent}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase12E";when:Services.Settings.ready
  function item(n){const x=findChild(win.contentItem,n);verify(x!==null,n);return x}
  function capture(n){win.contentItem.opacity=.999;wait(30);win.contentItem.opacity=1;wait(120);grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE12E_PREVIEWS")+"/"+n+".png")}
  function test_editor(){try{
   Services.SettingsWindowState.page="Hub";wait(350)
   const page=item("settingsPage-Hub"),preview=item("hubEditorPreview"),inspector=item("hubEditorInspector")
   verify(!Services.SettingsWindowState.inAppearance);verify(item("settingsNav-Hub").checked)
   const initial=JSON.stringify(Services.Settings.data),hubMode=Services.Hub.mode
   capture("hub-layout")
   for(const mode of ["apps","clipboard","notifications","emoji","settings"]){preview.mode=mode;wait(50);mouseClick(preview.surface,30,30);capture("hub-"+mode)}
   for(let i=0;i<5;++i){mouseClick(preview.selector.modeButtons.itemAt(i));compare(preview.mode,["apps","clipboard","notifications","emoji","settings"][i]);compare(page.selection.instance,"selector")}
   mouseClick(item("settingsToggle-Sample enabled preference"));compare(page.selection.instance,"toggles");compare(item("settingsToggle-Sample enabled preference").checked,true)
   compare(JSON.stringify(Services.Settings.data),initial);compare(Services.Hub.mode,hubMode)
   page.mode="Colours & Look"
   for(const key of ["","selector","toggles"]){page.selection.select(key);preview.mode=key==="toggles"?"settings":"apps";capture("hub-"+(key||"host"))}
   compare(JSON.stringify(Services.Settings.data),initial)
   const toggle=Theme.Theme.hubToggleColor,nav=Theme.Theme.navigationAccent
   Services.Settings.setValue("appearance","hubSelectionRole","teal");compare(Theme.Theme.hubToggleColor,toggle);compare(Theme.Theme.navigationAccent,nav)
   const selection=Theme.Theme.hubSelectionColor
   Services.Settings.setValue("appearance","hubToggleRole","red");compare(Theme.Theme.hubSelectionColor,selection);compare(Theme.Theme.navigationAccent,nav)
   Services.Settings.setValue("appearance","navigationAccent","blue");compare(Theme.Theme.hubSelectionColor,selection);compare(Theme.Theme.hubToggleColor,Theme.Theme.red);compare(item("settingsToggle-Sample enabled preference").activeColor,Theme.Theme.red)
   for(const style of ["pill","filled","minimal"]){Services.Settings.setValue("appearance","toggleStyle",style);wait(20);compare(item("settingsToggle-Sample enabled preference").toggleStyle,style)}
   for(const pos of ["above","below"]){Services.Settings.setValue("hub","selectorPosition",pos);wait(30);compare(preview.selector.y<preview.surface.y,pos==="above")}
   page.mode="Layout";Services.Settings.setValue("hub","verticalPosition",.2);Services.Settings.setValue("hub","selectorPosition","above");capture("hub-above")
   Services.Settings.setValue("hub","selectorPosition","below");page.mode="Colours & Look";page.selection.select("selector");preview.mode="apps"
   for(const theme of ["catppuccin-mocha","everforest-dark-hard","rose-pine","nord","tokyo-night-moon","rose-pine-dawn"]){Services.Settings.setTheme(theme);capture(theme)}
   // Production border overlays consume the same shared token; feature flags remain independent.
   const borderBefore=Services.Settings.data.appearance.notificationBorders
   Services.Settings.setValue("appearance","notificationBorders",Object.assign({},borderBefore,{role:"red",width:3,toasts:true,history:true,clipboard:true}))
   Services.SettingsWindowState.page="Notifications";wait(100)
   const notifications=item("settingsPage-Notifications"),toastToggle=item("settingsToggle-Toast borders")
   notifications.contentY=Math.max(0,toastToggle.mapToItem(notifications.contentItem,0,0).y-80);wait(50)
   mouseClick(toastToggle);compare(Services.Settings.data.appearance.notificationBorders.toasts,false)
   compare(Services.Settings.data.appearance.notificationBorders.history,true);compare(Services.Settings.data.appearance.notificationBorders.clipboard,true)
   const card=findChild(notifications,"notificationStylePreview"),outline=card.children.find(c=>c.family==="notificationBorders")
   verify(outline!==undefined);tryCompare(outline.border,"width",0);compare(outline.border.color,Theme.Theme.red)
   Services.SettingsWindowState.page="Clipboard";wait(100)
   const clipboardPage=item("settingsPage-Clipboard"),clipToggle=item("settingsToggle-Clipboard card borders")
   clipboardPage.contentY=Math.max(0,clipToggle.mapToItem(clipboardPage.contentItem,0,0).y-80);wait(50)
   mouseClick(clipToggle);compare(Services.Settings.data.appearance.notificationBorders.clipboard,false)
   compare(Services.Settings.data.appearance.notificationBorders.history,true)
   Services.Settings.setValue("appearance","notificationBorders",borderBefore)
   notifications.contentY=0;clipboardPage.contentY=0
   for(const target of ["Notifications","Clipboard","Appearance"]){Services.SettingsWindowState.page=target;wait(180);capture(target.toLowerCase())}
   const appearance=item("settingsPage-Appearance");appearance.contentY=Math.max(0,appearance.contentHeight-appearance.height);capture("appearance-shared");appearance.contentY=0
   Services.SettingsWindowState.page="Hub";Services.Settings.setTheme("catppuccin-mocha");wait(100)
   for(const size of [Qt.size(1450,1000),Qt.size(1080,780),Qt.size(720,500)]){
    win.contentItem.Window.window.width=size.width;win.contentItem.Window.window.height=size.height;wait(100)
    for(const mode of ["Layout","Colours & Look","Behaviour"]){page.mode=mode;wait(50);verify(preview.sceneHeight*preview.fitScale<=preview.height+1);verify(preview.sceneWidth*preview.fitScale<=preview.width+1);if(size.width>=720)verify(inspector.mapToItem(page,0,0).x>=preview.mapToItem(page,preview.width,0).x);capture("fit-"+size.width+"-"+mode.replace(/ /g,"-"))}
   }
   tryCompare(Services.Settings,"saveState","saved");wait(200)
   const saved=JSON.stringify(Services.Settings.data)
   Services.Settings.setValue("appearance","hubToggleRole","green");Services.Settings.setValue("hub","selectorPosition","above")
   verify(Services.Settings.discardAndReload());tryCompare(Services.Settings,"ready",true);compare(JSON.stringify(Services.Settings.data),saved)
   console.log("Phase12E presentation PASS")
  }catch(e){console.error("FAIL",e,e.stack)}finally{finish.start()}}
 }
}
