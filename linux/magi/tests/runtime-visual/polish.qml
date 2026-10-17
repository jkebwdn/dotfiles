import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/hub" as HubUI
import "../../.config/quickshell/magi/components/notifications" as NotificationUI
import "../../.config/quickshell/magi/components/wallpaper" as WallpaperUI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    BarUI.Bar { id: bar; expandableHostMode: "combined" }
    HubUI.HubWindow { id: hub }
    QtObject { id: record; property var notification: null; property var data: ({id:1,summary:"A notification",body:"One leading visual",appName:"Source",appIcon:Qt.resolvedUrl("square.ppm").toString(),image:""}); property double updatedAt: Date.now(); property bool hovered: false }
    FloatingWindow {
        id: samples; visible: true; implicitWidth: 500; implicitHeight: 450
        NotificationUI.NotificationCard { id: card; width: 400; height: implicitHeight; record: record; service: Services.Notifications }
        WallpaperUI.WallpaperTile { id: tile; y: 220; width: 220; height: 170; entry: ({url:Qt.resolvedUrl("test-artwork.ppm"),name:"Wallpaper"}) }
    }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "Phase2EPolish"
        when: Services.Settings.ready
        function collect(item, predicate) {
            let result=predicate(item)?[item]:[]
            for (const child of item.children || []) result=result.concat(collect(child,predicate))
            return result
        }
        function borders(item) { return collect(item,i=>i.surfaceId!==undefined && i.family!==undefined) }
        function test_polish() {
            try {
                for (const palette of ["catppuccin-mocha","catppuccin-frappe","everforest-light-hard"]) {
                    Services.Settings.setTheme(palette)
                    for (const id of ["controlcentre","wifi","bluetooth"]) {
                        Services.MenuController.open(id); tryCompare(bar.expandablePillRegistry[id],"phase",3)
                        const frame=borders(bar.contentItem).find(b=>b.surfaceId===id)
                        verify(frame!==undefined,id+" production frame")
                        const width=frame.width, height=frame.height
                        for(const enabled of [true,false]) {
                            const style=Object.assign({},Services.Settings.data.appearance.surfaceBorders,{role:"accent",width:3})
                            style[id]=enabled
                            Services.Settings.setValue("appearance","surfaceBorders",style); wait(20)
                            compare(frame.border.width,enabled?3:0); compare(frame.visible,enabled)
                            compare(frame.border.color,Theme.Theme.accent)
                            compare(frame.width,width);compare(frame.height,height);compare(bar.exclusiveZone,48)
                        }
                        if(id==="controlcentre") {
                            const profile=findChild(bar.contentItem,"runtimeProfile")
                            const avatar=findChild(profile,"runtimeAvatar")
                            const aw=avatar.width
                            Services.Settings.setValue("appearance","profileBackground",{enabled:true,role:"elevated"});wait(20)
                            compare(profile.color,Theme.Theme.elevated);compare(avatar.width,aw)
                            compare(profile.radius,Theme.Theme.radius("controlTile",10,profile.width,profile.height))
                            Services.Settings.setValue("appearance","profileBackground",{enabled:false,role:"elevated"});wait(20)
                            compare(profile.color,"#00000000")
                            const toggle=findChild(bar.contentItem,"mediaToggle")
                            const title=findChild(bar.contentItem,"mediaTitle")
                            for(const mode of ["always","active","hidden"]) {
                                Services.Settings.setValue("media","controlsVisibility",mode)
                                for(const active of [false,true]) {
                                    Services.Media.available=active;wait(20)
                                    compare(toggle.visible,mode==="always" || mode==="active"&&active)
                                    if(mode==="always"&&!active) verify(!toggle.available)
                                    if(toggle.visible) compare(toggle.mapToItem(bar.contentItem,0,0).x >= title.mapToItem(bar.contentItem,0,0).x,true)
                                }
                            }
                        }
                        Services.MenuController.close();wait(550)
                    }
                    Services.Hub.open("apps");wait(100)
                    for(const frame of borders(hub.contentItem)) {
                        for(const width of [0,4]) {
                            const style=Object.assign({},Services.Settings.data.appearance.surfaceBorders,{width:width,role:"text",hubContent:true,hubSelector:true})
                            Services.Settings.setValue("appearance","surfaceBorders",style);wait(20)
                            compare(frame.border.width,width);compare(frame.visible,width>0);compare(frame.border.color,Theme.Theme.text)
                        }
                    }
                    Services.Hub.close()
                    for(const history of [false,true]) {
                        card.historyCard=history
                        for(const enabled of [true,false]) {
                            Services.Settings.setValue("appearance","notificationBorders",{role:"accent",width:2,toasts:enabled,history:enabled});wait(20)
                            const frame=borders(card)[0]
                            compare(frame.border.width,enabled?2:0);compare(frame.border.color,Theme.Theme.accent)
                        }
                    }
                    const app=findChild(card,"notificationAppIcon"), art=findChild(card,"notificationImage")
                    tryCompare(app,"status",Image.Ready);verify(app.visible&&!art.visible)
                    record.data=Object.assign({},record.data,{image:Qt.resolvedUrl("test-artwork.ppm").toString()})
                    tryCompare(art,"status",Image.Ready);verify(art.visible&&!app.visible)
                    verify(findChild(art,"artworkEffect").maskEnabled)
                    record.data=Object.assign({},record.data,{image:""});wait(30)
                    tile.current=true;tile.keyboardFocused=false;wait(20)
                    const outer=tile.children[0]; compare(outer.border.width,3);compare(outer.border.color,Theme.Theme.accent)
                    tile.keyboardFocused=true;wait(20);compare(outer.border.width,3)
                    verify(collect(outer,i=>i.border!==undefined&&i.border.width===1&&i.z===2).length===1)
                    tile.favourite=true;compare(findChild(tile,"wallpaperFavourite").Accessible.name,"Remove favourite")
                    if(Quickshell.env("MAGI_POLISH_CAPTURES")) grabImage(samples.contentItem).save(Quickshell.env("MAGI_POLISH_CAPTURES")+"/polish-"+palette+".png")
                }
                console.log("Phase 2E polish PASS")
            } catch(error) { console.error("FAIL:",error,error.stack) }
            finally { finish.start() }
        }
    }
}
