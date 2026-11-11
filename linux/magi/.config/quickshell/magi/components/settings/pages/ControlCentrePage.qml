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
    readonly property string title: "Control Centre"
    property alias inspectorViewport: inspectorScroll
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
    function revealSelection() {
        if (!selection.instance || preview.moduleBoard.candidate || preview.moduleBoard.dragging
                || preview.structureBoard.candidate || preview.structureBoard.dragging) return
        const top = contextual.y
        if (top < inspectorScroll.contentY || top + Math.min(contextual.height, inspectorScroll.height) > inspectorScroll.contentY + inspectorScroll.height)
            inspectorScroll.contentY = Math.max(0, Math.min(top, inspectorScroll.contentHeight-inspectorScroll.height))
    }
    Label {
        id: heading
        objectName: "ccPageTitle"
        x: SettingsUI.SettingsMetrics.fieldPadding
        y: SettingsUI.SettingsMetrics.fieldPadding
        text: root.title
        font.pixelSize: SettingsUI.SettingsMetrics.titleSize
        font.bold: true
        Accessible.role: Accessible.Heading
    }
    Item {
        id: editor
        objectName: "ccUnifiedEditor"
        anchors { left: parent.left; right: parent.right; top: heading.bottom; bottom: parent.bottom; margins: SettingsUI.SettingsMetrics.fieldPadding }
        readonly property bool sideBySide: width >= 680
        readonly property real previewWidth: sideBySide ? Math.max(300, width - Math.min(440, width * .49) - SettingsUI.SettingsMetrics.gap) : width
        // Coordinate space shared by both drag boards. Only the inspector scrolls.
        Flickable {
            id: dragViewport
            anchors.fill: parent
            contentWidth: width; contentHeight: height
            interactive: false
        }
        ColumnLayout {
            id: previewColumn
            width: editor.previewWidth
            height: editor.sideBySide ? editor.height : Math.min(editor.height * .62, 340)
            z: 1
            spacing: SettingsUI.SettingsMetrics.compactGap
            SettingsUI.ControlCentrePreview {
                id: preview
                objectName: "controlCentrePreview"
                outputWidth: root.outputWidth
                outputHeight: root.outputHeight
                Layout.fillWidth: true
                Layout.fillHeight: true
                editing: true
                editorViewport: dragViewport
                inspectorViewport: inspectorScroll
                availableCard: available
                selectedKey: selection.instance
                onSelected: key => {
                    selection.select(key)
                    // Do not move the palette during a pointer grab. Reveal on click/release.
                    Qt.callLater(root.revealSelection)
                }
                onEditingFinished: root.revealSelection()
            }
            SettingsUI.SettingsButton {
                actionKind: "reset"
                objectName: "ccResetComposition"
                text: "Reset composition"
                onClicked: root.resetComposition()
            }
        }
        Flickable {
            id: inspectorScroll
            objectName: "ccInspectorScroll"
            x: editor.sideBySide ? previewColumn.width + SettingsUI.SettingsMetrics.gap : 0
            y: editor.sideBySide ? 0 : previewColumn.height + SettingsUI.SettingsMetrics.gap
            width: editor.width - x
            height: editor.height - y
            contentWidth: width
            contentHeight: inspector.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            function clampPosition() { contentY = Math.max(0, Math.min(contentY, Math.max(0, contentHeight-height))) }
            onContentHeightChanged: clampPosition()
            onHeightChanged: clampPosition()
            SettingsUI.ScrollInput { view: inspectorScroll }
            ScrollBar.vertical: ScrollBar {}
            ColumnLayout {
                id: inspector
                objectName: "controlCentreEditor"
                width: inspectorScroll.width - SettingsUI.SettingsMetrics.compactGap
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
                SettingsUI.SettingsSubheading {
                    objectName: "ccRoundness-controls"; collapsible: true
                    title: "Controls"
                    description: "Shapes Control Centre tiles, actions and slider tracks."
                    SettingsUI.RoundnessValue { fieldKey: "controlTile"; label: "Primary controls"; description: "Also shapes profile and media backgrounds." }
                    SettingsUI.RoundnessValue { fieldKey: "secondaryControl"; label: "Secondary controls" }
                    SettingsUI.RoundnessValue { fieldKey: "slider"; label: "Sliders"; description: "Control Centre slider tracks." }
                }
                SettingsUI.SettingsSubheading {
                    objectName: "ccRoundness-artwork"; collapsible: true
                    title: "Artwork & identity"
                    SettingsUI.RoundnessValue { fieldKey: "albumArt"; label: "Media artwork"; description: "Shapes media crops and artwork borders." }
                    SettingsUI.RoundnessValue { fieldKey: "avatar"; label: "Avatar / identity"; description: "Shapes profile and avatar masks, including the lock screen." }
                }

            }
            SettingsUI.DecorationSettings { }
        }
    }
    }
}
