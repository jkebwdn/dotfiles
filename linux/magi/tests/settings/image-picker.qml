import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    FloatingWindow { id: window; visible: true; implicitWidth: 900; implicitHeight: 800
        Loader { id: page; anchors.fill: parent; sourceComponent: UI.DecorationSettings { expanded: true } }
    }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "SettingsImagePicker"
        when: Services.Settings.ready
        function choose() {
            const button = findChild(page.item, "chooseDecorationImage")
            verify(button !== null)
            UI.SettingsImagePicker.dialog.currentFolder = Qt.resolvedUrl(".")
            mouseClick(button)
            tryCompare(UI.SettingsImagePicker.dialog, "visible", true)
            wait(100)
            compare(UI.SettingsImagePicker.dialog.parentWindow, page.item.Window.window)
            verify(UI.SettingsImagePicker.dialog.parentWindow !== null)
        }
        function selectFile(file) {
            const picker = UI.SettingsImagePicker
            const list = findChild(picker.dialog.parentWindow.contentItem, "fileDialogListView")
            verify(list !== null)
            let index = -1
            tryVerify(() => {
                for (let i=0; i<list.count; ++i) if (list.model.get(i, "fileName") === file) { index=i; return true }
                return false
            })
            list.positionViewAtIndex(index, ListView.Center)
            wait(50)
            mouseDoubleClickSequence(list.itemAtIndex(index))
            tryCompare(picker.dialog, "visible", false)
        }
        function test_lifecycle() {
            const picker = UI.SettingsImagePicker
            try {
            const original = JSON.stringify(Services.Settings.data)
            choose()
            picker.dialog.reject()
            tryCompare(picker, "busy", false)
            compare(JSON.stringify(Services.Settings.data), original)
            for (const file of ["alpha.png", "alpha.gif"]) {
                choose()
                selectFile(file)
                page.active = false // Dialog/import owner outlives its caller.
                tryCompare(picker, "requestId", 0)
                tryVerify(() => !!Services.Settings.data.controlCentre.decoration.asset)
                verify(Services.Settings.data.controlCentre.decoration.asset.id.endsWith(file.slice(-4)))
                compare(picker.errors.decoration, "")
                page.active = true
                tryVerify(() => page.item !== null)
            }
            const accepted = JSON.stringify(Services.Settings.data.controlCentre.decoration)
            for (const file of ["unsupported.txt", "missing.png"]) {
                choose(); picker.dialog.close()
                // FileDialog filters/missing-path guards normally prevent acceptance;
                // also verify importer failure cannot corrupt an existing selection.
                picker.importSelected(Qt.resolvedUrl(file))
                tryCompare(picker, "requestId", 0)
                verify(picker.errors.decoration.length > 0)
                compare(JSON.stringify(Services.Settings.data.controlCentre.decoration), accepted)
            }
            choose(); picker.dialog.reject()
            picker.choose("bar", page.item.Window.window)
            tryCompare(picker.dialog, "visible", true)
            selectFile("alpha.gif")
            tryCompare(picker, "requestId", 0)
            tryVerify(() => !!Services.Settings.data.bar.modules.customImage.asset)
            verify(Services.Settings.data.bar.modules.customImage.asset.id.startsWith("bar-image:"))
            Services.SettingsWindowState.shown = true
            choose(); Services.SettingsWindowState.shown = false
            tryCompare(picker.dialog, "visible", false)
            verify(window.visible) // Shared host remains mapped after leaving Settings.
            choose(); window.visible = false
            tryCompare(picker.dialog, "visible", false)
            tryCompare(Services.Settings, "saveState", "saved")
            console.log("Settings image picker PASS")
            finish.start()
            } catch (e) { console.error("FAIL: " + e + " " + e.stack); throw e }
        }
    }
}
