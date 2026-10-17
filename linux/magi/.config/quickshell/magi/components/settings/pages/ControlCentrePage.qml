pragma ComponentBehavior: Bound
import QtQuick
import ".." as SettingsUI
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../modules" as Modules
import "../../../settings/SettingsSchema.js" as Schema
SettingsUI.SettingsPage {
    id: root
    property real outputWidth: 1920
    readonly property int effectiveColumns: Math.max(1, Math.min(Services.Settings.data.controlCentre.columns, Math.floor((outputWidth - 56 + 12) / (Theme.RenderTokens.tileSize + 12))))
    title: "Control Centre"
    description: "Arrange the controls and actions shown in your Control Centre."
    function arrangedEntries(group) {
        return Services.Settings.data.controlCentre[group].filter(e => e.enabled).map((entry, index) => ({
            key: entry.key, label: Modules.ControlCatalog.definitions.find(d => d.id === entry.module)?.label || entry.module,
            lane: group, position: index, data: entry
        }))
    }
    function available(group, presentation) {
        return Modules.ControlCatalog.forPresentation(presentation).filter(d =>
            !Services.Settings.data.controlCentre[group].some(e => e.module === d.id && e.enabled))
    }
    function addConfigured(group, module) {
        const existing = Services.Settings.data.controlCentre[group].find(e => e.module === module)
        if (existing) Services.Settings.editEntry(group, existing.key, "enabled", true)
        else Services.Settings.addEntry(group, module)
    }
    function reorder(group, key, position) {
        const entries = Services.Settings.data.controlCentre[group]
        const visible = entries.filter(e => e.enabled)
        if (!visible[position]) return
        const from = entries.findIndex(e => e.key === key)
        const to = entries.findIndex(e => e.key === visible[position].key)
        if (from < 0 || from === to) return
        if (group === "controls") Services.Settings.moveControl(key, to - from)
        else Services.Settings.moveEntry(group, key, to - from)
    }
    SettingsUI.SettingsButton {
        objectName: "controlCentrePreview"
        text: Services.SettingsWindowState.controlCentrePreview ? "Close preview" : "Preview Control Centre"
        onClicked: Services.SettingsWindowState.toggleControlCentrePreview()
    }
    SettingsUI.SettingsSection {
        title: "Appearance"
        collapsible: true
        SettingsUI.VisualSettingsGroup {
            title: "Primary tiles"; collapsible: false
            description: "Tile shades use the configured accent. Icon references select semantic roles; off shade adjusts that role and off strength controls opacity."
            numbers: [
                {key:"primaryIconSize",label:"Primary icon size",min:16,max:48,step:1},
                {key:"primaryContainerSize",label:"Primary icon container size",min:60,max:96,step:1},
                {key:"tileBackgroundShade",label:"Tile background shade",min:-1,max:1,step:.02,shade:true},
                {key:"tileBorderShade",label:"Tile border shade",min:-1,max:1,step:.02,shade:true},
                {key:"tileBorderWidth",label:"Tile border width",min:0,max:6,step:.5},
                {key:"controlOffShade",label:"Off shade",min:-1,max:1,step:.02,shade:true},
                {key:"controlOffOpacity",label:"Off colour strength",min:0,max:1,step:.05}]
            colors: [{key:"controlOn",label:"On tone reference"},{key:"controlOff",label:"Off tone reference"}]
        }
        SettingsUI.VisualSettingsGroup {
            title: "Secondary actions"; collapsible: false
            numbers: [{key:"secondaryIconSize",label:"Secondary action icon size",min:16,max:36,step:1},
                {key:"secondaryOffShade",label:"Off shade",min:-1,max:1,step:.02,shade:true},
                {key:"secondaryOffOpacity",label:"Off strength",min:0,max:1,step:.05}]
            colors: [{key:"secondaryOn",label:"On role"},{key:"secondaryOff",label:"Off role"}]
        }
        SettingsUI.VisualSettingsGroup {
            title: "Sliders"; collapsible: false
            numbers: [{key:"sliderBorderWidth",label:"Border width",min:0,max:5,step:.5}]
            colors: [{key:"sliderTrack",label:"Empty track"},{key:"sliderFill",label:"Fill"},{key:"sliderBorder",label:"Border"}]
        }
        SettingsUI.VisualSettingsGroup {
            title: "Profile and media"; collapsible: false
            numbers: [{key:"avatarSize",label:"Profile avatar size",min:48,max:112,step:1},
                {key:"avatarBorderWidth",label:"Avatar border",min:0,max:5,step:.5},
                {key:"mediaArtworkSize",label:"Album artwork size",min:48,max:112,step:1}]
        }
        SettingsUI.VisualSettingsGroup {
            title: "Profile typography"; collapsible: false
            numbers: [{key:"profileGreetingSize",label:"Greeting font size",min:12,max:24,step:1},
                {key:"profileWeatherSize",label:"Weather/status font size",min:10,max:20,step:1},
                {key:"profileThirdLineSize",label:"Optional third-line font size",min:10,max:20,step:1}]
        }
        SettingsUI.VisualSettingsGroup {
            title: "Section spacing"; collapsible: false
            description: "When sections are hidden, the preceding visible section supplies one gap."
            numbers: [{key:"profileControlsGap",label:"Profile → Primary",min:0,max:48,step:1},
                {key:"controlsSlidersGap",label:"Primary → Sliders",min:0,max:48,step:1},
                {key:"slidersActionsGap",label:"Sliders → Secondary",min:0,max:48,step:1},
                {key:"actionsMediaGap",label:"Secondary → Media",min:0,max:48,step:1}]
        }
        Repeater {
            model: [{id:"avatar",label:"Avatar corner roundness"},{id:"albumArt",label:"Album artwork corner roundness"}]
            RowLayout {
                id: artRadius
                required property var modelData
                readonly property var setting: Services.Settings.data.appearance.roundness.roles[modelData.id]
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: artRadius.modelData.label; Layout.fillWidth: true; wrapMode: Text.Wrap }
                    SettingsUI.SettingsSlider {
                        objectName: "artRoundness-" + artRadius.modelData.id
                        Accessible.name: artRadius.modelData.label
                        Layout.fillWidth: true
                        from: 0; to: 2; stepSize: .05
                        value: artRadius.setting === null ? Services.Settings.data.appearance.roundness.master : artRadius.setting
                        onMoved: Services.Settings.setRoundness(artRadius.modelData.id, value)
                    }
                }
                Label { text: artRadius.setting === null ? "Master" : Number(artRadius.setting).toFixed(2) }
                SettingsUI.SettingsButton { text: "Default"; onClicked: Services.Settings.setRoundness(artRadius.modelData.id, null) }
            }
        }
        SettingsUI.SettingsHelp { text: "Corners: square (0), rounded square (1), rounder (2). Default follows Master." }
        SettingsUI.SettingsButton {
            flat: true; text: "Reset Control Centre appearance"
            onClicked: {
                const defaults = Schema.defaults().appearance
                // Reset only the visual settings owned by this page.
                const visual = Schema.clone(Services.Settings.data.appearance.visual)
                for (const key of Object.keys(defaults.visual))
                    if (key !== "statusIconSize") visual[key] = defaults.visual[key]
                Services.Settings.setValue("appearance", "visual", visual)
                Services.Settings.setRoundness("avatar", null)
                Services.Settings.setRoundness("albumArt", null)
            }
        }
    }
    SettingsUI.SettingsSection {
        title: "Layout"
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Label { text: "Primary columns"; Layout.fillWidth: true }
                Label { text: "Fits " + root.effectiveColumns + " on this output"; color: Theme.Theme.text; font.pixelSize: 12; Layout.fillWidth: true }
            }
            SettingsUI.SettingsNumber { objectName: "primaryColumns"; Accessible.name: "Primary columns"; from: 1; to: 16; value: Services.Settings.data.controlCentre.columns; onValueModified: Services.Settings.setValue("controlCentre","columns",value) }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { text: "Secondary columns"; Layout.fillWidth: true }
            SettingsUI.SettingsNumber { objectName: "secondaryColumns"; Accessible.name: "Secondary columns"; from: 1; to: 16; value: Services.Settings.data.controlCentre.actionColumns
                onValueModified: Services.Settings.setValue("controlCentre","actionColumns",value) }
        }
    }
    SettingsUI.SettingsSection {
        title: "Visible sections"
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 24
            rowSpacing: 6
            Repeater {
                model: [
                    {id:"profile", label:"Profile header"},
                    {id:"quickControls", label:"Quick controls"},
                    {id:"sliders", label:"Volume / brightness"},
                    {id:"actions", label:"Secondary actions"},
                    {id:"media", label:"Media"}
                ]
                SettingsUI.SettingsToggle {
                    required property var modelData
                    text: modelData.label
                    checked: Services.Settings.data.controlCentre.sections[modelData.id]
                    onToggled: Services.Settings.setControlSection(modelData.id, checked)
                }
            }
        }
    }
    SettingsUI.SettingsSection {
        title: "Primary controls"
        description: Services.Settings.data.controlCentre.controls.filter(e => e.enabled).length + " configured · remove to return to Available"
        SettingsUI.SettingsReorderBoard {
            objectName: "primaryOrder"
            viewport: root
            entries: root.arrangedEntries("controls")
            lanes: [{id:"controls", label:""}]
            rowHeight: 50
            onMoveRequested: (key, lane, position) => root.reorder("controls", key, position)
            rowContent: Component {
                RowLayout {
                    id: row
                    readonly property var modelData: parent.entry ? parent.entry.data : ({})
                    spacing: 6
                    SettingsUI.SettingsSelector {
                        objectName: "controlIdentity-" + row.modelData.key
                        Accessible.name: "Control"
                        Layout.fillWidth: true; Layout.maximumWidth: Infinity
                        Layout.minimumWidth: 100
                        font.bold: true
                        model: Modules.ControlCatalog.forPresentation("tile").filter(d => d.id === row.modelData.module || !Services.Settings.data.controlCentre.controls.some(e => e.module === d.id))
                        textRole: "label"
                        currentIndex: model.findIndex(d => d.id === row.modelData.module)
                        onActivated: index => Services.Settings.setControlModule(row.modelData.key,model[index].id)
                    }
                    Rectangle { width: 10; height: 10; radius: 5; color: Theme.Theme.roles[row.modelData.accent] || Theme.Theme.accent }
                    SettingsUI.SettingsSelector {
                        objectName: "controlAccent-" + row.modelData.key
                        Accessible.name: "Accent colour"
                        Layout.preferredWidth: 130; Layout.minimumWidth: 100; flat: true
                        model: Theme.ThemeRegistry.accentRoles
                        currentIndex: Math.max(0, model.indexOf(row.modelData.accent))
                        displayText: currentText.charAt(0).toUpperCase() + currentText.slice(1)
                        onActivated: index => Services.Settings.editControl(row.modelData.key,"accent",model[index])
                    }
                    SettingsUI.SettingsButton {
                        objectName: "removeControl-" + row.modelData.key
                        flat: true; implicitWidth: 28; leftPadding: 6; rightPadding: 6
                        text: "−"; Accessible.name: "Remove control"
                        onClicked: Services.Settings.editControl(row.modelData.key, "enabled", false)
                    }
                }
            }
        }
        RowLayout {
            Label { text: "Available"; color: Theme.Theme.text; font.pixelSize: 12 }
            SettingsUI.SettingsSelector {
                id: addChoice
                objectName: "availableControls"; Accessible.name: "Available controls"
                Layout.fillWidth: true
                model: root.available("controls", "tile")
                textRole: "label"
            }
            SettingsUI.SettingsButton { text: "Add control"; enabled: addChoice.currentIndex >= 0; onClicked: root.addConfigured("controls", addChoice.model[addChoice.currentIndex].id) }
        }
    }
    SettingsUI.SettingsSection {
        title: "Sliders"
        Repeater {
            model: Services.Settings.data.controlCentre.sliders
            SettingsUI.SettingsToggle {
                required property var modelData
                text: modelData.module
                checked: modelData.enabled
                onToggled: {
                    const entries = JSON.parse(JSON.stringify(Services.Settings.data.controlCentre.sliders))
                    entries.find(e => e.key === modelData.key).enabled = checked
                    Services.Settings.setValue("controlCentre","sliders",entries)
                }
            }
        }
    }
    SettingsUI.SettingsSection {
        title: "Secondary actions"
        description: Services.Settings.data.controlCentre.actions.filter(e => e.enabled).length + " configured · remove to return to Available"
        SettingsUI.SettingsReorderBoard {
            objectName: "secondaryOrder"
            viewport: root
            entries: root.arrangedEntries("actions")
            lanes: [{id:"actions", label:""}]
            rowHeight: 50
            onMoveRequested: (key, lane, position) => root.reorder("actions", key, position)
            rowContent: Component {
                RowLayout {
                    id: actionRow
                    readonly property var modelData: parent.entry ? parent.entry.data : ({})
                    SettingsUI.SettingsSelector {
                        objectName: "actionIdentity-" + actionRow.modelData.key
                        Layout.fillWidth: true; Layout.maximumWidth: Infinity
                        model: Modules.ControlCatalog.forPresentation("action").filter(d => d.id === actionRow.modelData.module
                            || !Services.Settings.data.controlCentre.actions.some(e => e.module === d.id))
                        textRole: "label"
                        currentIndex: model.findIndex(d => d.id === actionRow.modelData.module)
                        onActivated: index => Services.Settings.editEntry("actions",actionRow.modelData.key,"module",model[index].id)
                    }
                    SettingsUI.SettingsButton {
                        objectName: "removeAction-" + actionRow.modelData.key
                        flat: true; implicitWidth: 28; leftPadding: 6; rightPadding: 6
                        text: "−"; Accessible.name: "Remove action"
                        onClicked: Services.Settings.editEntry("actions",actionRow.modelData.key,"enabled",false)
                    }
                }
            }
        }
        RowLayout {
            Label { text: "Available"; color: Theme.Theme.text; font.pixelSize: 12 }
            SettingsUI.SettingsSelector {
                id: addAction
                objectName: "availableActions"; Accessible.name: "Available actions"
                Layout.fillWidth: true
                model: root.available("actions", "action")
                textRole: "label"
            }
            SettingsUI.SettingsButton { text: "Add action"; enabled: addAction.currentIndex >= 0
                onClicked: root.addConfigured("actions",addAction.model[addAction.currentIndex].id) }
        }
    }

    SettingsUI.SettingsButton { flat: true; text: "Reset Control Centre"; onClicked: Services.Settings.resetSection("controlCentre") }

}
