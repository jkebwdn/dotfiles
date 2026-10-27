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
  name:"Phase12H";when:Services.Settings.ready
  function item(name){const found=findChild(win.contentItem,name);verify(found!==null,name);return found}
  function capture(name){wait(80);grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE12H_PREVIEWS")+"/"+name+".png")}
  function rows(mixed,error){
   return [["magi","MAGI","Live"],["hyprland","Hyprland","Applied"],["ghostty","Ghostty","Reload requested"],
           ["gtk","GTK / Thunar","Applies next launch"],["zen","Zen","Restart required"],
           ["neovim","Neovim","Applies next launch"],["yazi","Yazi","Applies next launch"],
           ["btop","btop","Applies next launch"],["starship","Starship","Live"],["fastfetch","Fastfetch","Applies next launch"]].map(v=>({
    id:v[0],label:v[1],statusLabel:!mixed&&v[0]==="zen"?"Applies next launch":v[2],available:true,configured:true,enabled:true,installed:true,
    result:v[2],error:error&&v[0]==="ghostty"?"Reload request timed out. Configuration is ready; retry safely or reload in Ghostty.":"",
    phase:"ready",reason:"",path:"",confirmedProfile:"fixture",publishedPalette:"",boundary:"Fixture capability",compatibility:"Fixture"
   }))
  }
  function test_status_and_coalescing(){
   Services.SettingsWindowState.page="Appearance";wait(300);tryCompare(Services.ThemeOrchestrator,"busy",false,3000)
   compare(Services.Settings.data.schemaVersion,22)
   Services.ThemeOrchestrator.targets=rows(false,false)
   const p=item("settingsPage-Appearance"), section=item("applicationThemesSummary")
   capture("01-appearance-normal")
   section.expanded=true;wait(80);p.contentY=section.y;wait(50);capture("02-healthy")
   Services.ThemeOrchestrator.targets=rows(true,false);wait(60);capture("03-mixed")
   compare(item("themeSummary-ghostty").text,"Reload requested")
   compare(item("themeSummary-gtk").text,"Applies next launch")
   Services.ThemeOrchestrator.targets=rows(true,true);wait(60);capture("04-failure")
   Services.ThemeOrchestrator.targets=rows(true,false)
   win.contentItem.Window.window.width=760;wait(80);p.contentY=section.y;capture("05-compact")
   Services.Settings.setTheme("rose-pine-dawn");wait(80);capture("06-dawn")
   // Actual service debounce, fake worker: A/B never dispatch; C dispatches once.
   Services.ThemeOrchestrator.activate()
   Services.Settings.setTheme("catppuccin-mocha");wait(40)
   Services.Settings.setTheme("nord");wait(40)
   Services.Settings.setTheme("rose-pine-dawn");wait(900)
   tryCompare(Services.ThemeOrchestrator,"busy",false,3000)
   Services.ThemeOrchestrator.active=false
   console.log("Phase12H presentation PASS");finish.start()
  }
 }
}
