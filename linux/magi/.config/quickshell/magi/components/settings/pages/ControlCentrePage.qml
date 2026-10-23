pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".." as SettingsUI
import "../../../services" as Services
import "../../../settings/SettingsSchema.js" as Schema

Item {
    id: root
    objectName: "settingsPage-Control Centre"
    property string mode: "Layout"
    onModeChanged: if (mode === "Behaviour")
        selection.select("media")
    property int outputWidth: 1920
    property bool expandedPreview: false
    property alias selection: selection
    property alias body: inspector.body
    property alias contentItem: inspector.contentItem
    property alias contentY: inspector.contentY
    property alias contentHeight: inspector.contentHeight
    readonly property int boundsBehavior: inspector.boundsBehavior
    readonly property var cc: Services.Settings.data.controlCentre
    function resetAppearance() {
        const defaults = Schema.defaults().appearance, visual = Schema.clone(Services.Settings.data.appearance.visual);
        for (const key of Object.keys(defaults.visual))
            if (key !== "statusIconSize")
                visual[key] = defaults.visual[key];
        Services.Settings.setValue("appearance", "visual", visual);
        for (const role of ["avatar", "albumArt", "controlTile", "secondaryControl", "slider"])
            Services.Settings.setRoundness(role, null);
    }
    function family(id) {
        if (["profile", "controls", "actions", "sliders", "media"].includes(id))
            return id;
        for (const group of ["controls", "actions", "sliders"])
            if (cc[group].some(e => e.module === id))
                return group;
        return "controls";
    }
    function reconcile() {
        if (!selection.instance)
            return;
        const id = selection.instance;
        const placed = cc.layout.includes(id) || ["controls", "actions", "sliders"].some(g => cc.layout.includes(g) && cc[g].some(e => e.enabled && e.module === id));
        if (!placed)
            selection.select("");
        else
            selection.select(id);
    }
    onCcChanged: reconcile()
    SettingsUI.EditorSelection {
        id: selection
        familyForInstance: id => root.family(id)
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        Label {
            objectName: "ccEditorTitle"
            text: "Control Centre"
            font.pixelSize: 24
            font.bold: true
        }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: ["Layout", "Colours & Look", "Behaviour"]
                SettingsUI.SettingsButton {
                    required property string modelData
                    text: modelData
                    primary: root.mode === modelData
                    onClicked: root.mode = modelData
                }
            }
            SettingsUI.SettingsButton {
                visible: root.mode === "Layout"
                text: preview.arrangeStructure ? "Arrange controls" : "Arrange components"
                onClicked: preview.arrangeStructure = !preview.arrangeStructure
            }
            SettingsUI.SettingsButton {
                objectName: "expandControlCentrePreview"
                visible: root.width < 1000
                text: root.expandedPreview ? "Show inspector" : "Expand preview"
                onClicked: root.expandedPreview = !root.expandedPreview
            }
        }
        SettingsUI.VisualEditorFrame {
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            Layout.preferredHeight: 0
            columns: root.mode === "Layout" || root.expandedPreview ? 1 : 2
            SettingsUI.ControlCentrePreview {
                id: preview
                objectName: "controlCentrePreview"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: root.mode === "Layout" || root.expandedPreview ? parent.width : Math.min(360, parent.width * .40)
                Layout.minimumHeight: root.mode === "Layout" || root.expandedPreview ? 180 : root.height < 650 ? 130 : 240
                Layout.preferredHeight: root.height
                editing: root.mode === "Layout"
                selectedKey: selection.instance
                onSelected: key => selection.select(key)
            }
            SettingsUI.SettingsPage {
                id: inspector
                objectName: "controlCentreEditor"
                visible: root.mode !== "Layout" && !root.expandedPreview
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: parent.width * .60
                Layout.minimumHeight: root.height < 650 ? 100 : 160
                title: root.mode === "Behaviour" ? "Behaviour" : "Inspector"
                description: root.mode === "Behaviour" ? "Select Media Player for playback visibility and preferred-player settings. Preview playback is synthetic." : "Select the surface, a section heading or an individual control."
                SettingsUI.SettingsButton {
                    text: "Select surface"
                    onClicked: selection.select("")
                }
                SettingsUI.SettingsButton {
                    visible: root.mode === "Behaviour"
                    text: "Media Player behaviour"
                    onClicked: selection.select("media")
                }
                SettingsUI.SettingsSelector {
                    visible: root.mode === "Behaviour"
                    model: ["Preview playing", "Preview paused"]
                    onActivated: preview.playing = currentIndex === 0
                }
                SettingsUI.SettingsHelp {
                    text: selection.instance ? "Selected: " + (Schema.controlDefinitions().find(d => d.id === selection.instance)?.label || preview.labels[selection.instance]) + ". Shared family settings affect every member; individual accent settings affect only this module." : "Selected: Control Centre surface. Shared expanded-surface tokens are labelled below."
                }
                SettingsUI.SettingsButton {
                    visible: root.mode !== "Behaviour" && selection.instance !== "" && !preview.ids.includes(selection.instance) && selection.family !== "sliders"
                    text: "Individual accent ↓"
                    onClicked: inspector.contentY = Math.max(0, contextual.identitySection.mapToItem(inspector.contentItem, 0, 0).y - 24)
                }
                SettingsUI.CCInspector {
                    id: contextual
                    behaviourOnly: root.mode === "Behaviour"
                    selection: root.selection
                }
                SettingsUI.SettingsButton {
                    visible: root.mode !== "Behaviour"
                    text: "Reset Control Centre appearance"
                    flat: true
                    onClicked: root.resetAppearance()
                }
                SettingsUI.SettingsButton {
                    text: "Reset composition"
                    flat: true
                    onClicked: Services.Settings.resetSection("controlCentre")
                }
            }
        }
        Flow {
            visible: root.mode === "Layout"
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: [
                    {
                        id: "controls",
                        label: "Primary Controls"
                    },
                    {
                        id: "actions",
                        label: "Secondary Controls"
                    },
                    {
                        id: "sliders",
                        label: "Sliders"
                    }
                ]
                SettingsUI.SettingsButton {
                    required property var modelData
                    enabled: !selection.instance || preview.ids.includes(selection.instance) || preview.moduleBoard.canPlace(selection.instance, modelData.id)
                    text: selection.instance && !preview.ids.includes(selection.instance) ? "Move to " + modelData.label : "Select " + modelData.label
                    onClicked: {
                        if (selection.instance && !preview.ids.includes(selection.instance))
                            Services.Settings.placeCCModule(selection.instance, modelData.id);
                        else {
                            selection.select(modelData.id);
                            root.mode = "Colours & Look";
                        }
                    }
                }
            }
            SettingsUI.SettingsButton {
                text: "Remove selected"
                enabled: selection.instance !== "" && !["controls", "actions"].includes(selection.instance)
                onClicked: preview.ids.includes(selection.instance) ? Services.Settings.placeCCSection(selection.instance, -1) : Services.Settings.placeCCModule(selection.instance, "available")
            }
        }
        SettingsUI.SettingsHelp {
            text: root.mode === "Layout" ? "Drag grips to arrange. Available items are unplaced. Alt+↑/↓ reorders; Alt+←/→ changes target; Escape cancels. Empty groups disappear in production." : "Family controls affect every member; individual accents follow modules. Changes autosave; Reload from Disk discards pending edits."
        }
    }
}
