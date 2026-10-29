import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    BarUI.Bar { id: bar; visible: true; expandableHostMode: "combined" }
    Timer { id: finish; interval: 50; onTriggered: Qt.quit() }
    TestCase {
        name: "DailyPolishRuntime"; when: Services.Settings.ready
        function test_runtime() {
            try {
                Services.Bluetooth.connectedCount=1
                wait(300)
                for(const id of ["wifi","bluetooth","volume","controlcentre"]) {
                    const module=bar.expandablePillRegistry[id]
                    verify(module.pill !== null,id)
                    const modules=JSON.parse(JSON.stringify(Services.Settings.data.bar.modules)); modules[id]=Object.assign({},modules[id],{backgroundRole:"accent"}); Services.Settings.setValue("bar","modules",modules)
                    compare(module.pill.color,Theme.Theme.barItemBackground(id))
                    module.pill.forceActiveFocus(); wait(30)
                    verify(module.pill.activeFocus)
                    keyClick(Qt.Key_Return);wait(400);compare(Services.MenuController.activeMenu,id)
                    Services.MenuController.close();wait(500)
                    compare(module.pill.color,Theme.Theme.barItemBackground(id))
                }
                console.log("Daily polish runtime PASS")
            } catch(error) { console.error("Daily polish runtime FAIL: "+error+" at "+error.stack); throw error } finally { finish.start() }
        }
    }
}
