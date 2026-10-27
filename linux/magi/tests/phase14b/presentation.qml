//@ pragma UseQApplication
import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/audio" as AudioUI
import "../../.config/quickshell/magi/components/tray" as TrayUI
import "../../.config/quickshell/magi/plugins/bar/volume" as Volume
ShellRoot {
    id: test
    property int outputCalls: 0
    property int inputCalls: 0
    property var wanted: null
    property var fixtures: []
    Services.AudioModel {
        id: model
        onOutputRequested: node => { test.outputCalls++; test.wanted=node }
        onInputRequested: node => { test.inputCalls++; test.wanted=node }
    }
    Volume.Volume { id: volumeModule }
    QtObject {
        id: app
        property string id: "fixture"
        property string title: "Background utility"
        property string tooltipTitle: title
        property string tooltipDescription: "Synthetic application"
        property string icon: ""
        property int status: 1
        property bool hasMenu: true
        property bool onlyMenu: false
        property QtObject menu: QtObject {}
        property int calls: 0
        function activate(){calls++}
        function secondaryActivate(){calls++}
        function scroll(delta,horizontal){calls++}
    }
    FloatingWindow {
        id: win
        visible: true; implicitWidth: 410; implicitHeight: 680
        color: "#222230"
        Loader { id: measuredMenu; visible: false; width: 340; sourceComponent: volumeModule.menuContent }
        Item {
            id: capture
            anchors.fill: parent
            Rectangle { anchors.fill: parent; color: Theme.Theme.surfaceBackground(Theme.Theme.surface); radius: Theme.Theme.radiusMedium }
            AudioUI.AudioSurface { id: audio; x: 16; y: 16; width: parent.width-32; height: parent.height-80; audioService: model }
            TrayUI.TrayGroup { id: group; x: 16; y: parent.height-48; height: 32; items: [app]; nativeMenus: false; showEmpty: false }
            TrayUI.TrayItem { id: tray; x: 180; y: parent.height-48; width: 32; height: 32; trayItem: app }
            TrayUI.TrayOverflow { id: overflow; x: 80; y: 150; items: [app]; nativeMenus: false; opened: false }
        }
    }
    Component {
        id: device
        QtObject {
            property string description: ""
            property string nickname: ""
            property string name: ""
            property bool isStream: false
            property bool ready: true
            property var properties: ({})
            property QtObject audio: QtObject { property real volume: .65; property bool muted: false }
        }
    }
    Component { id: rebuildTray; TrayUI.TrayItem { width: 32; height: 32; trayItem: app } }
    Timer { id: done; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "Phase14B"
        when: Services.Settings.ready
        function eq(a,b){if(a!==b)throw Error("Expected "+b+", got "+a+" "+new Error().stack)}
        function ok(a){if(!a)throw Error("Assertion failed "+new Error().stack)}
        function node(label,kind,extra){
            return device.createObject(test,{description:label,isStream:kind.startsWith("Stream"),properties:Object.assign({"media.class":kind},extra||{})})
        }
        function captureCase(name){
            wait(30)
            grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE14B_PREVIEWS")+"/"+name+".png")
        }
        function test_actions(){
            try {
                const speaker=node("Built-in Speakers","Audio/Sink"), bt=node("Bluetooth Speaker","Audio/Sink",{"device.api":"bluez5"}), hdmi=node("HDMI Display","Audio/Sink"), usb=node("USB Headphones","Audio/Sink"), mic=node("Built-in Microphone","Audio/Source"), video=node("Camera","Video/Source")
                const stream1=node("Browser","Stream/Output/Audio",{"application.name":"Example Browser","media.name":"Music tab"}),stream2=node("Player","Stream/Output/Audio",{"application.name":"Example Player"}),stream3=node("Browser","Stream/Output/Audio",{"application.name":"Example Browser","media.name":"A very long application stream description ".repeat(8)})
                test.fixtures=[speaker,bt,hdmi,usb,mic,stream1,stream2,stream3,video]
                model.sourceNodes=test.fixtures; model.sink=speaker; model.source=mic
                wait(400)
                Services.Audio.sourceNodes=test.fixtures;Services.Audio.sink=speaker;Services.Audio.source=mic
                wait(60)
                eq(volumeModule.menuHeight,Math.min(volumeModule.maximumMenuHeight,Math.ceil(measuredMenu.item.contentHeight+volumeModule.viewTopPadding+volumeModule.viewBottomPadding)))
                const fullMenuHeight=volumeModule.menuHeight
                Services.Audio.sourceNodes=[speaker];Services.Audio.source=null;wait(60)
                ok(volumeModule.menuHeight<fullMenuHeight)
                eq(volumeModule.menuHeight,Math.ceil(measuredMenu.item.contentHeight+volumeModule.viewTopPadding+volumeModule.viewBottomPadding))
                eq(findChild(audio,"audioLevel-Output volume").height,findChild(audio,"audioLevel-Input volume").height)
                eq(findChild(audio,"audioLevel-Output volume").height,findChild(audio,"audioLevel-Example Browser").height)
                eq(model.outputs.length,4);eq(model.inputs.length,1);eq(model.streams.length,3)
                hdmi.ready=false;eq(model.outputs.length,3);ok(!model.selectOutput(hdmi));hdmi.ready=true;eq(model.outputs.length,4)
                eq(test.outputCalls,0);ok(model.selectOutput(bt));eq(test.outputCalls,1);ok(!model.selectOutput(bt));eq(test.outputCalls,1)
                model.sink=bt;eq(model.pendingOutput,null)
                model.setVolume(.72);eq(bt.audio.volume,.72);eq(speaker.audio.volume,.65)
                model.setNodeVolume(stream1,.45);eq(stream1.audio.volume,.45);eq(stream2.audio.volume,.65);eq(bt.audio.volume,.72)
                model.toggleNodeMute(stream1);ok(stream1.audio.muted);ok(!bt.audio.muted)
                model.setNodeVolume(stream2,3);eq(stream2.audio.volume,1)
                model.setNodeVolume(stream2,-1);eq(stream2.audio.volume,0)
                model.setNodeVolume(stream2,.7)
                eq(model.selectOutput(mic),false);eq(model.selectInput(bt),false)
                model.source=null;ok(model.selectInput(mic));eq(test.inputCalls,1);model.source=mic;eq(model.pendingInput,null)
                model.toggleNodeMute(mic);ok(mic.audio.muted)
                eq(volumeModule.expandsOnClick,true)
                volumeModule.secondaryTriggered();eq(Services.Audio.muteCalls,1)
                volumeModule.wheelTriggered(1);eq(Services.Audio.wheelCalls,1)
                eq(model.applications.length,2)
                eq(findChild(audio,"audioApplications").count,2)
                const browser=model.applications.find(g=>g.label==="Example Browser")
                eq(browser.nodes.length,2)
                const appSlider=findChild(audio,"audioLevel-Example Browser")
                appSlider.valueMoved(.36);eq(stream1.audio.volume,.36);eq(stream3.audio.volume,.36)
                eq(stream2.audio.volume,.7);eq(bt.audio.volume,.72)
                appSlider.iconTriggered();ok(stream1.audio.muted);ok(stream3.audio.muted)
                appSlider.iconTriggered();ok(!stream1.audio.muted);ok(!stream3.audio.muted)
                stream3.audio.volume=.51;eq(appSlider.value,.51)
                const other=node("Example Browser","Stream/Output/Audio",{"application.name":"Example Browser","application.id":"different-app"})
                model.sourceNodes=test.fixtures.concat([other]);eq(model.applications.length,3)
                model.sourceNodes=test.fixtures.filter(n=>n!==stream3);eq(model.applications.length,2)
                model.setGroupVolume(browser,.4);eq(stream1.audio.volume,.4);eq(stream3.audio.volume,.51)
                model.sourceNodes=test.fixtures;wait(30);eq(findChild(audio,"audioApplications").count,2)
                const inputSelector=findChild(audio,"audioInputSelector")
                mouseClick(inputSelector,20,inputSelector.height/2);ok(inputSelector.popup.visible)
                keyClick(Qt.Key_Escape);ok(!inputSelector.popup.visible)
                model.source=null;inputSelector.activated(0);eq(test.inputCalls,2);eq(model.pendingInput,mic);model.source=mic
                const slider=findChild(audio,"audioLevel-Output volume")
                const beforeVolume=bt.audio.volume
                mouseClick(slider,20,slider.height/2);ok(bt.audio.muted);eq(bt.audio.volume,beforeVolume)
                mouseClick(slider,20,slider.height/2);ok(!bt.audio.muted);eq(bt.audio.volume,beforeVolume)
                const selector=findChild(audio,"audioOutputSelector")
                mouseClick(selector,20,selector.height/2);ok(selector.popup.visible)
                captureCase("audio-output-dropdown")
                keyClick(Qt.Key_Escape);ok(!selector.popup.visible)
                captureCase("audio-bluetooth")
                audio.contentY=Math.max(0,audio.contentHeight-audio.height);wait(30);captureCase("audio-input-and-streams");audio.contentY=0
                bt.audio.muted=true;captureCase("audio-muted");bt.audio.muted=false
                audio.height=300;captureCase("audio-compact");audio.height=win.height-80
                Services.Settings.setTheme("rose-pine-dawn");wait(80);captureCase("audio-dawn")
                Services.Settings.setTheme("catppuccin-mocha");wait(80)
                model.sourceNodes=test.fixtures.filter(n=>n!==stream1);eq(model.streams.length,2);ok(!model.setNodeVolume(stream1,.1))
                model.sourceNodes=test.fixtures.filter(n=>n!==bt);model.sink=speaker;eq(model.sink,speaker);eq(test.outputCalls,1)
                // No restart/generation/node-arrival writes. WirePlumber chooses defaults.
                model.sourceNodes=[];model.sink=null;model.sourceNodes=test.fixtures;model.sink=speaker;eq(test.outputCalls,1)
                model.selectOutput(bt);model.selectOutput(usb);eq(test.wanted,usb);model.sink=usb
                eq(test.outputCalls,3)
                // Pointer selection never becomes keyboard-focus selected styling.
                mouseMove(tray,15,15);eq(tray.interactionState,"hover")
                mousePress(tray,15,15);eq(tray.interactionState,"pressed")
                mouseRelease(tray,15,15);eq(app.calls,1);eq(tray.interactionState,"hover")
                mouseMove(capture,380,10);eq(tray.interactionState,"normal");captureCase("tray-post-activation")
                mouseClick(tray,15,15,Qt.RightButton);ok(tray.menuVisible);eq(tray.interactionState,"menu");captureCase("tray-menu-open")
                // Native adapter emits visible=false on all three dismissal paths.
                for(const dismissal of ["outside","escape","action"]){tray.context();tray.closeMenu();ok(!tray.menuVisible);ok(tray.interactionState!=="menu")}
                tray.context();tray.trayItem=null;ok(!tray.menuVisible);tray.trayItem=app
                tray.context();tray.visible=false;ok(!tray.menuVisible);tray.visible=true
                let old=rebuildTray.createObject(capture);old.context();ok(old.menuVisible)
                const callsBefore=app.calls;old.destroy();wait(20)
                let rebuilt=rebuildTray.createObject(capture);ok(!rebuilt.menuVisible);eq(rebuilt.interactionState,"normal");eq(app.calls,callsBefore);rebuilt.destroy()
                app.status=2;mouseMove(capture,380,10);ok(tray.attention);eq(tray.interactionState,"normal");captureCase("tray-attention");app.status=1
                group.items=[];group.showEmpty=false;eq(group.implicitWidth,0);captureCase("tray-empty")
                group.items=[app];captureCase("tray-inline")
                group.visible=false;overflow.opened=true;wait(30);ok(overflow.visible);captureCase("tray-overflow")
                const originalSize=Services.Settings.data.appearance.visual.statusIconSize
                for (const size of [16,22,28]) {
                    Services.Settings.setVisual("statusIconSize",size);wait(30)
                    eq(findChild(overflow.delegates.itemAt(0).button,"trayApplicationArtwork").width,size)
                    eq(findChild(tray,"trayApplicationArtwork").width,size)
                    eq(overflow.cellWidth,group.cellWidth)
                    eq(overflow.width,overflow.cellWidth+16)
                    overflow.items=[app,app,app];wait(30)
                    eq(overflow.width,overflow.cellWidth*3+24)
                    eq(overflow.height,overflow.cellHeight+16)
                    overflow.items=Array(100).fill(app);wait(30)
                    ok(overflow.width<=280);eq(overflow.height,300)
                    overflow.items=[app];wait(30);eq(overflow.width,overflow.cellWidth+16)
                }
                Services.Settings.setVisual("statusIconSize",originalSize);wait(30)
                const popupButton=overflow.delegates.itemAt(0).button
                eq(popupButton.trayItem,app)
                const priorCalls=app.calls
                mouseClick(popupButton,20,20);eq(app.calls,priorCalls+1)
                mouseClick(popupButton,20,20,Qt.MiddleButton);eq(app.calls,priorCalls+2)
                Services.Settings.setTheme("rose-pine-dawn");wait(80);captureCase("tray-dawn")
                overflow.opened=false
                console.log("Phase14B audio actions, identities, lifecycle and tray interaction/preview PASS")
            } catch(error){console.error("Phase14B FAIL: "+error);throw error} finally {Services.Audio.sink=null;Services.Audio.source=null;Services.Audio.sourceNodes=[];done.start()}
        }
    }
}
