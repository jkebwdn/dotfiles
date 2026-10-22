import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    QtObject { id: internal; property string name:"eDP-1";property int width:1920;property int height:1080;property var monitor:({activeWorkspace:{id:1}}) }
    QtObject { id: external; property string name:"HDMI-A-1";property int width:2560;property int height:1440;property var monitor:({activeWorkspace:{id:2}}) }
    BarUI.BarFleet { id:fleet; screens:[internal,external] }
    Timer { id:finish;interval:100;onTriggered:Qt.quit() }
    TestCase {
        name:"Caffeine"
        when:Services.Settings.ready && !!fleet.mainBar
        function test_state() {
            try {
                verify(Services.Caffeine.bound);verify(!Services.Caffeine.active)
                Services.Caffeine.setRequested(true);verify(Services.Caffeine.active)
                Services.Settings.setValue("bar","externalDisplays",true);wait(400)
                compare(fleet.presentations.length,2);verify(Services.Caffeine.active)
                // Policy-only draft/save failure must not reset Caffeine or its one fleet binding.
                Services.Settings.setPowerIdle({lockAfter:60,displayOffAfter:300,suspendAfter:0})
                tryCompare(Services.Settings,"saveState","error",5000);verify(Services.Caffeine.active)
                verify(Services.Settings.error.includes("idle inhibition is active"))
                compare(Services.Settings.data.powerIdle.lockAfter,300)
                Services.Settings.discardAndReload();wait(300);verify(Services.Caffeine.active)
                Services.Caffeine.setRequested(false);verify(!Services.Caffeine.active)
                Services.Caffeine.setRequested(true);fleet.screens=[];wait(300)
                verify(Services.Caffeine.requested);verify(!Services.Caffeine.bound);verify(!Services.Caffeine.active)
                fleet.screens=[internal];wait(400);verify(Services.Caffeine.active)
                Services.Caffeine.setRequested(false);verify(!Services.Caffeine.active)
                console.log("Phase 10C.1 Caffeine lifecycle PASS")
            } catch(e) {console.error("FAIL:",e,e.stack)}
            finish.start()
        }
    }
}
