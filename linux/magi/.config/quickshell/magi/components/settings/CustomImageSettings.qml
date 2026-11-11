pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme

SettingsSection {
    id: root
    title: "Custom Image"
    collapsible: false
    readonly property int requestId: SettingsImagePicker.kind === "bar" ? SettingsImagePicker.requestId : 0
    readonly property string error: SettingsImagePicker.errors["bar"] || ""
    readonly property var configuration: Services.Settings.data.bar.modules.customImage || ({})
    function setOption(key, value) {
        const modules = JSON.parse(JSON.stringify(Services.Settings.data.bar.modules))
        modules.customImage = Object.assign({}, modules.customImage || {})
        modules.customImage[key] = value
        Services.Settings.setValue("bar", "modules", modules)
    }
    SettingsHelp { text: "Static images and animated GIFs keep their own colours and transparency. Drag this item beside Time or Date in the Bar layout." }
    SettingsRow {
        Label { text: "Size (height in px)"; Layout.fillWidth: true }
        SettingsNumber {
            objectName: "barImageHeight"
            Accessible.name: "Custom Image height in pixels"
            from: 16; to: 40; stepSize: 1
            value: root.configuration.height || 32
            onValueModified: root.setOption("height", value)
        }
    }
    SettingsSlider {
        objectName: "barImageSizeSlider"
        Accessible.name: "Custom Image size"
        Layout.fillWidth: true
        from: 16; to: 40; stepSize: 1
        snapMode: Slider.SnapAlways
        value: root.configuration.height || 32
        onMoved: root.setOption("height", Math.round(value))
    }
    SettingsHelp { text: "Drag to resize, or use − / + for 1px adjustments. Width follows the image proportions. Changes preview immediately and save automatically." }
    SettingsButton {
        objectName: "chooseBarImage"
        text: root.requestId ? "Importing…" : "Choose image or GIF…"
        enabled: !SettingsImagePicker.busy
        onClicked: SettingsImagePicker.choose("bar", root.Window.window)
    }
    SettingsButton {
        text: "Clear image"
        enabled: root.requestId === 0 && !!root.configuration.asset
        onClicked: root.setOption("asset", null)
    }
    SettingsToggle {
        objectName: "barImageTrim"
        text: "Trim transparent margins"
        checked: root.configuration.trim !== false
        onClicked: root.setOption("trim", checked)
    }
    SettingsHelp { text: "Trimming includes every animation frame. Wide images fit within 240px without stretching." }
    Label { visible: root.error.length > 0; text: root.error; color: Theme.Theme.red; wrapMode: Text.Wrap; Layout.fillWidth: true }
}
