import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1100;implicitHeight:1000;color:Theme.Theme.background;UI.SettingsContent {anchors.fill:parent}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"FingerprintSettings"
  when:Services.Settings.ready
  function capture(name){wait(150);grabImage(win.contentItem).save(Quickshell.env("MAGI_FINGERPRINT_PREVIEWS")+"/"+name+".png")}
  function test_page() {
   try {
    Services.SettingsWindowState.page="Security";wait(300)
    const page=findChild(win.contentItem,"settingsPage-Security")
    verify(page && page.visible);compare(page.productionEnabled,true)
    verify(findChild(page,"fingerprintEnroll")!==null)
    tryCompare(page,"available",true)
    compare(page.fingers.length,1)
    const enroll=findChild(page,"fingerprintEnroll"),remove=findChild(page,"fingerprintRemove"),test=findChild(page,"fingerprintTest")
    verify(enroll.enabled);enroll.clicked();tryCompare(page,"fingers",["right-index-finger","left-index-finger"])
    tryVerify(()=>remove.enabled);remove.clicked();compare(page.confirmRemove,true);compare(page.fingers.length,2)
    remove.clicked();tryCompare(page,"fingers",["right-index-finger"])
    tryVerify(()=>test.enabled);test.clicked();tryCompare(page,"hostMessage","Fingerprint matched")
    capture("host-unknown")
    page.selectFixture(1);compare(page.fingers.length,1);capture("existing-enrollment")
    page.selectFixture(2);compare(page.fingers.length,0);capture("no-enrollment")
    page.beginEnrollment();page.stage();compare(page.stages,1);capture("enrollment")
    page.complete();compare(page.fingers.length,1);page.beginEnrollment();page.complete();compare(page.enrollmentState,"duplicate");compare(page.fingers.length,1)
    page.beginEnrollment();page.enrollmentState="cancelled";page.complete();compare(page.fingers.length,1)
    page.selectFixture(3);verify(!findChild(page,"fingerprintAdd").enabled);capture("unavailable")
    page.beginEnrollment();compare(page.enrollmentState,"idle");compare(page.productionEnabled,true)
    console.log("Fingerprint Settings PASS")
   } catch(e) {console.error("FAIL",e,e.stack)}
   finish.start()
  }
 }
}
