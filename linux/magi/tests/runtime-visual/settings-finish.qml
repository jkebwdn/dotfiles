import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/components/settings/SettingsFeedback.js" as Feedback
import "../../.config/quickshell/magi/components/lockPresentation/LockLayout.js" as Model
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1000;implicitHeight:720;color:Theme.Theme.background
  UI.SettingsContent {id:content;anchors.fill:parent}
 }
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"SettingsFinish";when:Services.Settings.ready
  function item(name) {const value=findChild(content,name);verify(value!==null,name);return value}
  function page(name) {Services.SettingsWindowState.page=name;waitForPolish(win.contentItem.Window.window);return item("settingsPage-"+name)}
  function capture(name) {const dir=Quickshell.env("MAGI_SETTINGS_FINISH_CAPTURES");if(dir) {
    const nav=item("settingsNav-"+Services.SettingsWindowState.page)
    nav.forceActiveFocus(Qt.TabFocusReason)
    const section=findChild(content,"barFamilyInspector")
    if(section&&section.visible)tryVerify(()=>section.children.filter(child=>child.visible).every(child=>child.opacity===1))
    waitForRendering(content);grabImage(content).save(dir+"/"+name+".png")} }
  function test_finish() {try {
   const original=JSON.parse(JSON.stringify(Services.Settings.data))
   compare(content.navigationGroups.map(g=>g.title),["Personalisation","Desktop","Everyday tools","Session & hardware"])
   compare(content.navigationPages.length,16)
   compare(new Set(content.navigationPages).size,16)
   for(const group of content.navigationGroups) {
    const heading=item("settingsGroup-"+group.title)
    compare(heading.text,group.title);verify(!heading.activeFocusOnTab)
   }
   Services.SettingsWindowState.page="Displays"
   const navView=item("settingsNavigation"),last=item("settingsNav-Displays")
   tryVerify(()=>last.mapToItem(navView,0,0).y+last.height<=navView.height+1)
   content.Window.window.height=500;tryCompare(content,"height",500)
   tryVerify(()=>last.mapToItem(navView,0,0).y+last.height<=navView.height+1,1000,"Resize reveals selected destination")
   for(const theme of ["kanagawa-wave","one-light"]) {
    Services.Settings.setTheme(theme);tryCompare(Services.Settings,"saveState","saved")
    const revision=Services.Settings.revision
    for(const size of [Qt.size(720,500),Qt.size(1000,720),Qt.size(1280,900)]) {
     content.Window.window.width=size.width;content.Window.window.height=size.height;tryCompare(content,"width",size.width)
     for(const id of content.navigationPages) {
      Services.SettingsWindowState.page=id;waitForPolish(win.contentItem.Window.window)
      const nav=item("settingsNav-"+id);verify(nav.checked)
      nav.forceActiveFocus(Qt.TabFocusReason);waitForPolish(win.contentItem.Window.window)
      const viewport=item("settingsNavigation"),point=nav.mapToItem(viewport,0,0)
      verify(point.y>=-.1&&point.y+nav.height<=viewport.height+1,"Navigation revealed: "+id)
      verify(nav.Accessible.name.length>0)
     }
     const first=item("settingsNav-Appearance");first.forceActiveFocus();keyClick(Qt.Key_Down)
     verify(item("settingsNav-Wallpaper").activeFocus);keyClick(Qt.Key_Return)
     compare(Services.SettingsWindowState.page,"Wallpaper")
     keyClick(Qt.Key_Up);verify(first.activeFocus)
     const lock=page("Lock Screen");lock.contentY=0;waitForPolish(win.contentItem.Window.window)
     const canvas=item("lockThemeLivePreview"),gallery=item("lockThemeGallery")
     verify(!canvas.interactive,"Normal preview is read-only")
     verify(Math.abs(canvas.width/canvas.height-canvas.aspect)<.01,"Preview retains aspect ratio")
     verify(gallery.columns>=1&&gallery.columns<=4)
     verify(findChild(lock,"lockElementInspector")===null,"No freeform controls in normal Settings")
     capture(theme+"-"+size.width+"-lock")
     const bar=page("Bar");bar.mode="Appearance";bar.contentY=0
     bar.selection.select("statusPills");waitForPolish(win.contentItem.Window.window)
     verify(item("barSelectionContext").text.includes("Shared style"));verify(!item("barIdentityInspector").visible)
     capture(theme+"-"+size.width+"-bar-group")
     bar.selection.select("wifi");waitForPolish(win.contentItem.Window.window)
     verify(item("barSelectionContext").text.includes("Selected item"));verify(item("barIdentityInspector").visible)
     compare(item("barFamilyInspector").expanded,false)
     capture(theme+"-"+size.width+"-bar-item")
    }
    compare(Services.Settings.revision,revision,"Navigation, disclosures and selection do not save")
   }
   // Native model safety is unchanged by editor composition.
   const unsafe=Model.copy(Model.preset("centered"));unsafe.elements.authentication.visible=false;unsafe.elements.authentication.size=.1
   const safe=Model.normalize(unsafe);verify(safe.elements.authentication.visible);verify(safe.elements.authentication.size>=1)
   compare(Feedback.save("saved"),"All changes saved");compare(Feedback.save("pending"),"Saving…")
   verify(Feedback.save("conflict").includes("Reload"));verify(Feedback.save("error").includes("Could not save"))
   compare(Feedback.attention([{enabled:true,label:"MAGI",statusLabel:"Live"}],"",false,"saved"),"")
   compare(Feedback.attention([],"",true,"pending"),"Updating application themes…")
   verify(Feedback.attention([{enabled:true,label:"Zen",statusLabel:"Restart required"}],"",false,"saved").includes("Your choice is saved. Restart Zen"))
   verify(!Feedback.attention([],"failed",false,"pending").includes("saved"))
   compare(Feedback.appearance("applied",true,"saved"),"")
   verify(Feedback.appearance("reload_required",true,"saved").includes("Reload Ghostty"))
   const appearance=page("Appearance");appearance.contentY=0
   Services.ThemeOrchestrator.targets=[{id:"zen",label:"Zen",enabled:true,available:true,configured:true,installed:true,statusLabel:"Restart required",result:"Restart Zen",error:""}]
   tryVerify(()=>item("applicationThemeAttention").text.includes("Restart Zen"))
   verify(item("applicationThemeReview").visible)
   capture("feedback-restart")
   item("applicationThemeReview").clicked();tryCompare(item("applicationThemesSummary"),"expanded",true)
   Services.ThemeOrchestrator.error="Synthetic diagnostic"
   tryVerify(()=>item("applicationThemeAttention").text.includes("could not update"))
   verify(!item("applicationThemeAttention").text.includes("Synthetic diagnostic"))
   appearance.contentY=0;capture("feedback-error")
   Services.ThemeOrchestrator.error="";Services.ThemeOrchestrator.targets=[]
   Services.Settings.setTheme(original.appearance.theme);tryCompare(Services.Settings,"saveState","saved")
   compare(Services.Settings.data,original)
   console.log("Settings finish PASS: grouped routes, keyboard, responsive editor, ownership, feedback and persistence")
   finish.start()
  }catch(e){console.error("FAIL:",e,e.stack);finish.start();throw e}}
 }
}
