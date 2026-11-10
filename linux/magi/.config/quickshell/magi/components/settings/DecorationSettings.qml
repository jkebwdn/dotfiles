pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme

SettingsSection {
    id: root
    objectName: "decorationSettings"
    title: "Decorative Image"
    collapsible: true
    expanded: configuration.enabled
    readonly property int requestId: SettingsImagePicker.kind === "decoration" ? SettingsImagePicker.requestId : 0
    readonly property string error: SettingsImagePicker.errors["decoration"] || ""
    readonly property var configuration: Services.Settings.data.controlCentre.decoration
    function setOption(key, value) {
        const next = Object.assign({}, configuration)
        next[key] = value
        Services.Settings.setValue("controlCentre", "decoration", next)
    }
    SettingsToggle {
        objectName: "decorationEnabled"
        text: "Show decorative image"
        checked: root.configuration.enabled
        onClicked: root.setOption("enabled", checked)
    }
    SettingsHelp { text: "A transparent PNG or animated GIF beside the left edge. The panel arrives first, then the image appears above its border." }
    SettingsButton {
        objectName: "chooseDecorationImage"
        text: root.requestId ? "Importing…" : "Choose PNG or GIF…"
        enabled: !SettingsImagePicker.busy
        onClicked: SettingsImagePicker.choose("decoration", root.Window.window)
    }
    SettingsButton {
        text: "Clear image"
        enabled: root.requestId === 0 && !!root.configuration.asset
        onClicked: root.setOption("asset", null)
    }
    // Decode only a small availability sample; never a second live panel.
    Image {
        id: availability
        visible: false
        source: root.configuration.asset ? Services.AssetManager.assetUrl(root.configuration.asset.id) : ""
        sourceSize: Qt.size(1, 1)
        asynchronous: true
    }
    SettingsHelp {
        text: !root.configuration.asset ? "No image selected" : availability.status === Image.Error
            ? "Image unavailable — choose the file again." : "Original colours and transparency are preserved."
    }
    Repeater {
        model: [
            {key:"height", label:"Height (px)", low:120, high:600},
            {key:"overlap", label:"Border overlap (px)", low:0, high:24},
            {key:"verticalOffset", label:"Vertical position (px)", low:-300, high:300},
            {key:"duration", label:"Reveal duration (ms)", low:120, high:500}
        ]
        ColumnLayout {
            id: option
            required property var modelData
            Layout.fillWidth: true
            SettingsRow {
                Label { text: option.modelData.label; Layout.fillWidth: true }
                SettingsNumber {
                    objectName: "decoration-" + option.modelData.key
                    Accessible.name: "Decorative image " + option.modelData.label
                    from: option.modelData.low; to: option.modelData.high; stepSize: 1
                    value: root.configuration[option.modelData.key]
                    onValueModified: root.setOption(option.modelData.key, value)
                }
            }
            SettingsSlider {
                objectName: "decorationSlider-" + option.modelData.key
                Accessible.name: "Decorative image " + option.modelData.label
                Layout.fillWidth: true
                from: option.modelData.low; to: option.modelData.high; stepSize: 1
                snapMode: Slider.SnapAlways
                value: root.configuration[option.modelData.key]
                onMoved: root.setOption(option.modelData.key, Math.round(value))
            }
        }
    }
    SettingsHelp { text: "Negative vertical values move up from the panel’s centre. The image fits available space; narrow displays may shrink or hide it." }
    SettingsToggle {
        objectName: "decorationFlip"
        text: "Flip horizontally"
        checked: root.configuration.flip
        onClicked: root.setOption("flip", checked)
    }
    Label { visible: root.error.length > 0; text: root.error; color: Theme.Theme.red; wrapMode: Text.Wrap; Layout.fillWidth: true }
}
