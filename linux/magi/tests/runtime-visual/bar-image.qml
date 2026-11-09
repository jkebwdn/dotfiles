import QtQuick
import QtQuick.Controls.Basic
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/components/settings/pages" as Pages
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    id: root
    property var imported: null
    property string importError: ""
    Connections {
        target: Services.AssetManager
        function onBarImageImported(requestId, asset, error) { root.imported = asset; root.importError = error }
    }
    BarUI.Bar { id: bar; visible: true; expandableHostMode: "combined" }
    BarUI.Bar { id: otherBar; visible: true; expandableHostMode: "combined" }
    FloatingWindow {
        id: window; visible: true; implicitWidth: 1000; implicitHeight: 640; color: "transparent"
        Control {
            anchors.fill: parent
            palette.windowText: Theme.Theme.text
            contentItem: Pages.BarPage { id: page }
        }
    }
    FloatingWindow {
        visible: true; implicitWidth: 160; implicitHeight: 64; color: "transparent"
        Item {
            id: sample; anchors.fill: parent
            Rectangle { id: backdrop; anchors.fill: parent; color: "#00ff00"; visible: false }
            BarUI.CustomImage { id: image; anchors.centerIn: parent }
        }
    }
    Timer { id: finish; interval: 50; onTriggered: Qt.quit() }
    TestCase {
        name: "CustomImageRuntime"; when: Services.Settings.ready
        function visual(item, name, visibleOnly) {
            if (item.objectName === name && (!visibleOnly || item.visible)) return item
            for (const child of item.children || []) { const found = visual(child, name, visibleOnly); if (found) return found }
            return null
        }
        function configure(asset, height, trim) {
            const modules = JSON.parse(JSON.stringify(Services.Settings.data.bar.modules))
            modules.customImage = {asset: asset, height: height, trim: trim}
            Services.Settings.setValue("bar", "modules", modules)
        }
        function capture(name) {
            waitForRendering(sample)
            grabImage(sample).save(Quickshell.env("MAGI_BAR_IMAGE_TEST_CAPTURE") + "/" + name + ".png")
        }
        function test_image() {
            try {
                console.log("Beginning Custom Image import")
                Services.AssetManager.importBarImage(Qt.resolvedUrl("alpha.gif"))
                tryVerify(() => root.imported !== null || root.importError.length > 0)
                compare(root.importError, "")
                compare(root.imported.bounds, [1,6,20,13])
                configure(root.imported, 32, true)
                Services.Settings.placeBar("customImage", "left", 2)
                tryVerify(() => image.barVisible)
                compare(image.presenter.frameCount, 2)
                const first = image.presenter.currentFrame
                tryVerify(() => image.presenter.currentFrame !== first)
                tryVerify(() => image.presenter.currentFrame === first) // loops natively
                image.presenter.paused = true
                image.presenter.currentFrame = 0
                wait(100)
                capture("alpha")
                backdrop.visible = true; wait(30); capture("composed")
                backdrop.visible = false
                image.presenter.currentFrame = 1; wait(30); capture("later-frame")
                for (const region of ["left", "center", "right"]) {
                    Services.Settings.placeBar("customImage", region, region === "left" ? 2 : 0)
                    tryVerify(() => bar.placement[region].includes("customImage"))
                    tryVerify(() => visual(bar.contentItem, "barCustomImage") !== null)
                    tryVerify(() => visual(otherBar.contentItem, "barCustomImage") !== null)
                    const live = visual(bar.contentItem, "barCustomImage")
                    tryVerify(() => live.barVisible)
                    verify(Math.abs(live.width - 20 * 32 / 13) < .01)
                    compare(live.height, 28)
                    verify(live.mapToItem(bar.contentItem, 0, 0).y >= 0)
                }
                Services.Settings.placeBar("customImage", "left", 2)
                tryCompare(Services.Settings, "saveState", "saved")
                Services.Settings.discardAndReload(); wait(150)
                tryVerify(() => Services.Settings.data.bar.modules.customImage.asset !== null)
                compare(Services.Settings.data.bar.left, ["clock", "date", "customImage"])
                page.selection.select("customImage"); page.mode = "Appearance"; wait(80)
                compare(page.selection.family, "artwork")
                verify(!findChild(page, "barFamilyInspector").visible)
                verify(!findChild(page, "barIdentityInspector").visible)
                const preview = visual(page, "barPreview-customImage")
                verify(preview !== null)
                tryVerify(() => preview.presenter && preview.presenter.barVisible)
                const sizeSlider = visual(page, "barImageSizeSlider")
                const heightStepper = visual(page, "barImageHeight")
                verify(sizeSlider !== null && sizeSlider.visible)
                page.Window.window.requestActivate()
                sizeSlider.forceActiveFocus()
                tryVerify(() => sizeSlider.activeFocus)
                keyClick(Qt.Key_Left)
                tryCompare(heightStepper, "value", 31)
                compare(Services.Settings.data.bar.modules.customImage.height, 31)
                verify(Math.abs(image.width - 20 * 31 / 13) < .01)
                verify(Math.abs(preview.presenter.width - image.width) < .01)
                mouseClick(sizeSlider, sizeSlider.width - sizeSlider.rightPadding - 1, sizeSlider.height / 2)
                tryCompare(heightStepper, "value", 40)
                mouseClick(sizeSlider, sizeSlider.leftPadding + 1, sizeSlider.height / 2)
                tryCompare(heightStepper, "value", 16)
                heightStepper.forceActiveFocus(); keyClick(Qt.Key_Up)
                tryCompare(sizeSlider, "value", 17)
                tryCompare(Services.Settings, "saveState", "saved")
                Services.Settings.discardAndReload(); wait(150)
                compare(Services.Settings.data.bar.modules.customImage.height, 17)
                page.mode = "Layout"; wait(80)
                // Both inspectors consume the same persisted per-item setting.
                const layoutSlider = visual(page, "barImageSizeSlider", true)
                verify(layoutSlider !== null)
                compare(layoutSlider.value, 17)
                compare(image.bounds[3] * image.imageScale, 17)
                page.mode = "Appearance"
                configure(root.imported, 36, false); wait(80)
                compare(image.width, 36)
                // A static source after an animation, then animation again.
                root.imported = null
                Services.AssetManager.importBarImage(Qt.resolvedUrl("test-artwork.ppm"))
                tryVerify(() => root.importError.length > 0)
                verify(Services.Settings.data.bar.modules.customImage.asset !== null, "Failed imports preserve selection")
                root.importError = ""; root.imported = null
                Services.AssetManager.importBarImage(Qt.resolvedUrl("static-alpha.png"))
                tryVerify(() => root.imported !== null || root.importError.length > 0)
                compare(root.importError, "")
                configure(root.imported, 32, true); tryVerify(() => image.barVisible)
                verify(image.presenter.playing === undefined)
                capture("static-alpha")
                root.imported = null
                Services.AssetManager.importBarImage(Qt.resolvedUrl("alpha.gif"))
                tryVerify(() => root.imported !== null)
                configure(root.imported, 32, true); tryVerify(() => image.barVisible)
                verify(image.presenter.playing)
                configure(null, 32, true); wait(30)
                verify(!image.barVisible); compare(image.width, 0)
                if (Quickshell.env("MAGI_BAR_IMAGE_SOURCE")) {
                    root.imported = null
                    Services.AssetManager.importBarImage(Qt.resolvedUrl("operator.gif"))
                    tryVerify(() => root.imported !== null || root.importError.length > 0)
                    compare(root.importError, "")
                    configure(root.imported, 24, true); tryVerify(() => image.barVisible)
                    compare(image.bounds[3] * image.imageScale, 24)
                    compare(image.presenter.frameCount, 8)
                    compare(root.imported.bounds, [3,167,427,147])
                    const frame = image.presenter.currentFrame
                    tryVerify(() => image.presenter.currentFrame !== frame)
                    const directory = Quickshell.env("MAGI_BAR_IMAGE_REVIEW")
                    image.presenter.paused = true
                    for (let i = 0; i < 8; i++) {
                        image.presenter.currentFrame = i; wait(30)
                        grabImage(sample).save(directory + "/ae86-frame-" + i + ".png")
                    }
                    // Capture the actual 48px Bar instead of the offscreen
                    // combined-menu window's otherwise empty screen height.
                    bar.expandableHostMode = "anchored"
                    bar.contentItem.Window.window.height = 48
                    wait(200)
                    compare(bar.height, 48)
                    grabImage(bar.contentItem).save(directory + "/bar.png")
                    grabImage(page).save(directory + "/settings.png")
                }
                console.log("Custom Image runtime PASS")
            } catch (error) { console.error("Custom Image runtime FAIL: " + error + " at " + error.stack); throw error }
            finally { finish.start() }
        }
    }
}
