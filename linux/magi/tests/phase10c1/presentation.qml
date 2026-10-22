import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    FloatingWindow { id: window; visible:true; implicitWidth:940; implicitHeight:620
        color: "#1e1e2e"
        UI.SettingsContent { anchors.fill:parent }
    }
    Timer { id: finish; interval:100; onTriggered:Qt.quit() }
    TestCase {
        name:"PowerIdle"
        when: Services.Settings.ready
        function test_page() {
            try {
                Services.SettingsWindowState.page="Power & Idle";wait(200)
                const page=findChild(window.contentItem,"settingsPage-Power & Idle")
                verify(page && page.visible)
                const lock=findChild(page,"powerIdle-lockAfter"), display=findChild(page,"powerIdle-displayOffAfter"), suspend=findChild(page,"powerIdle-suspendAfter")
                compare(lock.currentText,"5 minutes");compare(display.currentText,"10 minutes");compare(suspend.currentText,"Never")
                for(const selector of [lock,display,suspend]) {
                    verify(selector.model.includes("Never"))
                    const point=selector.mapToItem(page,0,0)
                    verify(point.x>=0 && point.x+selector.width<=page.width)
                }
                const capture=grabImage(window.contentItem)
                compare(capture.width,940)
                capture.save(Quickshell.env("MAGI_POWER_PREVIEW"))
                lock.currentIndex=lock.choices.indexOf(1800);lock.activated(lock.currentIndex);wait(30)
                verify(!page.validOrder);verify(!findChild(page,"powerIdle-apply").enabled)
                page.draft={lockAfter:60,displayOffAfter:300,suspendAfter:900};wait(30)
                verify(page.validOrder);verify(findChild(page,"powerIdle-apply").enabled)
                mouseClick(findChild(page,"powerIdle-apply"));tryCompare(Services.Settings,"saveState","error",5000)
                verify(Services.Settings.error.includes("setup is not active"))
                Services.Settings.discardAndReload();tryCompare(Services.Settings,"saveState","saved",3000)
                compare(Services.Settings.data.powerIdle.lockAfter,300)
                console.log("Power & Idle UI, ordering, unenrolled failure and persistence PASS")
            } catch(e) {console.error("FAIL:",e,e.stack)}
            finish.start()
        }
    }
}
