import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase12BSwitching"
  when:Services.Settings.ready
  function idle(){tryCompare(Services.ThemeOrchestrator,"busy",false,10000);wait(100);tryCompare(Services.ThemeOrchestrator,"busy",false,10000);verify(!Services.ThemeOrchestrator.error,Services.ThemeOrchestrator.error)}
  function ghost(){return Services.ThemeOrchestrator.targets.find(t=>t.id==="ghostty")}
  function test_requests(){try{
   const original=Services.Settings.data.appearance.theme
   Services.ThemeOrchestrator.activate();idle()
   Services.ThemeOrchestrator.preview("ghostty","");idle();verify(Services.ThemeOrchestrator.plan!==null)
   Services.ThemeOrchestrator.enable();idle();verify(ghost().enabled)
   for(const theme of Theme.ThemeRegistry.themes){
    Services.Settings.setTheme(theme.id);idle()
    compare(ghost().publishedPalette,theme.id);compare(Theme.Theme.effectiveTheme,theme.id)
   }
   // Force changes while a worker is pending; late output must not replace latest selection.
   Services.Settings.setTheme("rose-pine-dawn")
   Services.ThemeOrchestrator.drain()
   verify(Services.ThemeOrchestrator.busy)
   Services.Settings.setTheme("nord");Services.Settings.setTheme("tokyo-night-day");Services.Settings.setTheme(original)
   idle();compare(ghost().publishedPalette,original);compare(Theme.Theme.effectiveTheme,original)
   Services.ThemeOrchestrator.disable("ghostty");idle();verify(!ghost().enabled)
   console.log("Phase12B switching PASS: sequential and busy-worker last-request-wins")
  }catch(e){console.error("FAIL",e,e.stack)}finish.start()}
 }
}
