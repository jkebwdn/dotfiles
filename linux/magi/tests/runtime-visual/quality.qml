import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as CC
import "../../.config/quickshell/magi/plugins/bar/wifi" as Wifi
ShellRoot {
    Services.NotificationModel { id: notices; preferences: ({enabled:true,toastsEnabled:true,historyLimit:20,maxVisible:4,retentionHours:6,fallbackTimeout:800}) }
    QtObject {
        id: record
        property var notification: null
        property int notificationId: 1
        property double remaining: 0
        property bool hovered: false
        property bool dismissed: false
        property bool read: false
        property double updatedAt: Date.now()
        property var data: ({id:1,transient:false,urgency:1})
    }
    QtObject { id: nativeNotice; property int expires:0; function expire() { expires++; record.notification=null } }
    QtObject {
        id: networkController
        property var selectedNetwork:null
        property var pendingNetwork:null
        property var errorNetwork:null
        property bool connecting:false
        property bool authenticating:false
        property string connectionError:""
        property int menuHeight:400
        property int viewTopPadding:12
        property int viewBottomPadding:12
        property int listCount:1
        property int selections:0
        signal clearPassword()
        function signalIcon(value) {return "wifi"}
        function selectNetwork(network) {selections++}
        function resetTransientState() {}
        function cancelPassword() {selectedNetwork=null;authenticating=false}
        function submitPassword(value) {}
    }
    FloatingWindow {
        id: win; visible:true; implicitWidth:800;implicitHeight:600;color:Theme.Theme.background
        Item {id: parking;focus:true}
        CC.ControlTile {id: tile;x:20;y:20;title:"Wi-Fi";icon:"wifi";property int calls:0;onPrimaryTriggered:calls++}
        Controls.IconSlider {id: slider;x:160;y:25;width:300;value:.5;moduleId:"volume";onValueMoved: moved => slider.value=moved}
        Wifi.WifiMenuContent {id:wifi;x:20;y:150;width:400;controller:networkController}
    }
    Timer {id:finish;interval:100;onTriggered:Qt.quit()}
    TestCase {
        name:"Phase16Quality";when:Services.Settings.ready
        function findRow(item) {
            if(item.strength !== undefined && item.modelData !== undefined) return item
            for(const child of item.children || []) {const row=findRow(child);if(row)return row}
            return null
        }
        function changedByFocus(item) {
            parking.forceActiveFocus();waitForRendering(item);const before=grabImage(item)
            item.forceActiveFocus();tryCompare(item,"activeFocus",true);waitForRendering(item)
            return !grabImage(item).equals(before)
        }
        function test_quality() {try {
            Services.Network.availableNetworks=[{name:"Long synthetic wireless network name — accessibility audit",connected:false,signalStrength:.8,known:true,security:0}]
            tryVerify(()=>findRow(wifi)!==null)
            const row=findRow(wifi)
            Services.Settings.setVisual("sliderBorderWidth",0)
            const tileFocus=changedByFocus(tile),sliderFocus=changedByFocus(slider)
            const tick=notices.lastTick;wait(250);const idleTicking=notices.lastTick!==tick
            console.log("Phase16 evidence: tile focus changes pixels="+tileFocus+", zero-rim slider focus changes pixels="+sliderFocus+", idle notification clock advances="+idleTicking+", Wi-Fi accessible name="+row.Accessible.name)
            verify(tileFocus,"Keyboard focus must change Control Centre pixels")
            verify(sliderFocus,"Zero decorative rim must retain a focus outline")
            compare(idleTicking,false,"No idle 50 ms work")
            verify(row.Accessible.name.indexOf(Services.Network.availableNetworks[0].name)>=0)
            row.forceActiveFocus();keyClick(Qt.Key_Return);compare(networkController.selections,1)
            row.Accessible.pressAction();compare(networkController.selections,2)
            mouseClick(row,row.width-2,20);compare(networkController.selections,3)
            verify(findChild(wifi,"wifiPasswordInput").Accessible.name.indexOf(Services.Network.availableNetworks[0].name)>=0)
            tile.forceActiveFocus();keyClick(Qt.Key_Tab);tryCompare(slider,"activeFocus",true)
            keyClick(Qt.Key_Tab,Qt.ShiftModifier);tryCompare(tile,"activeFocus",true)
            keyClick(Qt.Key_Space);compare(tile.calls,1)
            parking.forceActiveFocus();tile.available=false;tile.Accessible.pressAction();compare(tile.calls,1);tile.available=true
            slider.forceActiveFocus();keyClick(Qt.Key_Left);fuzzyCompare(slider.value,.45,.001)
            keyClick(Qt.Key_Home);compare(slider.value,0);keyClick(Qt.Key_End);compare(slider.value,1);slider.value=.5
            // The first notification after a long idle must receive its complete lifetime.
            notices.lastTick=Date.now()-100000
            record.remaining=600;record.notification=nativeNotice;notices.records=[record]
            wait(120);verify(record.remaining>300);compare(nativeNotice.expires,0)
            record.hovered=true;const paused=record.remaining;wait(200);compare(record.remaining,paused)
            record.hovered=false;tryCompare(nativeNotice,"expires",1,1200)
            const stopped=notices.lastTick;wait(150);compare(notices.lastTick,stopped)
            // Toast exit still completes even for a persistent notification.
            record.remaining=0;record.notification=nativeNotice
            notices.toasts.append({notificationId:1,exiting:false,exitAt:0})
            notices.hideToast(1);tryCompare(notices.toasts,"count",0,1000)
            const idleAgain=notices.lastTick;wait(150);compare(notices.lastTick,idleAgain)
            const themes=["everforest-dark-hard","kanagawa-wave","dracula","one-dark","gruvbox-dark","gruvbox-light","one-light","rose-pine-dawn"]
            for(const theme of themes) {
                Services.Settings.setTheme(theme);tryCompare(Theme.Theme,"effectiveTheme",theme)
                for(const width of [640,1280,1920]) {
                    win.implicitWidth=width;verify(changedByFocus(tile));verify(changedByFocus(slider))
                    for(const alpha of [1,.75,.5]) {
                        Services.Settings.setValue("applicationAppearance","managed",true)
                        Services.Settings.setValue("applicationAppearance","backgroundOpacity",alpha)
                        fuzzyCompare(Theme.Theme.surfaceBackground(Theme.Theme.surface).a,alpha,.001)
                        compare(Theme.Theme.focus.a,1);compare(Theme.Theme.text.a,1)
                    }
                }
            }
            console.log("Phase16 quality PASS: focus, keyboard, names, idle work, expiry, hover and toast exit")
            finish.start()
        }catch(error){console.error("FAIL: "+error+" "+error.stack);throw error}}
    }
}
