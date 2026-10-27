import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/components/audio" as AudioUI
import "../../.config/quickshell/magi/components/calendar" as CalendarUI
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/notifications" as Notices
import "../../.config/quickshell/magi/components/hub" as HubUI
ShellRoot {
    BarUI.Bar { id: bar; expandableHostMode: "combined" }
    HubUI.HubWindow { id: hub; readyToOpen: bar.settingsReady; previewSurface: bar.activeCombinedRegion }
    Services.AudioModel {
        id: audio
        sink: ({id:1, name:"speakers", description:"Built-in Speakers", ready:true, properties:{"media.class":"Audio/Sink"}, audio:{volume:.65,muted:false}})
        sourceNodes: [sink]
    }
    QtObject {
        id:record
        property var notification:null
        property int notificationId:1
        property bool hovered:false
        property bool dismissed:false
        property bool read:false
        property double updatedAt:Date.now()
        property var data:({id:1,appName:"MAGI",summary:"Palette preview",body:"Readable notification",actions:[],urgency:1})
    }
    FloatingWindow {
        id: win
        visible: true; implicitWidth: 1280; implicitHeight: 1000; color: Theme.Theme.background
        Row {
            x:24; y:16; spacing:18
            Repeater { model:["clock","workspaces","wifi","bluetooth","volume","tray","battery"]
                UI.BarModulePreview { required property string modelData; moduleId:modelData; width:100; height:40 }
            }
        }
        UI.ThemeGallery { id: gallery; x:24; y:80; width:1220; height:160 }
        UI.ControlCentrePreview { id: cc; x:24; y:260; width:440; height:700 }
        AudioUI.AudioSurface { x:500; y:270; width:340; height:250; audioService:audio }
        CalendarUI.CalendarContent { x:900; y:270; width:350; service:Services.Calendar }
        UI.LockStylePreview { x:500; y:580; width:340; height:120; kind:"credential"; choice:"dots"; palette:Theme.Theme.roles }
        Notices.NotificationCard { id:notice; x:500; y:800; width:720; record:record; service:({invoke:function(){},dismiss:function(){}}) }
        Text { x:500; y:740; text:"Authentication preview · no credentials"; color:Theme.Theme.text }
    }
    Timer { id:finish; interval:100; onTriggered:Qt.quit() }
    TestCase {
        name:"PaletteExpansion"
        when:Services.Settings.ready
        function test_palettes() { try {
            const original=Services.Settings.data.appearance.theme
            compare(Theme.ThemeRegistry.themes.length,26)
            for (const theme of Theme.ThemeRegistry.themes.slice(18)) {
                Services.Settings.setTheme(theme.id)
                tryCompare(Theme.Theme,"effectiveTheme",theme.id)
                compare(Theme.Theme.definition.dark,theme.dark)
                compare(Theme.Theme.roles.text,theme.roles.text)
                compare(findChild(notice,"notificationTitle").color,theme.roles.text)
                compare(gallery.currentIndex,Theme.ThemeRegistry.ids.indexOf(theme.id))
                verify(gallery.itemAt(gallery.currentIndex).selected)
                for (const mode of Services.Hub.modes) {
                    Services.Hub.open(mode);tryCompare(hub,"visible",true)
                    verify(hub.content.currentContent.visible)
                }
                Services.Hub.close();tryCompare(hub,"visible",false)
                for (const surface of ["controlcentre","wifi","bluetooth","audio"]) {
                    console.log("Preview surface",theme.id,surface)
                    Services.MenuController.open(surface==="audio"?"volume":surface,bar.outputScreen)
                    tryCompare(bar.expandablePillRegistry[surface==="audio"?"volume":surface],"phase",3)
                    Services.MenuController.close()
                    tryCompare(bar.expandablePillRegistry[surface==="audio"?"volume":surface],"phase",0)
                }
                const opacity=Services.Settings.data.applicationAppearance
                Services.Settings.setValue("applicationAppearance","managed",true)
                Services.Settings.setValue("applicationAppearance","backgroundOpacity",.75)
                compare(Theme.Theme.surfaceBackground(Theme.Theme.surface).a,.75)
                compare(Theme.Theme.text.a,1)
                Services.Settings.setValue("applicationAppearance","managed",opacity.managed)
                Services.Settings.setValue("applicationAppearance","backgroundOpacity",opacity.backgroundOpacity)
                const capture=Quickshell.env("MAGI_PALETTE_PREVIEWS")
                if(capture) { waitForRendering(win.contentItem);grabImage(win.contentItem).save(capture+"/"+theme.id+".png") }
            }
            Services.Settings.setTheme(original)
            tryCompare(Theme.Theme,"effectiveTheme",original)
            compare(Services.QuickActions.executed.length,0)
            console.log("Palette expansion preview PASS")
        } catch(e) { console.error("FAIL:",e,e.stack) } finish.start() }
    }
}
