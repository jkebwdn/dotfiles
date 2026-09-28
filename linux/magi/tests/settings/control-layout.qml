import QtQuick
import Quickshell
import "../../.config/quickshell/magi/modules" as Modules
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property var original: null
    property real profileBaseline: 0
    property real mediaBaseline: 0
    function check(ok,label) { if (!ok) { failures++; console.error("FAIL: " + label) } }
    Modules.ModuleRegistry { id: registry; barWindow: null; sharedSurface: surface }
    Bar.SharedStatusSurface {
        id: surface
        combined: true
        modules: Object.values(registry.modules)
        requestedModule: registry.modules[Services.MenuController.activeMenu] || null
        statusContent: Component { Item { implicitWidth: 120; implicitHeight: 28 } }
    }
    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: {
            if (!Services.Settings.ready) return
            const cc = registry.modules.controlcentre
            switch (test.step++) {
            case 0:
                test.original = registry.modules.bluetooth
                Services.MenuController.open("controlcentre")
                break
            case 1:
                test.check(surface.phase === 3, "open CC")
                for (const id of ["settings","volume-down","volume-up","brightness-up"]) Services.Settings.addControl(id)
                Services.Settings.setValue("controlCentre","columns",8)
                break
            case 2:
                test.check(cc.controls.length === 8 && cc.columns === 8 && surface.phase === 3, "8 live controls/columns")
                test.check(surface.animatedWidth === cc.expandedWidth, "open geometry settles")
                Services.Settings.setValue("controlCentre","columns",5)
                break
            case 3:
                test.check(cc.rows === 2 && cc.columns === 5 && surface.phase === 3, "five columns wrap while open")
                Services.Settings.editControl(Services.Settings.data.controlCentre.controls[0].key,"enabled",false)
                break
            case 4:
                test.check(cc.controls.length === 7 && surface.phase === 3, "disable while open")
                const key = Services.Settings.data.controlCentre.controls[1].key
                Services.Settings.moveControl(key,1)
                break
            case 5:
                test.check(cc.controls[0].module === "volume" && surface.phase === 3, "reorder while open")
                Services.Settings.placeBar("bluetooth","hidden")
                Modules.ControlCatalog.secondary("bluetooth")
                break
            case 6:
                test.check(surface.displayedModule === test.original && surface.phase === 3 && test.original.pill === null, "detail survives hidden originating pill")
                Services.MenuController.back()
                Services.Settings.setValue("controlCentre","columns",6)
                break
            case 7:
                test.check(cc.columns === 6 && surface.phase === 3, "six columns")
                Services.Settings.setValue("controlCentre","columns",7)
                break
            case 8:
                test.check(cc.columns === 7 && surface.phase === 3, "seven columns")
                Services.Settings.setValue("controlCentre","columns",4)
                break
            case 9:
                test.check(cc.columns === 4 && surface.phase === 3 && surface.contentOpacity === 1, "four columns without collapse")
                test.profileBaseline = cc.menuHeight
                Services.Settings.setValue("profile", "displayName", "Ada")
                break
            case 10:
                test.check(surface.phase === 3 && cc.showProfile && cc.menuHeight > test.profileBaseline
                    && surface.revealedHeight === cc.menuHeight, "profile update retargets open surface")
                test.mediaBaseline = cc.menuHeight
                Services.Media.available = true
                Services.Media.title = "A real track"
                Services.Media.artist = "An artist"
                break
            case 11:
                test.check(surface.phase === 3 && cc.menuHeight > test.mediaBaseline
                    && surface.revealedHeight === cc.menuHeight, "media appearance retargets open surface")
                Services.Media.available = false
                break
            case 12:
                test.check(surface.phase === 3 && cc.menuHeight === test.mediaBaseline
                    && surface.revealedHeight === cc.menuHeight, "media disappearance retargets open surface")
                Services.Settings.resetSection("profile")
                break
            case 13:
                test.check(surface.phase === 3 && !cc.showProfile && cc.menuHeight === test.profileBaseline
                    && surface.revealedHeight === cc.menuHeight, "profile reset retargets open surface")
                Services.MenuController.close()
                break
            case 14:
                test.check(surface.phase === 0, "clean close")
                console.log("RESULT: " + test.failures + " failures; dynamic Control Centre layout")
                Qt.quit()
            }
        }
    }
}
