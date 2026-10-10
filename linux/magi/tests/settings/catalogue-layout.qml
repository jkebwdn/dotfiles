import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property string expected: ""
    function check(ok, label) { if (!ok) { failures++; console.error("FAIL: " + label) } }
    Timer {
        interval: 300; running: true; repeat: true
        onTriggered: {
            if (!Services.Settings.ready || Services.Settings.saveState === "pending") return
            const store = Services.Settings
            switch (test.step++) {
            case 0:
                store.resetSection("controlCentre")
                for (const id of ["apps", "notifications", "emoji", "clipboard", "reboot", "settings"])
                    test.check(store.addEntry("actions", id), "add " + id)
                test.check(!store.addEntry("actions", "notifications"), "duplicate not added")
                store.setValue("controlCentre", "columns", 7)
                store.setValue("controlCentre", "actionColumns", 2)
                store.moveControl(store.data.controlCentre.controls[0].key, 1)
                store.moveEntry("actions", store.data.controlCentre.actions[11].key, -1)
                store.editEntry("actions", store.data.controlCentre.actions[7].key, "enabled", false)
                test.expected = JSON.stringify(store.data.controlCentre)
                break
            case 1: store.discardAndReload(); break
            case 2:
                test.check(JSON.stringify(store.data.controlCentre) === test.expected, "new options, order, enable state and independent columns survive disk reload")
                store.removeEntry("actions", store.data.controlCentre.actions.find(e => e.module === "clipboard").key)
                break
            case 3: store.discardAndReload(); break
            case 4:
                test.check(!store.data.controlCentre.actions.some(e => e.module === "clipboard"), "remove survives reload")
                store.resetSection("controlCentre")
                break
            case 5: store.discardAndReload(); break
            case 6:
                test.check(store.data.controlCentre.actions.map(e => e.module).join(",") === "vpn,dnd,caffeine,lock,hibernate,shutdown", "reset leaves new actions unselected")
                test.check(store.data.controlCentre.columns === 4 && store.data.controlCentre.actionColumns === 6, "independent reset defaults")
                console.log("RESULT: " + test.failures + " failures; catalogue Settings persistence and reset")
                Qt.quit()
            }
        }
    }
}
