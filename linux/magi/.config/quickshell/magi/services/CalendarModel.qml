import QtQuick
import "CalendarMath.js" as Dates
QtObject {
    id: root
    required property var preferences
    required property date today
    property var locale: Qt.locale()
    property date selected: Dates.day(today)
    readonly property int year: selected.getFullYear()
    readonly property int month: selected.getMonth()
    readonly property int firstDay: preferences.firstDay === "monday" ? 1
        : preferences.firstDay === "sunday" ? 0 : locale.firstDayOfWeek
    readonly property var cells: Dates.grid(year, month, firstDay, preferences.showAdjacentDays, today, selected)
    readonly property var weekNumbers: Dates.weeks(cells)
    readonly property var weekdayNames: Array.from({length:7}, (_, i) => locale.standaloneDayName((firstDay + i) % 7, Locale.ShortFormat))
    readonly property string monthLabel: locale.standaloneMonthName(month, Locale.LongFormat) + " " + year
    readonly property string selectedWeekday: selected.toLocaleDateString(locale, "dddd")
    readonly property string selectedLabel: selected.toLocaleDateString(locale, "d MMMM yyyy")
    function select(date) {
        if (isNaN(date.getTime()) || date.getFullYear() < 1 || date.getFullYear() > 9999) return
        selected = Dates.day(date)
    }
    function resetToday() { select(today) }
    function moveDays(amount) { select(Dates.addDays(selected, amount)) }
    function moveMonths(amount) { select(Dates.addMonths(selected, amount)) }
}
