pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
import "../../../settings/SettingsSchema.js" as Schema

Item {
    id: root
    objectName: "settingsPage-Hub"
    property string mode: "Layout"
    property alias selection: selection
    property alias preview: preview
    property alias body: inspector.body
    property alias contentItem: inspector.contentItem
    property alias contentY: inspector.contentY
    property alias contentHeight: inspector.contentHeight
    readonly property int boundsBehavior: inspector.boundsBehavior
    SettingsUI.EditorSelection {
        id: selection
        familyForInstance: id => id
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        Label {
            text: "Hub"
            font.pixelSize: 24
            font.bold: true
            color: Theme.Theme.text
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: ["Layout", "Colours & Look", "Behaviour"]
                SettingsUI.SettingsButton {
                    required property string modelData
                    text: modelData
                    primary: root.mode === modelData
                    onClicked: root.mode = modelData
                }
            }
        }
        SettingsUI.VisualEditorFrame {
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            Layout.preferredHeight: 0
            columns: width < 400 ? 1 : 2
            SettingsUI.HubPreview {
                id: preview
                objectName: "hubEditorPreview"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * .48
                Layout.minimumWidth: 0
                Layout.minimumHeight: parent.columns === 1 ? 120 : 100
                selectedKey: selection.instance
                onSelected: key => selection.select(key)
            }
            SettingsUI.SettingsPage {
                id: inspector
                objectName: "hubEditorInspector"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * .52
                Layout.minimumWidth: 0
                Layout.minimumHeight: 140
                title: root.mode === "Layout" ? "Layout" : root.mode === "Behaviour" ? "Behaviour" : selection.instance === "selector" ? "Hub selector — shared" : selection.instance === "toggles" ? "Hub toggles" : "Hub content"
                description: "One Hub shell, five modes. Child-feature appearance stays with its own Settings page."
                Label {
                    text: "Preview mode (not saved)"
                    color: Theme.Theme.subtext
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                SettingsUI.SettingsSelector {
                    objectName: "hubPreviewMode"
                    Layout.fillWidth: true
                    model: ["Apps", "Clipboard", "Notifications", "Emoji", "Settings"]
                    currentIndex: ["apps", "clipboard", "notifications", "emoji", "settings"].indexOf(preview.mode)
                    onActivated: preview.mode = ["apps", "clipboard", "notifications", "emoji", "settings"][currentIndex]
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: [
                            {
                                id: "",
                                label: "Content"
                            },
                            {
                                id: "selector",
                                label: "Selector"
                            },
                            {
                                id: "toggles",
                                label: "Toggles"
                            }
                        ]
                        SettingsUI.SettingsButton {
                            required property var modelData
                            text: modelData.label
                            primary: selection.instance === modelData.id
                            onClicked: {
                                selection.select(modelData.id);
                                root.mode = "Colours & Look";
                                if (modelData.id === "toggles")
                                    preview.mode = "settings";
                            }
                        }
                    }
                }
                ColumnLayout {
                    visible: root.mode === "Layout"
                    Layout.fillWidth: true
                    Label {
                        text: "Selector position"
                        color: Theme.Theme.text
                    }
                    SettingsUI.SettingsSelector {
                        objectName: "hubSelectorPosition"
                        Layout.fillWidth: true
                        model: ["Below content", "Above content"]
                        currentIndex: Services.Settings.data.hub.selectorPosition === "above" ? 1 : 0
                        onActivated: Services.Settings.setValue("hub", "selectorPosition", currentIndex ? "above" : "below")
                    }
                    Label {
                        text: "Vertical anchor · " + Math.round(Services.Settings.data.hub.verticalPosition * 100) + "%"
                        color: Theme.Theme.text
                    }
                    SettingsUI.SettingsSlider {
                        objectName: "hubVerticalPosition"
                        Layout.fillWidth: true
                        from: .1
                        to: .9
                        stepSize: .01
                        value: Services.Settings.data.hub.verticalPosition
                        onMoved: Services.Settings.setValue("hub", "verticalPosition", value)
                    }
                    SettingsUI.SettingsHelp {
                        text: "The selector anchors the Hub on the output; content grows away from it and stays within the screen. The canvas shows the same clamping principle."
                    }
                }
                ColumnLayout {
                    visible: root.mode === "Colours & Look" && selection.instance === ""
                    Layout.fillWidth: true
                    SettingsUI.SurfaceStyleSettings {
                        title: "Hub content"
                        group: "surfaceBorders"
                        showSharedControls: false
                        targets: [
                            {
                                id: "hubContent",
                                label: "Content border"
                            }
                        ]
                    }
                    SettingsUI.SettingsHelp {
                        text: "Content uses the theme Surface background. Border colour/width and surface roundness are shared with other expanded surfaces; they are not Hub-specific."
                    }
                    SettingsUI.SettingsButton {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "Shared surface appearance ↗"
                        onClicked: Services.SettingsWindowState.page = "Appearance"
                    }
                }
                ColumnLayout {
                    visible: root.mode === "Colours & Look" && selection.instance === "selector"
                    Layout.fillWidth: true
                    Label {
                        text: "Selected mode colour"
                        color: Theme.Theme.text
                    }
                    SettingsUI.SemanticPaletteSelector {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        objectName: "hubSelectionRole"
                        role: Services.Settings.data.appearance.hubSelectionRole
                        onRoleSelected: value => Services.Settings.setValue("appearance", "hubSelectionRole", value)
                    }
                    SettingsUI.SurfaceStyleSettings {
                        title: "Hub selector"
                        group: "surfaceBorders"
                        showSharedControls: false
                        targets: [
                            {
                                id: "hubSelector",
                                label: "Selector border"
                            }
                        ]
                    }
                    Label {
                        text: "Selector corner roundness"
                        color: Theme.Theme.text
                    }
                    SettingsUI.SettingsSlider {
                        Layout.fillWidth: true
                        from: 0
                        to: 2
                        stepSize: .05
                        value: Services.Settings.data.appearance.roundness.roles.hubSelector ?? Services.Settings.data.appearance.roundness.master
                        onMoved: Services.Settings.setRoundness("hubSelector", value)
                    }
                    SettingsUI.SettingsButton {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "Follow Master roundness"
                        onClicked: Services.Settings.setRoundness("hubSelector", null)
                    }
                    SettingsUI.SettingsHelp {
                        text: "All five modes share this selector. Border colour and width are shared expanded-surface tokens."
                    }
                    SettingsUI.SettingsButton {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "Shared selector borders ↗"
                        onClicked: Services.SettingsWindowState.page = "Appearance"
                    }
                }
                ColumnLayout {
                    visible: root.mode === "Colours & Look" && selection.instance === "toggles"
                    Layout.fillWidth: true
                    Label {
                        text: "Hub-hosted Settings toggle colour"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        color: Theme.Theme.text
                    }
                    SettingsUI.SemanticPaletteSelector {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        objectName: "hubToggleRole"
                        role: Services.Settings.data.appearance.hubToggleRole
                        onRoleSelected: value => Services.Settings.setValue("appearance", "hubToggleRole", value)
                    }
                    Label {
                        text: "Switch style — shared"
                        color: Theme.Theme.text
                    }
                    SettingsUI.SettingsSelector {
                        objectName: "sharedToggleStyle"
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        model: ["Pill", "Filled", "Minimal"]
                        currentIndex: ["pill", "filled", "minimal"].indexOf(Services.Settings.data.appearance.toggleStyle)
                        onActivated: Services.Settings.setValue("appearance", "toggleStyle", ["pill", "filled", "minimal"][currentIndex])
                    }
                    SettingsUI.SettingsHelp {
                        text: "Style affects all Settings switches and the Wi-Fi/Bluetooth menu switches. Toggle colour affects Hub-hosted Settings switches only; selector colour is independent. Shared switch roundness lives in Appearance."
                    }
                }
                SettingsUI.SettingsHelp {
                    visible: root.mode === "Behaviour"
                    text: "Hub retains each mode while switching. Escape closes it; outside clicks pass through without dismissing it. Search belongs to each feature. Selector anchoring is in Layout. No additional Hub behaviour settings exist."
                }
                SettingsUI.SettingsButton {
                    visible: ["clipboard", "notifications", "emoji"].includes(preview.mode)
                    text: "Edit " + ({
                            clipboard: "Clipboard",
                            notifications: "Notifications",
                            emoji: "Emoji"
                        })[preview.mode] + " ↗"
                    onClicked: Services.SettingsWindowState.page = ({
                            clipboard: "Clipboard",
                            notifications: "Notifications",
                            emoji: "Emoji"
                        })[preview.mode]
                }
                SettingsUI.SettingsButton {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "Reset Hub appearance"
                    flat: true
                    onClicked: {
                        Services.Settings.resetSection("hub");
                        Services.Settings.setRoundness("hubSelector", null);
                        for (const key of ["hubSelectionRole", "hubToggleRole"])
                            Services.Settings.setValue("appearance", key, Schema.defaults().appearance[key]);
                    }
                }
            }
        }
        SettingsUI.SettingsHelp {
            text: "Preview selection is local. Changes autosave; Reload from disk discards pending edits."
        }
    }
}
