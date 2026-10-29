import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as CC
ShellRoot {
    id: root
    property int positionNotifications: 0
    Connections { target: player; function onPositionChanged() { root.positionNotifications++ } }
    QtObject {
        id: player
        property string identity: "Already playing"
        property string dbusName: "fixture"
        property string desktopEntry: "fixture"
        property string trackTitle: "Track one"
        property string trackArtist: "Artist"
        property string trackArtUrl: ""
        property bool isPlaying: true
        property bool positionSupported: true
        property bool lengthSupported: true
        property real position: 25
        property real length: 100
        property bool canControl: true
        property bool canTogglePlaying: true
        property bool canGoPrevious: true
        property bool canGoNext: true
        function togglePlaying() { isPlaying = !isPlaying }
    }
    QtObject {
        id: replacement
        property string identity: "Replacement"
        property string trackTitle: "Track two"
        property string trackArtist: "Artist"
        property string trackArtUrl: ""
        property bool isPlaying: true
        property bool positionSupported: true
        property bool lengthSupported: true
        property real position: 60
        property real length: 120
        property bool canControl: true
        property bool canTogglePlaying: true
        property bool canGoPrevious: false
        property bool canGoNext: false
    }
    Services.MediaController { id: media; players: [player]; cacheArtwork: false }
    FloatingWindow {
        id: win; visible: true; implicitWidth: 820; implicitHeight: 200; color: Theme.Theme.background
        Item { id: parking; focus: true }
        Column {
            anchors.centerIn: parent; spacing: 25
            Row {
                id: strip; spacing: 6
                Repeater { model: ["clock","date","volume","wifi","bluetooth","battery","controlcentre","tray"]; UI.BarModulePreview { required property string modelData; moduleId: modelData } }
            }
            Bar.ExpandablePlugin { id: focusPill; visible: false; styleId: "volume"; title: "Focus sample"; expandsOnClick: false; color: Theme.Theme.barItemBackground("volume") }
            CC.MediaSection { id: section; width: 450; service: media; interactive: false }
        }
    }
    Timer { id: finish; interval: 50; onTriggered: Qt.quit() }
    TestCase {
        name: "DailyPolish"; when: Services.Settings.ready
        function item(name) { const result = findChild(win.contentItem,name); verify(result !== null, name); return result }
        function set(id,key,value) { const modules = JSON.parse(JSON.stringify(Services.Settings.data.bar.modules)); if (!modules[id]) modules[id]={}; modules[id][key]=value; verify(Services.Settings.setValue("bar","modules",modules)) }
        function compareInk(actual, expected) { for (const channel of ["r","g","b","a"]) verify(Math.abs(actual[channel]-expected[channel]) <= 1/255, "rendered shade " + channel) }
        function capture(name) { wait(80); const dir=Quickshell.env("MAGI_DAILY_PREVIEWS"); if(dir) grabImage(win.contentItem).save(dir+"/"+name+".png") }
        function test_all() {
            try {
                Services.Settings.setValue("icons", "pack", "magi-legacy")
                tryCompare(media,"activePlayer",player)
                compare(media.progress,.25)
                verify(item("artworkProgressBorder").visible,"already playing progress immediately visible")
                const beforeOpen=root.positionNotifications
                Services.MenuController.open("controlcentre")
                wait(50)
                verify(root.positionNotifications > beforeOpen, "opening media samples the current position immediately, before the one-second tick")
                player.length=0
                const noDuration=root.positionNotifications
                wait(1050); compare(root.positionNotifications,noDuration, "no timer without a valid duration")
                player.length=100
                wait(50); verify(root.positionNotifications > noDuration, "late duration starts progress without pause/resume")
                Services.MenuController.close()
                const hidden=root.positionNotifications
                wait(1050); compare(root.positionNotifications,hidden,"no hidden progress timer")
                player.positionSupported=false; player.lengthSupported=false
                compare(media.progress,-1)
                player.positionSupported=true; player.lengthSupported=true
                compare(media.progress,.25)
                player.isPlaying=false; compare(media.progress,.25)
                Services.MenuController.open("controlcentre")
                const pausedNotifications=root.positionNotifications
                wait(1100); compare(media.progress,.25); compare(root.positionNotifications,pausedNotifications)
                player.isPlaying=true; wait(50); verify(root.positionNotifications > pausedNotifications)
                Services.MenuController.close()
                player.position=26; compare(media.progress,.26)
                player.position=75; compare(media.progress,.75)
                player.trackTitle="New track"; player.position=0; player.length=200; compare(media.progress,0)
                player.position=20; compare(media.progress,.1)
                player.length=0; compare(media.progress,-1)
                player.length=200; compare(media.progress,.1)
                media.players=[replacement]; tryCompare(media,"activePlayer",replacement); compare(media.progress,.5)
                media.players=[]; tryCompare(media,"available",false); compare(media.progress,-1)
                media.players=[player]; tryCompare(media,"activePlayer",player)
                const wifi=item("barPreview-wifi").presenter, battery=item("barPreview-battery").presenter
                compare(wifi.color,Theme.Theme.statusPillBackground)
                const left=item("batteryIconRegion"), right=item("batteryPercentageRegion")
                compare(left.color,right.color); compare(right.width,battery.width); compare(left.width,battery.iconRegionWidth)
                capture("default")
                set("wifi","backgroundRole","green"); set("bluetooth","backgroundRole","blue"); set("volume","backgroundRole","yellow")
                compare(wifi.color,Theme.Theme.barItemBackground("wifi")); compare(Theme.Theme.barAccent("wifi"),Theme.Theme.accent)
                set("wifi","accentRole","red"); compare(wifi.color,Theme.Theme.barItemBackground("wifi")); compare(Theme.Theme.barAccent("wifi"),Theme.Theme.roles.red)
                focusPill.visible=true
                parking.forceActiveFocus(); wait(50); waitForRendering(focusPill)
                const unfocused=grabImage(win.contentItem)
                focusPill.forceActiveFocus(); wait(50); waitForRendering(focusPill)
                verify(!grabImage(win.contentItem).equals(unfocused), "focus outline remains visible on custom background")
                focusPill.visible=false
                set("wifi","accentRole","background"); set("bluetooth","accentRole","background"); set("volume","foregroundRole","background")
                capture("status-backgrounds")
                set("battery","backgroundRole","blue"); set("battery","percentageBackgroundRole","green")
                verify(left.color !== right.color); compare(left.topRightRadius,battery.radius); compare(right.topLeftRadius,battery.radius)
                compare(left.topLeftRadius,battery.radius); compare(right.topRightRadius,battery.radius)
                set("battery","foregroundRole","background"); set("battery","percentageForegroundRole","background")
                compare(item("batteryStatusIcon").color,Theme.Theme.background); compare(item("batteryPercentageText").color,Theme.Theme.background)
                battery.border.width=2; battery.border.color=Theme.Theme.text
                compare(item("batteryOuterBorder").border.width,2); compare(item("batteryOuterBorder").radius,battery.radius)
                compare(left.border.width,0); compare(right.border.width,0)
                battery.border.width=0
                capture("battery-split")
                const icon=item("batteryStatusIcon"), normalRole=icon.role
                compare(icon.x + icon.width / 2, left.width / 2, "icon centered within split region")
                battery.charging=true; verify(icon.role !== normalRole); battery.charging=false
                battery.percentage=3; verify(icon.role !== normalRole); battery.percentage=72
                const percentageText=item("batteryPercentageText")
                for (const percentage of [3, 72, 100]) {
                    battery.percentage=percentage
                    compare(percentageText.x + percentageText.width / 2, (battery.iconRegionWidth + battery.width) / 2, "percentage centered for " + percentage)
                    verify(Math.abs(percentageText.y + percentageText.height / 2 - battery.height / 2) <= .5, "percentage vertically centered within pixel alignment")
                }
                battery.percentage=72
                const wide=battery.width
                set("battery","showPercentage",false); verify(!right.visible); verify(!item("batteryPercentageText").visible); verify(battery.width<wide); compare(left.topRightRadius,battery.radius)
                compare(icon.x + icon.width / 2, battery.width / 2, "icon centered when percentage hidden")
                capture("battery-hidden-percentage")
                set("battery","showPercentage",true)
                battery.hovered=true; verify(left.color !== Theme.Theme.barItemBackground("battery")); battery.hovered=false
                for(const theme of ["catppuccin-mocha","everforest-dark-hard","kanagawa-wave","one-light","gruvbox-light"]) { Services.Settings.setTheme(theme); capture(theme); verify(left.color!==right.color); compare(wifi.color,Theme.Theme.barItemBackground("wifi")) }
                for(const theme of ["catppuccin-mocha","everforest-dark-hard","kanagawa-wave","one-light","gruvbox-light"]) {
                    Services.Settings.setTheme(theme)
                    set("battery","backgroundShade",.4); set("battery","percentageBackgroundShade",-.25)
                    set("battery","foregroundShade",.2); set("battery","percentageForegroundShade",-.3)
                    compareInk(left.color,Theme.Theme.shadeAccent(Theme.Theme.roles.blue,.4))
                    compareInk(right.color,Theme.Theme.shadeAccent(Theme.Theme.roles.green,-.25))
                    compareInk(icon.color,Theme.Theme.shadeAccent(Theme.Theme.background,.2))
                    compareInk(percentageText.color,Theme.Theme.shadeAccent(Theme.Theme.background,-.3))
                    capture(theme+"-refined")
                }
                set("wifi","foregroundShade",.5); compareInk(Theme.Theme.barAccent("wifi"),Theme.Theme.shadeAccent(Theme.Theme.background,.5))
                set("wifi","foregroundOffShade",-.4); compareInk(Theme.Theme.barItemForeground("wifi",Theme.Theme.muted,false),Theme.Theme.shadeAccent(Theme.Theme.muted,-.4))
                set("battery","percentageBackgroundRole",null); set("battery","percentageBackgroundShade",null)
                compare(left.color,right.color,"percentage inherits icon role and shade")
                let visual=JSON.parse(JSON.stringify(Services.Settings.data.bar.visual)); visual.statusPills.opacity=.4; Services.Settings.setValue("bar","visual",visual); verify(Math.abs(item("batteryBackgrounds").opacity-.4)<.01); compare(left.color.a,1); compare(right.color.a,1)
                visual.statusPills.enabled=false; Services.Settings.setValue("bar","visual",visual); compare(item("batteryBackgrounds").opacity,0)
                tryCompare(Services.Settings,"saveState","saved"); wait(100)
                const saved=JSON.stringify(Services.Settings.data.bar.modules)
                verify(Services.Settings.discardAndReload()); tryCompare(Services.Settings,"ready",true); compare(JSON.stringify(Services.Settings.data.bar.modules),saved)
                console.log("Daily polish PASS")
            } catch(error) { console.error("Daily polish FAIL: " + error + " at " + error.stack); throw error } finally { finish.start() }
        }
    }
}
