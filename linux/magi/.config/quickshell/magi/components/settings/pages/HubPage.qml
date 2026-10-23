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
        familyKeys: ["selector", "toggles"]
        familyForInstance: id => id
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: SettingsUI.SettingsMetrics.pagePadding
        spacing: 12
        Label {
            text: "Hub"
            font.pixelSize: SettingsUI.SettingsMetrics.titleSize
            font.bold: true
            color: Theme.Theme.text
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: ["Layout", "Appearance"]
                SettingsUI.SettingsButton {
                    required property string modelData
                    text: modelData
                    primary: root.mode === modelData
                    onClicked: root.mode = modelData
                }
            }
            SettingsUI.SettingsSelector {
                objectName: "hubPreviewMode"
                Accessible.name: "Preview mode"
                width: 180
                model: ["Apps", "Clipboard", "Notifications", "Emoji", "Settings"]
                currentIndex: ["apps", "clipboard", "notifications", "emoji", "settings"].indexOf(preview.mode)
                onActivated: preview.mode = ["apps", "clipboard", "notifications", "emoji", "settings"][currentIndex]
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
                titleSize: SettingsUI.SettingsMetrics.sectionSize
                objectName: "hubEditorInspector"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * .52
                Layout.minimumWidth: 0
                Layout.minimumHeight: 140
                title: root.mode === "Layout" ? "" : selection.instance === "selector" ? "Selector" : selection.instance === "toggles" ? "Switches" : "Hub content"
                description: ""
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
                }
                ColumnLayout {
                    visible: root.mode === "Appearance" && selection.instance === ""
                    Layout.fillWidth: true
                    SettingsUI.SurfaceStyleSettings {
                        title: "Hub content"
                        group: "surfaceBorders"
                        showSharedControls: false
                        targets: [
                            {
                                id: "hubContent",
                                label: "Border"
                            }
                        ]
                    }
                    SettingsUI.SettingsHelp {
                        text: "Colour, width and shape follow shared menu styling."
                    }
                    SettingsUI.SettingsButton {
                        actionKind: "navigation";
                        Layout.minimumWidth: 0
                        text: "Shared surface appearance ↗"
                        onClicked: Services.SettingsWindowState.page = "Appearance"
                    }
                }
                ColumnLayout {
                    visible: root.mode === "Appearance" && selection.instance === "selector"
                    Layout.fillWidth: true
                    Label {
                        text: "Selected colour"
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
                        title: ""
                        group: "surfaceBorders"
                        showSharedControls: false
                        targets: [
                            {
                                id: "hubSelector",
                                label: "Border"
                            }
                        ]
                    }
                    Label {
                        text: "Roundness"
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
                        actionKind: "reset";
                        Layout.minimumWidth: 0
                        text: "Follow Master roundness"
                        onClicked: Services.Settings.setRoundness("hubSelector", null)
                    }
                    SettingsUI.SettingsButton {
                        actionKind: "navigation";
                        Layout.minimumWidth: 0
                        text: "Shared selector borders ↗"
                        onClicked: Services.SettingsWindowState.page = "Appearance"
                    }
                }
                ColumnLayout {
                    visible: root.mode === "Appearance" && selection.instance === "toggles"
                    Layout.fillWidth: true
                    Label {
                        text: "Toggle colour"
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
                    SettingsUI.SwitchStylePicker {}
                    SettingsUI.SettingsHelp {
                        text: "Style: Settings, Wi-Fi and Bluetooth. Colour: Settings switches only."
                    }
                }
                SettingsUI.SettingsButton {
                    actionKind: "navigation"
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
                    actionKind: "reset";
                    Layout.minimumWidth: 0
                    text: "Reset Hub appearance"
                    onClicked: {
                        Services.Settings.resetSection("hub");
                        Services.Settings.setRoundness("hubSelector", null);
                        for (const key of ["hubSelectionRole", "hubToggleRole"])
                            Services.Settings.setValue("appearance", key, Schema.defaults().appearance[key]);
                    }
                }
            }
        }
    }
}
