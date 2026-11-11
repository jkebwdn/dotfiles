import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/settings/pages" as Pages
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    id: root
    property var imported: null
    property string importError: ""
    QtObject { id: first; property string name: "TEST-1" }
    QtObject { id: second; property string name: "TEST-2" }
    Connections {
        target: Services.AssetManager
        function onDecorationImageImported(requestId, asset, error) { root.imported = asset; root.importError = error }
    }
    BarUI.Bar { id: bar; visible: true; expandableHostMode: "combined"; outputScreen: first }
    BarUI.Bar { id: other; visible: true; expandableHostMode: "combined"; outputScreen: second }
    FloatingWindow {
        id: settings; visible: true; implicitWidth: 1000; implicitHeight: 700
        Pages.ControlCentrePage { id: page; anchors.fill: parent }
    }
    FloatingWindow {
        visible: true; implicitWidth: 400; implicitHeight: 240; color: "transparent"
        Item {
            id: sample; anchors.fill: parent
            Rectangle { x: 200; width: 190; height: 240; color: "#00ff00"; border.color: "#ffffff"; border.width: 2 }
            BarUI.ControlCentreDecoration {
                id: artwork; z: 2; panelPresent: true; panelReady: true; animate: false
                panelRect: Qt.rect(200, 0, 190, 240)
            }
        }
    }
    Timer { id: finish; interval: 50; onTriggered: Qt.quit() }
    TestCase {
        name: "ControlCentreDecoration"; when: Services.Settings.ready
        function setOption(key, value) {
            const next = Object.assign({}, Services.Settings.data.controlCentre.decoration)
            next[key] = value
            Services.Settings.setValue("controlCentre", "decoration", next)
        }
        function geometry() {
            const s = bar.statusPresentation
            return [s.x,s.y,s.width,s.height,bar.width,bar.height,bar.exclusiveZone]
        }
        function capture(name) {
            waitForRendering(sample)
            grabImage(sample).save(Quickshell.env("MAGI_DECORATION_TEST_CAPTURE") + "/" + name + ".png")
        }
        function test_decoration() {
            try {
                Services.SurfaceOrigin.enabledScreens = [first,second]
                Services.SurfaceOrigin.mainScreen = first
                const savedBar = JSON.stringify(Services.Settings.data.bar)
                const d = findChild(bar.contentItem,"controlCentreDecoration")
                const d2 = findChild(other.contentItem,"controlCentreDecoration")
                const panel = bar.statusPresentation
                const blur = findChild(bar,"statusPanelBlur")
                verify(d !== null && d2 !== null && blur !== null)
                bar.open("controlcentre")
                tryCompare(panel,"phase",3)
                verify(!d.visible, "No asset is a normal panel")
                const baseline = geometry()
                const blurBaseline = [blur.x,blur.y,blur.width,blur.height]
                Services.AssetManager.importDecorationImage(Qt.resolvedUrl("decoration.png"))
                tryVerify(() => root.imported !== null || root.importError.length > 0)
                compare(root.importError,"")
                compare(root.imported.bounds,[10,10,85,180])
                setOption("asset",root.imported); setOption("height",180); setOption("overlap",8)
                verify(!d.visible, "Import does not enable it")
                setOption("enabled",true)
                tryCompare(d,"progress",1)
                verify(d.visible)
                compare(geometry(),baseline,"Enabling cannot move or resize the panel/window")
                compare([blur.x,blur.y,blur.width,blur.height],blurBaseline,"Image never expands blur")
                compare(d.parent,panel.parent)
                verify(d.z > panel.z)
                verify(!d.parent.clip)
                verify(d.x < panel.x)
                verify(Math.abs(d.x + d.width - panel.x - 8) < .01)
                verify(d.y >= panel.y && d.y+d.height <= panel.y+panel.height)
                verify(!d.activeFocusOnTab && !d.focus)
                tryVerify(() => artwork.visible)
                capture("decoration-alpha")
                Services.Settings.setValue("appearance","theme","nord")
                wait(150); capture("decoration-theme")
                compare(d.sourceUrl,Services.AssetManager.assetUrl(root.imported.id))
                setOption("duration",320)
                // Full lifecycle ordering, reversals, and no accumulating translation.
                for (let i=0;i<3;++i) {
                    bar.close()
                    tryCompare(d,"progress",0)
                    verify(panel.phase !== 0,"Decoration leaves before panel finishes")
                    tryCompare(panel,"phase",0)
                    verify(!d.visible && !d.animating)
                    bar.open("controlcentre")
                    tryVerify(() => panel.phase === 1 || panel.phase === 2)
                    compare(d.progress,0,"Panel leads")
                    for (let n=0; n<2000 && panel.phase !== 3; ++n) { verify(!d.revealing); wait(1) }
                    compare(panel.phase,3)
                    verify(d.revealing)
                    verify(d.progress < 1,"Decoration begins its own reveal after panel settles")
                    wait(80)
                    verify(d.progress > 0 && d.progress < .5, "Slower reveal starts gently instead of popping in")
                    tryCompare(d,"progress",1)
                    compare(geometry(),baseline)
                    verify(Math.abs(d.x + d.width - panel.x - 8)<.01)
                }
                // Artwork cannot intercept panel-edge or existing outside-dismiss input.
                mouseClick(bar.contentItem, d.x+d.width-1, d.y+10)
                compare(Services.MenuController.activeMenu,"controlcentre")
                mouseClick(bar.contentItem, d.x+d.width/2, d.y+d.height/2)
                tryCompare(panel,"phase",0)
                verify(!d.animating && d.progress === 0)
                bar.open("controlcentre"); tryCompare(panel,"phase",3); tryCompare(d,"progress",1)
                bar.close(); wait(20); bar.open("controlcentre")
                tryCompare(panel,"phase",3); tryCompare(d,"progress",1)
                Services.MenuController.navigate("wifi")
                tryCompare(d,"progress",0); verify(!d.visible)
                Services.MenuController.back()
                tryCompare(panel,"phase",3); tryCompare(d,"progress",1)
                // Invocation-time output ownership, no main-output exception.
                other.open("controlcentre")
                tryCompare(other.statusPresentation,"phase",3)
                tryCompare(d2,"progress",1); verify(d2.visible); verify(!d.visible)
                Services.SurfaceOrigin.enabledScreens = [first]
                tryCompare(other.statusPresentation,"phase",0)
                verify(!d2.visible)
                Services.SurfaceOrigin.enabledScreens = [first,second]
                bar.open("controlcentre"); tryCompare(panel,"phase",3); tryCompare(d,"progress",1)
                // Compact screens shrink then hide the artwork; panel remains usable.
                setOption("height",600)
                bar.contentItem.Window.window.width = 540; wait(300)
                const compactPanel = geometry()
                verify(!d.visible || (d.x >= 8 && d.x+d.width <= bar.width && d.height < 600))
                setOption("enabled",false); wait(100); compare(geometry(),compactPanel)
                setOption("enabled",true); bar.contentItem.Window.window.width = 380; wait(300)
                verify(!d.visible, JSON.stringify({width:bar.width,panel:geometry(),image:[d.x,d.width,d.height],fits:d.fits})); verify(panel.interactive)
                bar.contentItem.Window.window.width = 1200; setOption("height",180); tryVerify(() => d.visible)
                Services.Settings.setValue("bar","position","bottom"); wait(200)
                verify(d.y >= 0 && d.y+d.height <= bar.height)
                Services.Settings.setValue("bar","position","top")
                // Real Settings input and immediate static preview / saved preferences.
                 wait(100)
                const slider = findChild(page,"decorationSlider-height")
                const stepper = findChild(page,"decoration-height")
                const preview = findChild(page,"decorationPreview")
                verify(slider && stepper && preview)
                // Title-aligned panel fit may leave insufficient left space for art.
                // Decode still succeeds; the accepted preview fallback must follow fits.
                tryVerify(() => preview.ready)
                compare(preview.visible, preview.fits)
                page.Window.window.requestActivate(); slider.forceActiveFocus(); tryVerify(() => slider.activeFocus)
                keyClick(Qt.Key_Right); tryCompare(stepper,"value",181)
                tryCompare(d,"height",181)
                stepper.forceActiveFocus(); keyClick(Qt.Key_Up); tryCompare(slider,"value",182)
                const durationStepper = findChild(page,"decoration-duration")
                durationStepper.forceActiveFocus(); keyClick(Qt.Key_Up)
                tryCompare(findChild(page,"decorationSlider-duration"),"value",321)
                compare(Services.Settings.data.controlCentre.decoration.duration,321)
                setOption("overlap",12); setOption("verticalOffset",-20); setOption("flip",true)
                tryCompare(Services.Settings,"saveState","saved")
                const saved = JSON.stringify(Services.Settings.data.controlCentre.decoration)
                page.resetComposition()
                compare(JSON.stringify(Services.Settings.data.controlCentre.decoration),saved)
                tryCompare(Services.Settings,"saveState","saved")
                Services.Settings.discardAndReload(); wait(200)
                compare(JSON.stringify(Services.Settings.data.controlCentre.decoration),saved)
                compare(JSON.stringify(Services.Settings.data.bar),savedBar)
                // Native GIF playback, all-frame bounds and idle resource gating.
                const pngAsset = root.imported
                root.imported = null
                Services.AssetManager.importDecorationImage(Qt.resolvedUrl("alpha.gif"))
                tryVerify(() => root.imported !== null || root.importError.length > 0)
                compare(root.importError, "")
                compare(root.imported.bounds,[1,6,20,13])
                const gifAsset = root.imported
                setOption("asset",gifAsset)
                tryVerify(() => d.ready && d.presenter.frameCount === 2)
                tryCompare(d,"progress",1)
                const firstFrame = d.presenter.currentFrame
                tryVerify(() => d.presenter.currentFrame !== firstFrame)
                tryVerify(() => d.presenter.currentFrame === firstFrame)
                verify(!d.presenter.paused)
                tryVerify(() => preview.ready)
                verify(preview.presenter.paused, "Settings preview is still")
                const previewFrame = preview.presenter.currentFrame
                bar.close()
                tryCompare(d,"progress",0); tryCompare(panel,"phase",0)
                verify(d.presenter.paused)
                const closedFrame = d.presenter.currentFrame
                wait(350)
                compare(d.presenter.currentFrame,closedFrame,"No frame updates while closed")
                compare(preview.presenter.currentFrame,previewFrame)
                bar.open("controlcentre")
                tryVerify(() => panel.phase === 1 || panel.phase === 2)
                verify(d.presenter.paused,"Playback also waits for the panel")
                tryCompare(panel,"phase",3); tryCompare(d,"progress",1)
                tryVerify(() => d.presenter.currentFrame !== closedFrame)
                other.open("controlcentre")
                tryCompare(d2,"progress",1)
                verify(d.presenter.paused && !d2.presenter.paused,"Only the owning output plays")
                bar.open("controlcentre"); tryCompare(d,"progress",1)
                setOption("flip",false); setOption("height",130); setOption("overlap",8); setOption("verticalOffset",0)
                artwork.playbackEnabled = false
                tryVerify(() => artwork.ready && artwork.presenter.paused)
                artwork.presenter.currentFrame = 0; wait(40); capture("decoration-gif-first")
                artwork.presenter.currentFrame = 1; wait(40); capture("decoration-gif-later")
                for (const asset of [pngAsset,gifAsset,pngAsset]) {
                    setOption("asset",asset)
                    tryVerify(() => d.ready)
                    if (asset.id.endsWith(".gif")) {
                        tryCompare(d,"progress",1)
                        verify(d.presenter.playing && !d.presenter.paused)
                    } else verify(d.presenter.playing === undefined)
                }
                root.imported = pngAsset
                // Missing files fail only the image; no placeholder or panel failure.
                setOption("asset",Object.assign({},root.imported,{id:"decoration-image:"+"e".repeat(64)+".png"}))
                tryVerify(() => !d.ready && !d.visible)
                verify(panel.interactive)
                setOption("asset",null); verify(!d.visible)
                console.log("Control Centre decoration runtime PASS")
            } catch(error) { console.error("Control Centre decoration FAIL: "+error+" at "+error.stack); throw error }
            finally { finish.start() }
        }
    }
}
