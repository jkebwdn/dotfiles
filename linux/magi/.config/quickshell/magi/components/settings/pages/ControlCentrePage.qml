pragma ComponentBehavior: Bound
import QtQuick
import ".." as SettingsUI
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../modules" as Modules
SettingsUI.SettingsPage {
    id: root
    property real outputWidth: 1920
    readonly property int effectiveColumns: Math.max(1, Math.min(Services.Settings.data.controlCentre.columns, Math.floor((outputWidth - 56 + 18) / 78)))
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
    SettingsUI.SettingsButton { text: "Preview Control Centre"; onClicked: Services.MenuController.open("controlcentre") }
    SettingsUI.SettingsButton { flat: true; text: "Reset Control Centre"; onClicked: Services.Settings.resetSection("controlCentre") }

}
