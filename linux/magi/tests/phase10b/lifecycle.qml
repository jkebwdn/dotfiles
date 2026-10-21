import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/hub" as HubUI
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: test
    QtObject { id: internal; property string name: "eDP-1"; property int width: 1920; property int height: 1080; property real scale: 2; property var monitor: ({activeWorkspace:{id:1}}) }
    QtObject { id: external; property string name: "HDMI-A-1"; property int width: 2560; property int height: 1440; property real scale: 1.5; property var monitor: ({activeWorkspace:{id:2}}) }
    QtObject { id: reconnect; property string name: "HDMI-A-1"; property int width: 2560; property int height: 1440; property real scale: 1.5; property var monitor: ({activeWorkspace:{id:2}}) }
    BarUI.BarFleet { id: fleet; screens: [internal] }
    HubUI.HubWindow { id: hub; readyToOpen: !fleet.hubBar || fleet.hubBar.settingsReady; previewSurface: fleet.hubBar ? fleet.hubBar.activeCombinedRegion : null }
    FloatingWindow { id: settings; visible: false; implicitWidth: 1000; implicitHeight: 850; UI.SettingsContent { id: settingsContent; anchors.fill: parent } }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "Phase10B"
        when: Services.Settings.ready && fleet.mainBar !== null
        function pause() { wait(600) }
        function bar(screen) { return fleet.barFor(screen) }
        function capture(item,name) {
            const path=Quickshell.env("MAGI_10B_CAPTURES")
            if(path) { let done=false; item.grabToImage(result=>{verify(result.saveToFile(path+"/"+name+".png"));done=true});tryVerify(()=>done,3000) }
        }
        function collect(item) {
            let items=[item]
            for(const child of item.children || []) items=items.concat(collect(child))
            return items
        }
        function surface(b) { return findChild(b.contentItem,"calendarSurface") }
        function checkCount(n) { tryVerify(()=>fleet.presentations.length===n,2000); for(const b of fleet.presentations) compare(b.exclusiveZone,48+b.geometry.edgeOffset) }
        function test_lifecycle() {
            try {
            console.log("10B started")
            Services.Bluetooth.connectedCount=1;Services.Bluetooth.available=true;Services.Bluetooth.enabled=true
            pause();checkCount(1);compare(fleet.mainScreen,internal)
            capture(findChild(bar(internal).contentItem,"captureRoot"),"top-no-inset")
            fleet.screens=[internal,external];pause();checkCount(1)
            Services.Settings.setValue("bar","externalDisplays",true);pause();checkCount(2)
            // Re-read settings without duplicating a presentation or reservation.
            const priorBars=fleet.presentations.slice()
            Services.Settings.discardAndReload();pause();checkCount(2)
            for(const b of priorBars) verify(fleet.presentations.includes(b))
            const retained=bar(internal);let oldExternal=bar(external)
            for(const screen of [internal,external]) {
                const strip=findChild(bar(screen).contentItem,"workspaceStrip")
                compare(strip.activeWorkspace.id,screen.monitor.activeWorkspace.id)
                const cells=collect(strip).filter(c=>c.isActive!==undefined)
                compare(cells.filter(c=>c.isActive).length,1)
                compare(cells.find(c=>c.isActive).modelData.id,screen.monitor.activeWorkspace.id)
                mouseClick(cells[1]);compare(strip.dispatched,'hl.dsp.focus({workspace="2"})')
            }
            capture(findChild(bar(external).contentItem,"captureRoot"),"external-top")
            console.log("10B two bars")
            for(const screen of [internal,external]) {
                const b=bar(screen)
                b.clockAnchor.triggered();pause();compare(Services.SurfaceOrigin.menuTarget(),screen);compare(surface(b).phase,3)
                b.clockAnchor.triggered();pause();compare(surface(b).phase,0)
                for(const view of ["controlcentre","wifi","bluetooth"]) {
                    mouseClick(b.expandablePillRegistry[view].pill)
                    pause()
                    compare(Services.SurfaceOrigin.menuTarget(),screen);compare(b.statusPresentation.phase,3)
                    compare(bar(screen===internal?external:internal).statusPresentation.phase,0)
                    Services.MenuController.close();pause()
                }
                Services.Hub.open("settings",screen);pause();verify(Services.Hub.opened);verify(hub.visible);compare(hub.routedScreen,screen);compare(Services.SurfaceOrigin.hubTarget(),screen);Services.Hub.close();pause()
            }
            console.log("10B origin families complete")
            // Exercise the same entry points used by keyboard IPC handlers.
            for (const view of ["controlcentre", "wifi", "bluetooth", "calendar"]) {
                fleet.focusedMonitor={name:external.name};pause()
                verify(fleet.openFromShortcut(view));pause()
                compare(Services.SurfaceOrigin.menuTarget(),external)
                fleet.focusedMonitor={name:internal.name};pause()
                compare(Services.SurfaceOrigin.menuTarget(),external) // Focus alone does not move it.
                compare(fleet.mainScreen,internal)
                fleet.toggleFromShortcut(view);pause()
                compare(Services.MenuController.activeMenu,view)
                compare(Services.SurfaceOrigin.menuTarget(),internal)
                fleet.toggleFromShortcut(view);pause();compare(Services.MenuController.activeMenu,"")
            }
            for (const mode of ["settings", "apps", "clipboard", "emoji", "notifications"]) {
                fleet.focusedMonitor={name:external.name};pause()
                Services.Hub.openFromShortcut(mode);pause()
                verify(Services.Hub.opened);compare(hub.routedScreen,external)
                fleet.focusedMonitor={name:internal.name};pause()
                compare(hub.routedScreen,external)
                Services.Hub.toggleFromShortcut(mode);pause()
                verify(Services.Hub.opened);compare(hub.routedScreen,internal)
                Services.Hub.toggleFromShortcut(mode);pause();verify(!Services.Hub.opened)
            }
            fleet.focusedMonitor={name:external.name};pause()
            Services.Settings.setValue("bar","externalDisplays",false);pause()
            compare(Services.SurfaceOrigin.shortcutTarget(),internal)
            fleet.openFromShortcut("controlcentre");pause();compare(Services.SurfaceOrigin.menuTarget(),internal)
            Services.MenuController.close()
            Services.Settings.setValue("bar","externalDisplays",true);pause()
            fleet.focusedMonitor={name:"removed-output"};pause()
            compare(Services.SurfaceOrigin.shortcutTarget(),internal)
            fleet.focusedMonitor=null;pause();compare(Services.SurfaceOrigin.shortcutTarget(),internal)
            console.log("10B focused-output shortcuts PASS")
            Services.MenuController.open("controlcentre",external);pause()
            Services.MenuController.toggle("controlcentre",internal);pause()
            compare(Services.MenuController.activeMenu,"controlcentre");compare(bar(internal).statusPresentation.phase,3);compare(bar(external).statusPresentation.phase,0)
            Services.MenuController.toggle("controlcentre",internal);pause();compare(Services.MenuController.activeMenu,"")
            Services.MenuController.open("wifi",external);pause();compare(Services.Network.scanOwners.length,1)
            Services.MenuController.open("wifi",internal);pause();compare(Services.Network.scanOwners.length,1)
            Services.MenuController.close();pause();compare(Services.Network.scanOwners.length,0)
            Services.MenuController.open("bluetooth",external);pause()
            fleet.screens=[internal];pause();checkCount(1);compare(Services.MenuController.activeMenu,"");compare(Services.SurfaceOrigin.menuScreen,null);compare(bar(internal),retained)
            fleet.screens=[internal,reconnect];pause();checkCount(2);verify(bar(reconnect)!==oldExternal);oldExternal=null
            Services.Hub.open("settings",reconnect);pause()
            Services.Settings.setValue("bar","externalDisplays",false);pause();checkCount(1);verify(!Services.Hub.opened);verify(!hub.visible);compare(Services.SurfaceOrigin.hubScreen,null)
            Services.Settings.setValue("bar","externalDisplays",true);pause();checkCount(2)
            for(const position of ["top","bottom","top"]) {
                Services.Settings.setValue("bar","position",position)
                for(const offset of [0,12,32]) {
                    Services.Settings.setValue("bar","edgeOffset",offset);pause()
                    for(const b of fleet.presentations) {
                        compare(b.exclusiveZone,48+offset)
                        compare(b.geometry.top,position==="top"?48+offset:0)
                        compare(b.geometry.bottom,position==="bottom"?48+offset:0)
                        compare(b.barY,position==="top"?offset:b.height-48-offset)
                    }
                }
                Services.Settings.setValue("bar","position",position)
                Services.Settings.setValue("bar","horizontalInset",16)
                Services.Settings.setValue("bar","edgeOffset",12);pause()
                for(const b of fleet.presentations) {compare(b.geometry.inset,16);compare(b.exclusiveZone,48+b.geometry.edgeOffset);compare(b.topReserved,position==="top")}
                const b=bar(internal);b.clockAnchor.triggered();pause()
                const c=surface(b);verify(c.y>=0 && c.y+c.height<=b.height)
                compare(c.bottomUp,position==="bottom")
                capture(findChild(b.contentItem,"captureRoot"),position==="bottom"?"bottom-calendar":"top-inset-calendar")
                Services.MenuController.open("controlcentre",internal);pause()
                verify(b.statusPresentation.y>=0 && b.statusPresentation.y+b.statusPresentation.height<=b.height)
                capture(findChild(b.contentItem,"captureRoot"),position==="bottom"?"bottom-controlcentre":"top-inset-controlcentre")
                Services.MenuController.close();pause()
            }
            Services.Settings.setValue("bar","horizontalInset",64);internal.width=320
            // FloatingWindow retains user size; emulate the compositor's anchored resize.
            bar(internal).contentItem.Window.window.width=320;pause();compare(bar(internal).width,320);verify(bar(internal).geometry.width>=0);verify(bar(internal).geometry.inset<64,"inset must shrink on the narrow output")
            internal.width=1920;bar(internal).contentItem.Window.window.width=1920;pause()
            Services.SettingsWindowState.page="Bar";settings.visible=true;pause()
            const positionControl=findChild(settingsContent,"barPosition")
            compare(positionControl.model.length,2)
            const insetControl=findChild(settingsContent,"horizontalInset")
            compare(insetControl.to,64);insetControl.value=16;insetControl.valueModified();pause();compare(Services.Settings.data.bar.horizontalInset,16)
            const offsetControl=findChild(settingsContent,"edgeOffset");compare(offsetControl.to,32)
            verify(findChild(settingsContent,"externalBars")!==null)
            capture(settingsContent,"settings-bar");settings.visible=false
            // No internal panel: choose focused output once, retain it across focus changes.
            fleet.focusedMonitor={name:external.name}
            fleet.screens=[external];pause();compare(fleet.mainScreen,external)
            fleet.focusedMonitor={name:"DP-2"};pause();compare(fleet.mainScreen,external)
            fleet.screens=[];pause();checkCount(0);compare(fleet.mainScreen,null)
            fleet.screens=[internal];pause();checkCount(1)
            console.log("Phase 10B lifecycle PASS")
            } catch(e) { console.error("FAIL:", e, e.stack) }
            finish.start()
        }
    }
}
