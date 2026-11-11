pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".." as SettingsUI
import "../../../services" as Services
import "../../../settings/SettingsSchema.js" as Schema

SettingsUI.SettingsPage {
    id: root
    title: "Control Centre"
    maximumBodyWidth: 1400
    property int outputWidth: Services.SurfaceOrigin.hubTarget()?.width || 1920
    property int outputHeight: Services.SurfaceOrigin.hubTarget()?.height || 1080
    property alias selection: selection
    readonly property var cc: Services.Settings.data.controlCentre
    function resetComposition() {
        const defaults = Schema.defaults().controlCentre
        for (const key of ["columns", "actionColumns", "layout", "controls", "sliders", "actions"])
            Services.Settings.setValue("controlCentre", key, defaults[key])
    }
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
        if (!placed) selection.select("");
        else selection.select(id);
    }
    onCcChanged: reconcile()
    SettingsUI.EditorSelection {
        id: selection
        familyKeys: ["controls", "actions", "sliders"]
        familyForInstance: id => root.family(id)
    }
    Item {
        id: editor
        objectName: "ccUnifiedEditor"
        Layout.fillWidth: true
        readonly property bool sideBySide: width >= 680
        readonly property real previewWidth: sideBySide ? Math.min(400, width * .44) : width
        implicitHeight: sideBySide ? Math.max(previewColumn.height, inspector.height) : previewColumn.height + 18 + inspector.height
        ColumnLayout {
            id: previewColumn
            width: editor.previewWidth
            height: implicitHeight
            z: 1
            SettingsUI.ControlCentrePreview {
                id: preview
                objectName: "controlCentrePreview"
                outputWidth: root.outputWidth
                outputHeight: root.outputHeight
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                editing: true
                editorViewport: root
                availableCard: available
                selectedKey: selection.instance
                onSelected: key => selection.select(key)
            }
            SettingsUI.SettingsButton {
                actionKind: "reset"
                objectName: "ccResetComposition"
                text: "Reset composition"
                onClicked: root.resetComposition()
            }
        }
        ColumnLayout {
            id: inspector
            objectName: "controlCentreEditor"
            x: editor.sideBySide ? previewColumn.width + 18 : 0
            y: editor.sideBySide ? 0 : previewColumn.height + 18
            width: editor.sideBySide ? editor.width - x : editor.width
            height: implicitHeight
            spacing: SettingsUI.SettingsMetrics.gap
            SettingsUI.CCAvailableControls { id: available; preview: preview }
            SettingsUI.CCInspector { id: contextual; selection: root.selection }
            SettingsUI.CCGlobalSettings {
                SettingsUI.SettingsButton {
                    actionKind: "reset"
                    text: "Reset Control Centre appearance"
                    onClicked: root.resetAppearance()
                }
            }
            SettingsUI.SettingsSection {
                objectName: "ccRoundness"
                title: "Roundness"
                collapsible: false
                SettingsUI.SettingsSection {
                    objectName: "ccRoundness-controls"; collapsible: true
                    carded: false; title: "Controls"
                    description: "Shapes tiles, actions and shared control surfaces."
                    SettingsUI.RoundnessValue { fieldKey: "controlTile"; label: "Primary controls"; description: "Also shapes profile and media backgrounds." }
                    SettingsUI.RoundnessValue { fieldKey: "secondaryControl"; label: "Secondary controls" }
                    SettingsUI.RoundnessValue { fieldKey: "slider"; label: "Sliders"; description: "Control Centre tracks and shared value sliders." }
                }
                SettingsUI.SettingsSection {
                    objectName: "ccRoundness-artwork"; collapsible: true
                    carded: false; title: "Artwork & identity"
                    SettingsUI.RoundnessValue { fieldKey: "albumArt"; label: "Media artwork"; description: "Shapes media crops and artwork borders." }
                    SettingsUI.RoundnessValue { fieldKey: "avatar"; label: "Avatar / identity"; description: "Shapes profile and avatar masks, including the lock screen." }
                }
                SettingsUI.SettingsSection {
                    objectName: "ccRoundness-action"; collapsible: true
                    carded: false; title: "Shared buttons & switches · review"
                    description: "Affects controls across MAGI, including Settings, Hub and Bar menus."
                    SettingsUI.RoundnessValue { fieldKey: "action"; label: "Buttons and switches"; reference: 8 }
                }
            }
            SettingsUI.DecorationSettings { }
        }
    }
}
