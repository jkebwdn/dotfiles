import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"ApplicationAppearanceLifecycle";when:Services.Settings.ready
  function policy(a){Services.Settings.setValue("applicationAppearance","managed",true);Services.Settings.setValue("applicationAppearance","backgroundOpacity",a)}
  function test_lifecycle(){
   policy(.95);Services.ApplicationAppearanceService.activate()
   tryCompare(Services.ApplicationAppearanceService,"status","reload-required",4000)
   compare(Services.ApplicationAppearanceService.outcome.outcome.calls,1)
   policy(.94);policy(.93);policy(.92)
   wait(100);compare(Services.ApplicationAppearanceService.outcome.outcome.calls,1)
   tryVerify(()=>Services.ApplicationAppearanceService.outcome.outcome.calls===2,4000)
   compare(Services.ApplicationAppearanceService.outcome.outcome.backgroundOpacity,.92)
   Services.ApplicationAppearanceService.schedule()
   Services.ApplicationAppearanceService.schedule()
   tryVerify(()=>Services.ApplicationAppearanceService.outcome.outcome.calls===3,4000)
   policy(.51);tryCompare(Services.ApplicationAppearanceService,"status","unavailable",4000)
   compare(Services.Settings.data.applicationAppearance.backgroundOpacity,.51)
   policy(.9);tryCompare(Services.ApplicationAppearanceService,"status","reload-required",4000)
   Services.Settings.resetSection("applicationAppearance");tryCompare(Services.ApplicationAppearanceService,"status","released",4000)
   wait(600);verify(!Services.ApplicationAppearanceService.busy)
   console.log("Phase12G lifecycle PASS");finish.start()
  }
 }
}
