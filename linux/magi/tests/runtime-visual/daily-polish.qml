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
        function content(item) {
            if (item.iconColor !== undefined && item.moduleId !== undefined) return item
            for (const child of item.children || []) { const found=content(child); if(found) return found }
            return null
        }
        function ink(actual, expected) { for(const channel of ["r","g","b","a"]) verify(Math.abs(actual[channel]-expected[channel])<=1/255) }
        function test_runtime() {
            try {
                Services.Bluetooth.connectedCount=1
                wait(300)
                for(const id of ["wifi","bluetooth","volume","controlcentre"]) {
                    const module=bar.expandablePillRegistry[id]
                    verify(module.pill !== null,id)
                    const modules=JSON.parse(JSON.stringify(Services.Settings.data.bar.modules)); modules[id]=Object.assign({},modules[id],{backgroundRole:"accent",foregroundShade:.4,foregroundOffShade:-.4}); Services.Settings.setValue("bar","modules",modules)
                    compare(module.pill.color,Theme.Theme.barItemBackground(id))
                    const label=content(module.pill); verify(label!==null)
                    if(id === "wifi") {
                        ink(label.iconColor,Theme.Theme.shadeAccent(Theme.Theme.muted,-.4))
                        Services.Network.connected=true
                        ink(label.iconColor,Theme.Theme.barAccent("wifi"))
                        Services.Network.connected=false
                    } else if(id === "bluetooth") {
                        ink(label.iconColor,Theme.Theme.shadeAccent(Theme.Theme.muted,-.4))
                        Services.Bluetooth.enabled=true
                        ink(label.iconColor,Theme.Theme.shadeAccent(Theme.Theme.text,-.4))
                        Services.Bluetooth.primaryDevice={name:"Fixture",batteryAvailable:false}
                        ink(label.iconColor,Theme.Theme.barAccent("bluetooth"))
                        Services.Bluetooth.primaryDevice=null
                    } else if(id === "volume") {
                        Services.Audio.muted=true
                        ink(label.iconColor,Theme.Theme.shadeAccent(Theme.Theme.warning,-.4))
                        Services.Audio.available=true;Services.Audio.muted=false
                        ink(label.iconColor,Theme.Theme.shadeAccent(Theme.Theme.text,.4))
                    }
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
