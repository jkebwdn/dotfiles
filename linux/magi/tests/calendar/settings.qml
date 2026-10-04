import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    UI.SettingsWindow { id: window }
    property int step: 0
        Timer {
        interval: 500; repeat: true; running: true
        onTriggered: {
            if (!Services.Settings.ready || Services.Settings.saveState === "pending") return
            function check(ok,label) { if (!ok) throw new Error("Calendar settings: " + label) }
            switch(step++) {
            case 0:
                Services.SettingsWindowState.page = "Date & time"
                Services.SettingsWindowState.shown = true
                check(Services.Settings.setValue("calendar","firstDay","sunday"),"weekday")
                check(Services.Settings.setValue("calendar","density","compact"),"density")
                check(Services.Settings.setValue("calendar","showAdjacentDays",false),"adjacent")
                check(Services.Settings.setValue("calendar","showWeekNumbers",true),"weeks")
                check(Services.Settings.setValue("calendar","timeFormat","12h"),"time")
                check(Services.Settings.setValue("calendar","dateFormat","iso"),"date")
                check(!Services.Settings.setValue("calendar","firstDay","invalid"),"invalid enum")
                check(!Services.Settings.setValue("calendar","showWeekNumbers","yes"),"invalid boolean")
                Services.Settings.setValue("launcher","hiddenIds",["preserved.desktop"])
                break
            case 1:
                check(Services.Settings.saveState === "saved","save")
                check(Services.Calendar.model.firstDay===0,"model setting")
                check(Services.ClockState.dateText===Services.ClockState.now.toLocaleDateString(Services.ClockState.locale,"yyyy-MM-dd"),"shared date format")
                check(Services.ClockState.timeText===Services.ClockState.now.toLocaleTimeString(Services.ClockState.locale,"h:mm AP"),"shared time format")
                Services.Settings.discardAndReload();break
            case 2:
                var p=Services.Settings.data.calendar
                check(p.firstDay==="sunday" && p.density==="compact" && p.showWeekNumbers && !p.showAdjacentDays && p.timeFormat==="12h" && p.dateFormat==="iso","reload all fields")
                check(Services.Settings.resetSection("calendar"),"reset")
                break
            case 3:
                var p=Services.Settings.data.calendar
                check(p.firstDay==="locale" && p.density==="comfortable" && !p.showWeekNumbers && p.showAdjacentDays && p.timeFormat==="24h" && p.dateFormat==="numeric","defaults restored")
                check(Services.Settings.data.launcher.hiddenIds[0]==="preserved.desktop","reset isolation")
                console.log("Calendar Settings page, shared clock formats, validation, persistence, reload and reset PASS")
                Qt.quit()
            }
        }
    }
}
