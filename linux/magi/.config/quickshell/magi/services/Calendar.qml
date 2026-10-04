pragma Singleton
import QtQuick
import Quickshell
Scope {
    id: root
    property bool suppressed: false
    readonly property bool opened: MenuController.activeMenu === "calendar"
    readonly property var preferences: Settings.data.calendar
    readonly property CalendarModel model: CalendarModel {
        preferences: root.preferences
        today: ClockState.today
        locale: ClockState.locale
    }
    function open() {
        if (suppressed) return
        model.resetToday()
        MenuController.open("calendar")
    }
    function close() { if (opened) MenuController.close() }
    function toggle() { if (opened) close(); else open() }
    onSuppressedChanged: { if (suppressed) close() }
    onOpenedChanged: {
        if (opened) {
            if (suppressed) close()
            else model.resetToday()
        }
    }
}
