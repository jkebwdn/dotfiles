pragma Singleton
import QtQuick
import Quickshell
import "CalendarMath.js" as Dates
Scope {
    id: root
    property var locale: Qt.locale()
    readonly property var preferences: Settings.data.calendar
    readonly property date now: clock.date
    readonly property date today: Dates.day(now)
    readonly property string timeText: preferences.timeFormat === "locale"
        ? now.toLocaleTimeString(locale, Locale.ShortFormat)
        : now.toLocaleTimeString(locale, preferences.timeFormat === "12h" ? "h:mm AP" : "HH:mm")
    readonly property string dateText: preferences.dateFormat === "locale"
        ? now.toLocaleDateString(locale, Locale.ShortFormat)
        : now.toLocaleDateString(locale, preferences.dateFormat === "iso" ? "yyyy-MM-dd" : "dd/MM/yy")
    SystemClock { id: clock; precision: SystemClock.Minutes }
}
