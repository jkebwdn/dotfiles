import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/calendar" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/services/CalendarMath.js" as Dates
import "../../.config/quickshell/magi/settings/SettingsSchema.js" as Schema
ShellRoot {
    id: test
    Services.CalendarModel {
        id: model
        preferences: Schema.defaults().calendar
        today: Dates.civil(2024,1,29)
        locale: Qt.locale("en_GB")
    }
    QtObject {
        id: service
        property var model: model
        property var preferences: model.preferences
        property bool opened: true
        function close() { opened = false }
    }
    FloatingWindow {
        visible: true; implicitWidth: 344; implicitHeight: 420
        UI.CalendarContent { id: content; anchors.fill: parent; anchors.margins: 12; service: service }
    }
    Timer {
        interval: 350; running: true
        onTriggered: {
            function check(ok,label) { if(!ok) throw new Error(label) }
            check(model.firstDay===1 && model.weekdayNames[0]==="Mon","British locale")
            check(model.monthLabel==="February 2024","month label")
            model.locale=Qt.locale("en_US");check(model.firstDay===0 && model.weekdayNames[0]==="Sun","US locale")
            model.locale=Qt.locale("de_DE");check(model.monthLabel==="Februar 2024","German month")
            model.preferences=Object.assign({},model.preferences,{firstDay:"sunday",showAdjacentDays:false,showWeekNumbers:true,density:"compact"})
            check(model.firstDay===0 && model.cells.filter(c=>c.shown).length===29,"adjacency")
            check(content.cellHeight===32 && content.weekWidth===28,"settings geometry")
            content.requestInitialFocus();check(content.activeFocus,"focus")
            content.navigate(Qt.Key_Right);check(model.selected.getMonth()===2 && model.selected.getDate()===1,"next day")
            content.navigate(Qt.Key_Up);check(model.selected.getDate()===23 && model.month===1,"week back")
            content.navigate(Qt.Key_PageUp);check(model.month===0,"previous month")
            content.navigate(Qt.Key_Home);check(Dates.same(model.selected,model.today),"today")
            model.today=Dates.civil(2024,2,1)
            check(model.cells.some(c=>c.today && c.day===1),"today rollover highlight")
            model.resetToday();check(model.month===2,"today rollover selection")
            model.select(Dates.civil(2026,11,31));content.navigate(Qt.Key_PageDown);check(model.year===2027 && model.month===0,"year rollover")
            content.navigate(Qt.Key_Escape);check(!service.opened,"Escape")
            console.log("Calendar production content locale, selection, keyboard, settings and today rollover PASS")
            Qt.quit()
        }
    }
}
