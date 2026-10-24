import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
 FloatingWindow { id:win; visible:true; implicitWidth:1080; implicitHeight:830; color:Theme.Theme.background
  UI.SettingsContent {anchors.fill:parent}
 }
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase12G";when:Services.Settings.ready
  function item(name){const found=findChild(win.contentItem,name);verify(found!==null,name);return found}
  function capture(name){wait(80);grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE12G_PREVIEWS")+"/"+name+".png")}
  function test_background(){
   Services.SettingsWindowState.page="Applications";wait(200)
   const p=item("settingsPage-Transparency & blur"),preview=item("applicationPreview"),fg=item("applicationForeground"),bg=item("applicationBackground"),photo=item("previewOpaqueImage")
   compare(Services.Settings.data.schemaVersion,20)
   const foreground=Theme.Theme.text, surface=Theme.Theme.surface
   const localBar=Theme.Theme.statusPillBackground
   const original=JSON.parse(JSON.stringify(Services.Settings.data));delete original.applicationAppearance
   capture("01-default")
   item("applicationManaged").forceActiveFocus();keyClick(Qt.Key_Space);wait(50)
   verify(Services.Settings.data.applicationAppearance.managed);capture("02-opaque")
   const slider=item("applicationOpacity");slider.forceActiveFocus();keyClick(Qt.Key_Left);wait(50)
   compare(Services.Settings.data.applicationAppearance.backgroundOpacity,.99)
   const imageBefore=grabImage(photo)
   p.edit("backgroundOpacity",.65);p.edit("blurEnabled",false);wait(80)
   fuzzyCompare(Theme.Theme.surfaceBackground(Theme.Theme.surface).a,.65,.005)
   compare(Theme.Theme.text,foreground);compare(Theme.Theme.surface,surface)
   compare(Theme.Theme.sharedBlur,false)
   fuzzyCompare(bg.color.a,.65,.005);compare(fg.opacity,1);compare(fg.parent.opacity,1)
   verify(imageBefore.equals(grabImage(photo)),"Opaque image pixels must not change")
   verify(!item("previewBlurSample").visible);capture("03-translucent-sharp")
   const fgColor=photo.color
   item("applicationBlur").forceActiveFocus();keyClick(Qt.Key_Space);wait(80)
   compare(Theme.Theme.sharedBlur,true)
   verify(item("previewBlurSample").visible);compare(photo.color,fgColor);compare(fg.opacity,1)
   verify(imageBefore.equals(grabImage(photo)),"Blur must not change foreground image")
   capture("04-translucent-blurred")
   p.edit("backgroundOpacity",1);wait(50);capture("05-opaque-blur-on")
   p.edit("blurEnabled",false);wait(50);capture("06-opaque-blur-off")
   p.edit("backgroundOpacity",.85);p.edit("blurEnabled",true)
   item("applicationSupport").expanded=true;wait(80);capture("07-support-detail")
   item("applicationSupport").expanded=false
   for(const theme of ["catppuccin-mocha","everforest-dark-hard","rose-pine","nord","tokyo-night-moon","rose-pine-dawn"]){
    Services.Settings.setTheme(theme);wait(60);capture("theme-"+theme)
   }
   win.contentItem.Window.window.width=760;wait(100);capture("08-compact-dawn")
   win.contentItem.Window.window.width=1080;Services.Settings.setTheme(original.appearance.theme);wait(80)
   Services.ApplicationAppearanceService.error="Synthetic publish failure. Previous configuration restored."
   item("applicationAdvanced").expanded=true;wait(50);capture("09-error-detail")
   Services.ApplicationAppearanceService.error=""
   verify(Services.Settings.resetSection("applicationAppearance"));wait(50)
   compare(Services.Settings.data.applicationAppearance.managed,false)
   compare(Theme.Theme.statusPillBackground,localBar)
   compare(Theme.Theme.surfaceBackground(Theme.Theme.surface),surface)
   compare(Theme.Theme.sharedBlur,false)
   const after=JSON.parse(JSON.stringify(Services.Settings.data));delete after.applicationAppearance
   compare(after,original,"Only application appearance changes (semantic comparison)")
   tryCompare(Services.Settings,"saveState","saved",4000)
   verify(!Services.ApplicationAppearanceService.active,"Preview never activates executor")
   console.log("Phase12G presentation PASS");finish.start()
  }
 }
}
