import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/hub" as HubUI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    BarUI.Bar { id: bar; expandableHostMode: "combined" }
    HubUI.HubWindow { id: hub; readyToOpen: bar.settingsReady; previewSurface: bar.activeCombinedRegion }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "HubProductionPreview"
        when: Services.Settings.ready
        function test_preview() {
            try {
                bar.contentItem.Window.window.width = 1920
                Services.SettingsWindowState.page = "Control Centre"
                Services.SettingsWindowState.open(); tryCompare(hub,"visible",true); wait(100)
                const content = hub.content.currentContent
                const cc = bar.expandablePillRegistry.controlcentre
                const preview = findChild(content,"controlCentrePreview")
                verify(preview !== null)
                const anchor = hub.content.selectorPill.mapToItem(hub.contentItem,0,0)
                Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
                verify(hub.visible && bar.previewPinned && !bar.catcherEnabled)
                compare(hub.content.selectorPill.mapToItem(hub.contentItem,0,0),anchor)
                verify(hub.content.x + hub.content.width <= hub.previewOrigin.x - 16)
                compare(hub.mask.item,hub.content.surface)
                compare(hub.mask.regions[0].item,hub.content.selectorPill)
                verify(hub.content.x+hub.content.width < hub.previewOrigin.x)
                for (const page of ["Appearance","Profile","Bar","Date & time","Notifications","Clipboard","Launcher","Emoji","Wallpaper","Hub","Control Centre"]) {
                    const sub = ({})[page]
                    if (sub) { Services.SettingsWindowState.page = "Appearance"; wait(30) }
                    const nav = findChild(content,sub ? "appearanceNav-" + sub : "settingsNav-"+page)
                    nav.forceActiveFocus(); wait(20); mouseClick(nav); wait(50)
                    compare(Services.SettingsWindowState.page,page)
                    verify(hub.visible && bar.previewPinned && cc.phase === 3)
                }
                const before = bar.activeCombinedRegion.height
                Services.Settings.setVisual("primaryContainerSize",96); wait(550)
                verify(bar.activeCombinedRegion.height !== before)
                verify(hub.visible && bar.previewPinned)
                verify(hub.content.x+hub.content.width < hub.previewOrigin.x)
                mouseClick(findChild(content,"settingsCloseControlCentrePreview"))
                verify(hub.visible,"closing preview does not hide Settings during retraction")
                tryCompare(cc,"phase",0); verify(!bar.previewPinned)
                Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
                Services.Hub.close(); tryCompare(cc,"phase",0)
                verify(!hub.visible && !Services.SettingsWindowState.shown && !bar.previewPinned)
                Services.SettingsWindowState.open(); wait(100)
                Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
                Services.Hub.open("apps"); tryCompare(cc,"phase",0)
                verify(hub.visible && !Services.SettingsWindowState.controlCentrePreview)
                Services.SettingsWindowState.open(); wait(100)
                Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
                mouseClick(hub.contentItem,8,80); compare(cc.phase,3)
                verify(hub.visible && bar.previewPinned)
                Services.Hub.close(); tryCompare(cc,"phase",0)
                Services.SettingsWindowState.open(); wait(80)
                Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
                Services.Calendar.open(); tryCompare(hub,"visible",false)
                verify(!Services.SettingsWindowState.controlCentrePreview)
                Services.MenuController.close(); wait(550)
                Services.MenuController.open("controlcentre"); tryCompare(cc,"phase",3)
                verify(bar.catcherEnabled)
                mouseClick(findChild(bar.contentItem,"statusDismissCatcher"),10,400)
                tryCompare(cc,"phase",0)
                compare(bar.exclusiveZone,48)
                console.log("Hub production preview PASS")
            } catch (error) { console.error("FAIL:",error,error.stack) } finally { finish.start() }
        }
    }
}
