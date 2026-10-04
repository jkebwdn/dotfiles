import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/services/CalendarMath.js" as Dates
ShellRoot {
    id: test
    property int step: 0
    property real clockWidth: 0
    property real dateWidth: 0
    property var surface: null
    BarUI.Bar { id: bar; expandableHostMode: "combined" }
    function check(ok,label) { if(!ok) throw new Error("Calendar bar step " + step + ": " + label) }
    function find(item) {
        if (item.objectName === "calendarSurface") return item
        for (const child of item.children || []) { const value = find(child); if(value) return value }
        return null
    }
    function openCheck() {
        check(surface.phase===3 && surface.absorbed && surface.visible,"shared lifecycle open")
        check(bar.clockAnchor.opacity===0 && bar.dateAnchor.opacity===0,"both originals suppressed")
        check(bar.clockAnchor.width===clockWidth && bar.dateAnchor.width===dateWidth,"slots unchanged")
        check(bar.exclusiveZone===48 && bar.catcherEnabled && bar.combinedKeyboardEnabled,"reservation/input")
        check(surface.x>=0 && surface.x+surface.width<=bar.width,"horizontal bounds")
        check(surface.y===10,"bar origin")
    }
    Timer {
        interval: 550; running: true; repeat: true
        onTriggered: {
            if(!Services.Settings.ready) return
            switch(step++) {
            case 0:
                surface=find(bar.contentItem);check(!!surface,"surface exists")
                clockWidth=bar.clockAnchor.width;dateWidth=bar.dateAnchor.width
                bar.clockAnchor.triggered();break
            case 1:
                openCheck();check(surface.x===14,"left group origin")
                Services.Calendar.model.moveMonths(1)
                bar.dateAnchor.triggered();break
            case 2:
                check(surface.phase===0 && bar.clockAnchor.opacity===1 && bar.dateAnchor.opacity===1,"toggle restores originals")
                check(!bar.catcherEnabled && !bar.combinedKeyboardEnabled,"input released")
                Services.Settings.setValue("bar","left",[])
                Services.Settings.setValue("bar","center",["clock","date"])
                break
            case 3: bar.dateAnchor.triggered();break
            case 4:
                openCheck();check(surface.x>bar.width/4,"center anchoring")
                check(Dates.same(Services.Calendar.model.selected,Services.ClockState.today),"reopen resets today")
                bar.closeActiveCombinedMenu();break
            case 5:
                check(surface.phase===0,"outside catcher closes")
                Services.Settings.setValue("bar","center",[])
                Services.Settings.setValue("bar","right",["clock","date","controlcentre"])
                break
            case 6: bar.clockAnchor.triggered();break
            case 7:
                openCheck();check(surface.x>bar.width/2,"right anchoring")
                Services.MenuController.open("controlcentre");break
            case 8:
                check(surface.phase===0 && bar.clockAnchor.opacity===1,"CC switches Calendar off")
                check(bar.activeExpandablePill && bar.activeExpandablePill.phase===3,"CC lifecycle intact")
                bar.clockAnchor.triggered();break
            case 9:
                openCheck();Services.Calendar.suppressed=true;break
            case 10:
                check(surface.phase===0 && !Services.Calendar.opened,"fullscreen closes")
                Services.Calendar.open();check(!Services.Calendar.opened,"fullscreen rejects open")
                Services.Calendar.suppressed=false
                check(!Services.Calendar.opened,"fullscreen exit does not reopen")
                bar.clockAnchor.triggered();bar.clockAnchor.triggered();bar.clockAnchor.triggered();break
            case 11:
                openCheck();Services.MenuController.close();break
            case 12:
                check(surface.phase===0 && bar.settingsReady,"rapid toggle clean close")
                bar.expandableHostMode="anchored"
                bar.clockAnchor.triggered();break
            case 13:
                openCheck();check(bar.fullSurface,"legacy host temporary full-height")
                Services.MenuController.close();break
            case 14:
                check(!bar.fullSurface && surface.phase===0,"legacy bar compact restored")
                console.log("Calendar real Bar clicks, suppression, slots, left/center/right, CC handoff, fullscreen, rapid toggle and fallback PASS")
                Qt.quit()
            }
        }
    }
}
