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
    property int outputWidth: 1920
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
        if (!selection.instance || selection.familyKeys.includes(selection.instance))
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
        familyKeys: ["controls", "actions", "sliders"]
        familyForInstance: id => root.family(id)
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: SettingsUI.SettingsMetrics.pagePadding
        spacing: 12
        Label {
            objectName: "ccEditorTitle"
            text: "Control Centre"
            font.pixelSize: SettingsUI.SettingsMetrics.titleSize
            font.bold: true
        }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: ["Layout", "Appearance"]
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
            columns: root.mode === "Layout" ? 1 : 2
            SettingsUI.ControlCentrePreview {
                id: preview
                objectName: "controlCentrePreview"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: root.mode === "Layout" ? parent.width : Math.min(360, parent.width * .40)
                Layout.minimumHeight: root.mode === "Layout" ? 180 : root.height < 650 ? 130 : 240
                Layout.preferredHeight: root.height
                editing: root.mode === "Layout"
                selectedKey: selection.instance
                onSelected: key => selection.select(key)
            }
            SettingsUI.SettingsPage {
                id: inspector
                contentPadding: 0
                objectName: "controlCentreEditor"
                visible: root.mode !== "Layout"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: parent.width * .60
                Layout.minimumHeight: root.height < 650 ? 100 : 160
                title: ""
                description: ""
                SettingsUI.CCInspector {
                    id: contextual
                    behaviourOnly: false
                    selection: root.selection
                }
                SettingsUI.SettingsButton {
                    actionKind: "reset";
                    visible: !contextual.individual || contextual.familySection.expanded
                    text: "Reset Control Centre appearance"
                    onClicked: root.resetAppearance()
                }
                SettingsUI.SettingsButton {
                    actionKind: "reset";
                    visible: !contextual.individual || contextual.familySection.expanded
                    text: "Reset composition"
                    onClicked: Services.Settings.resetSection("controlCentre")
                }
            }
        }
        SettingsUI.SettingsButton {
            actionKind: "reset";
            visible: root.mode === "Layout"
            text: "Reset composition"
            onClicked: Services.Settings.resetSection("controlCentre")
        }
    }
}
