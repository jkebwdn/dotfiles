pragma ComponentBehavior: Bound
import QtQuick
import ".." as SettingsUI
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../modules" as Modules
import "../../../settings/SettingsSchema.js" as Schema

Item {
    id: root
    objectName: "settingsPage-Control Centre"
    property alias contentItem: editor.contentItem
    readonly property int boundsBehavior: editor.boundsBehavior
    property alias contentY: editor.contentY
    property alias contentHeight: editor.contentHeight
    property alias body: editor.body
    property bool expandedPreview: false
    property real outputWidth: 1920
    readonly property int effectiveColumns: Math.max(1, Math.min(Services.Settings.data.controlCentre.columns, Math.floor((outputWidth - 56 + 12) / (Theme.RenderTokens.tileSize + 12))))
    function arrangedEntries(group) {
        return Services.Settings.data.controlCentre[group].filter(e => e.enabled).map((entry, index) => ({
                    key: entry.key,
                    label: Modules.ControlCatalog.definitions.find(d => d.id === entry.module)?.label || entry.module,
                    lane: group,
                    position: index,
                    data: entry
                }));
    }
    function available(group, presentation) {
        return Modules.ControlCatalog.forPresentation(presentation).filter(d => !Services.Settings.data.controlCentre[group].some(e => e.module === d.id && e.enabled));
    }
    function addConfigured(group, module) {
        const existing = Services.Settings.data.controlCentre[group].find(e => e.module === module);
        if (existing)
            Services.Settings.editEntry(group, existing.key, "enabled", true);
        else
            Services.Settings.addEntry(group, module);
    }
    function reorder(group, key, position) {
        const entries = Services.Settings.data.controlCentre[group];
        const visible = entries.filter(e => e.enabled);
        if (!visible[position])
            return;
        const from = entries.findIndex(e => e.key === key);
        const to = entries.findIndex(e => e.key === visible[position].key);
        if (from < 0 || from === to)
            return;
        if (group === "controls")
            Services.Settings.moveControl(key, to - from);
        else
            Services.Settings.moveEntry(group, key, to - from);
    }
    GridLayout {
        anchors.fill: parent
        anchors.margins: 12
        columnSpacing: 16
        rowSpacing: 8
        columns: root.width >= 800 ? 2 : 1
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 360
            Layout.fillHeight: root.width < 800
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: root.width >= 800 ? preview.implicitHeight + 40 : root.expandedPreview ? root.height : root.height * .42
            Layout.maximumHeight: root.width >= 800 || root.expandedPreview ? root.height - 24 : root.height * .42
            SettingsUI.ControlCentrePreview {
                id: preview
                objectName: "controlCentrePreview"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onMoveRequested: (group, key, position) => root.reorder(group, key, position)
            }
            RowLayout {
                Label {
                    text: "Playback"
                }
                SettingsUI.SettingsSelector {
                    objectName: "previewPlayback"
                    model: ["Playing", "Paused"]
                    Layout.maximumWidth: 150
                    onActivated: preview.playing = currentIndex === 0
                }
                SettingsUI.SettingsButton {
                    objectName: "expandControlCentrePreview"
                    visible: root.width < 800
                    text: root.expandedPreview ? "Show settings" : "Expand preview"
                    onClicked: root.expandedPreview = !root.expandedPreview
                }
            }
        }
        SettingsUI.SettingsPage {
            id: editor
            objectName: "controlCentreEditor"
            visible: root.width >= 800 || !root.expandedPreview
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 480
            Layout.minimumHeight: 120
            Layout.preferredHeight: root.height * .58
            title: "Control Centre"
            description: "Changes preview live and save automatically. Drag handles reorder within each section; Alt+Up/Down also works."
            SettingsUI.SettingsSection {
                title: "Profile Header"
                objectName: "profileHeaderSettings"
                collapsible: true
                expanded: true
                SettingsUI.VisualSettingsGroup {
                    title: "Avatar and typography"
                    collapsible: false
                    numbers: [
                        {
                            key: "avatarSize",
                            label: "Avatar size",
                            min: 48,
                            max: 112,
                            step: 1
                        },
                        {
                            key: "avatarBorderWidth",
                            label: "Avatar border width",
                            min: 0,
                            max: 5,
                            step: .5
                        },
                        {
                            key: "profileGreetingSize",
                            label: "Greeting size",
                            min: 12,
                            max: 24,
                            step: 1
                        },
                        {
                            key: "profileWeatherSize",
                            label: "Weather size",
                            min: 10,
                            max: 20,
                            step: 1
                        },
                        {
                            key: "profileThirdLineSize",
                            label: "Detail size",
                            min: 10,
                            max: 20,
                            step: 1
                        }
                    ]
                    weights: [
                        {
                            key: "profileGreetingWeight",
                            label: "Greeting weight"
                        },
                        {
                            key: "profileWeatherWeight",
                            label: "Weather weight"
                        },
                        {
                            key: "profileThirdLineWeight",
                            label: "Detail weight"
                        }
                    ]
                }
                SettingsUI.SettingsToggle {
                    text: "Profile background"
                    checked: Services.Settings.data.appearance.profileBackground.enabled
                    onClicked: Services.Settings.setValue("appearance", "profileBackground", Object.assign({}, Services.Settings.data.appearance.profileBackground, {
                        enabled: checked
                    }))
                }
                SettingsUI.SettingsRow {
                    Label {
                        text: "Profile background colour"
                        Layout.fillWidth: true
                    }
                    SettingsUI.SemanticPaletteSelector {
                        model: ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "border", "accent"].concat(Theme.ThemeRegistry.accentRoles)
                        role: Services.Settings.data.appearance.profileBackground.role
                        onRoleSelected: value => Services.Settings.setValue("appearance", "profileBackground", Object.assign({}, Services.Settings.data.appearance.profileBackground, {
                                role: value
                            }))
                    }
                }
                SettingsUI.SettingsRow {
                    Label {
                        text: "Greeting style"
                        Layout.fillWidth: true
                    }
                    SettingsUI.SettingsSelector {
                        model: ["Compact", "Friendly"]
                        currentIndex: Services.Settings.data.profile.greetingStyle === "friendly" ? 1 : 0
                        onActivated: Services.Settings.setValue("profile", "greetingStyle", currentIndex ? "friendly" : "compact")
                    }
                }
                SettingsUI.SettingsHelp {
                    text: "Choose your image and edit your name in Profile."
                }
                SettingsUI.SettingsRow {
                    Label {
                        text: "Avatar corner roundness"
                        Layout.fillWidth: true
                    }
                    SettingsUI.SettingsSlider {
                        objectName: "artRoundness-avatar"
                        Layout.fillWidth: true
                        from: 0
                        to: 2
                        stepSize: .05
                        value: Services.Settings.data.appearance.roundness.roles.avatar ?? Services.Settings.data.appearance.roundness.master
                        onMoved: Services.Settings.setRoundness("avatar", value)
                    }
                    SettingsUI.SettingsButton {
                        text: "Default"
                        onClicked: Services.Settings.setRoundness("avatar", null)
                    }
                }
            }
            SettingsUI.SettingsSection {
                title: "Controls"
                objectName: "controlsSettings"
                collapsible: true
                expanded: true
                SettingsUI.SettingsSection {
                    title: "Layout"
                    collapsible: true
                    expanded: true
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: "Primary columns"
                                Layout.fillWidth: true
                            }
                            Label {
                                text: "Fits " + root.effectiveColumns + " on this output"
                                color: Theme.Theme.text
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                        }
                        SettingsUI.SettingsNumber {
                            objectName: "primaryColumns"
                            Accessible.name: "Primary columns"
                            from: 1
                            to: 16
                            value: Services.Settings.data.controlCentre.columns
                            onValueModified: Services.Settings.setValue("controlCentre", "columns", value)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Secondary columns"
                            Layout.fillWidth: true
                        }
                        SettingsUI.SettingsNumber {
                            objectName: "secondaryColumns"
                            Accessible.name: "Secondary columns"
                            from: 1
                            to: 16
                            value: Services.Settings.data.controlCentre.actionColumns
                            onValueModified: Services.Settings.setValue("controlCentre", "actionColumns", value)
                        }
                    }
                }
                SettingsUI.SettingsSection {
                    title: "Visible sections"
                    collapsible: true
                    expanded: true
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 24
                        rowSpacing: 6
                        Repeater {
                            model: [
                                {
                                    id: "profile",
                                    label: "Profile header"
                                },
                                {
                                    id: "quickControls",
                                    label: "Quick controls"
                                },
                                {
                                    id: "sliders",
                                    label: "Volume / brightness"
                                },
                                {
                                    id: "actions",
                                    label: "Secondary actions"
                                },
                                {
                                    id: "media",
                                    label: "Media"
                                }
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
                SettingsUI.VisualSettingsGroup {
                    title: "Primary tiles"
                    collapsible: false
                    description: "Tile shades use the configured accent. Icon references select semantic roles; off shade adjusts that role and off strength controls opacity."
                    numbers: [
                        {
                            key: "primaryIconSize",
                            label: "Primary icon size",
                            min: 16,
                            max: 48,
                            step: 1
                        },
                        {
                            key: "primaryContainerSize",
                            label: "Primary icon container size",
                            min: 60,
                            max: 96,
                            step: 1
                        },
                        {
                            key: "tileBackgroundShade",
                            label: "Tile background shade",
                            min: -1,
                            max: 1,
                            step: .02,
                            shade: true
                        },
                        {
                            key: "tileBorderShade",
                            label: "Tile border shade",
                            min: -1,
                            max: 1,
                            step: .02,
                            shade: true
                        },
                        {
                            key: "tileBorderWidth",
                            label: "Tile border width",
                            min: 0,
                            max: 6,
                            step: .5
                        },
                        {
                            key: "controlOffShade",
                            label: "Off shade",
                            min: -1,
                            max: 1,
                            step: .02,
                            shade: true
                        },
                        {
                            key: "controlOffOpacity",
                            label: "Off colour strength",
                            min: 0,
                            max: 1,
                            step: .05
                        }
                    ]
                    colors: [
                        {
                            key: "controlOn",
                            label: "On tone reference"
                        },
                        {
                            key: "controlOff",
                            label: "Off tone reference"
                        }
                    ]
                }
                SettingsUI.VisualSettingsGroup {
                    title: "Secondary actions"
                    collapsible: false
                    numbers: [
                        {
                            key: "secondaryIconSize",
                            label: "Secondary action icon size",
                            min: 16,
                            max: 36,
                            step: 1
                        },
                        {
                            key: "secondaryOffShade",
                            label: "Off shade",
                            min: -1,
                            max: 1,
                            step: .02,
                            shade: true
                        },
                        {
                            key: "secondaryOffOpacity",
                            label: "Off strength",
                            min: 0,
                            max: 1,
                            step: .05
                        }
                    ]
                    colors: [
                        {
                            key: "secondaryOn",
                            label: "On role"
                        },
                        {
                            key: "secondaryOff",
                            label: "Off role"
                        }
                    ]
                }
                SettingsUI.VisualSettingsGroup {
                    title: "Sliders"
                    collapsible: false
                    numbers: [
                        {
                            key: "sliderBorderWidth",
                            label: "Border width",
                            min: 0,
                            max: 5,
                            step: .5
                        }
                    ]
                    colors: [
                        {
                            key: "sliderTrack",
                            label: "Track"
                        },
                        {
                            key: "sliderFill",
                            label: "Progress"
                        },
                        {
                            key: "sliderBorder",
                            label: "Outline"
                        }
                    ]
                }
                SettingsUI.VisualSettingsGroup {
                    title: "Section spacing"
                    collapsible: false
                    description: "When sections are hidden, the preceding visible section supplies one gap."
                    numbers: [
                        {
                            key: "profileControlsGap",
                            label: "Profile → Primary",
                            min: 0,
                            max: 48,
                            step: 1
                        },
                        {
                            key: "controlsSlidersGap",
                            label: "Primary → Sliders",
                            min: 0,
                            max: 48,
                            step: 1
                        },
                        {
                            key: "slidersActionsGap",
                            label: "Sliders → Secondary",
                            min: 0,
                            max: 48,
                            step: 1
                        },
                        {
                            key: "actionsMediaGap",
                            label: "Secondary → Media",
                            min: 0,
                            max: 48,
                            step: 1
                        }
                    ]
                }
                SettingsUI.SettingsSection {
                    title: "Primary controls"
                    collapsible: true
                    expanded: true
                    description: Services.Settings.data.controlCentre.controls.filter(e => e.enabled).length + " configured · remove to return to Available"
                    SettingsUI.SettingsReorderBoard {
                        objectName: "primaryOrder"
                        viewport: editor
                        entries: root.arrangedEntries("controls")
                        lanes: [
                            {
                                id: "controls",
                                label: ""
                            }
                        ]
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
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: Infinity
                                    Layout.minimumWidth: 100
                                    font.bold: true
                                    model: Modules.ControlCatalog.forPresentation("tile").filter(d => d.id === row.modelData.module || !Services.Settings.data.controlCentre.controls.some(e => e.module === d.id))
                                    textRole: "label"
                                    currentIndex: model.findIndex(d => d.id === row.modelData.module)
                                    onActivated: index => Services.Settings.setControlModule(row.modelData.key, model[index].id)
                                }
                                SettingsUI.SettingsSelector {
                                    objectName: "controlAccent-" + row.modelData.key
                                    Accessible.name: "Accent colour"
                                    Layout.preferredWidth: 130
                                    Layout.minimumWidth: 100
                                    flat: true
                                    model: Theme.ThemeRegistry.accentRoles
                                    currentIndex: Math.max(0, model.indexOf(row.modelData.accent))
                                    displayText: currentText.charAt(0).toUpperCase() + currentText.slice(1)
                                    onActivated: index => Services.Settings.editControl(row.modelData.key, "accent", model[index])
                                }
                                SettingsUI.SettingsButton {
                                    objectName: "removeControl-" + row.modelData.key
                                    flat: true
                                    implicitWidth: 28
                                    leftPadding: 6
                                    rightPadding: 6
                                    text: "−"
                                    Accessible.name: "Remove control"
                                    onClicked: Services.Settings.editControl(row.modelData.key, "enabled", false)
                                }
                            }
                        }
                    }
                    RowLayout {
                        Label {
                            text: "Available"
                            color: Theme.Theme.text
                            font.pixelSize: 12
                        }
                        SettingsUI.SettingsSelector {
                            id: addChoice
                            objectName: "availableControls"
                            Accessible.name: "Available controls"
                            Layout.fillWidth: true
                            model: root.available("controls", "tile")
                            textRole: "label"
                        }
                        SettingsUI.SettingsButton {
                            text: "Add control"
                            enabled: addChoice.currentIndex >= 0
                            onClicked: root.addConfigured("controls", addChoice.model[addChoice.currentIndex].id)
                        }
                    }
                }
                SettingsUI.SettingsSection {
                    title: "Sliders"
                    collapsible: true
                    expanded: true
                    Repeater {
                        model: Services.Settings.data.controlCentre.sliders
                        SettingsUI.SettingsToggle {
                            required property var modelData
                            text: modelData.module
                            checked: modelData.enabled
                            onToggled: {
                                const entries = JSON.parse(JSON.stringify(Services.Settings.data.controlCentre.sliders));
                                entries.find(e => e.key === modelData.key).enabled = checked;
                                Services.Settings.setValue("controlCentre", "sliders", entries);
                            }
                        }
                    }
                    SettingsUI.SettingsReorderBoard {
                        objectName: "sliderOrder"
                        viewport: editor
                        entries: root.arrangedEntries("sliders")
                        lanes: [
                            {
                                id: "sliders",
                                label: ""
                            }
                        ]
                        rowHeight: 42
                        onMoveRequested: (key, lane, position) => root.reorder("sliders", key, position)
                        rowContent: Component {
                            Label {
                                text: parent.entry ? parent.entry.label : ""
                            }
                        }
                    }
                }
                SettingsUI.SettingsSection {
                    title: "Secondary actions"
                    collapsible: true
                    expanded: true
                    description: Services.Settings.data.controlCentre.actions.filter(e => e.enabled).length + " configured · remove to return to Available"
                    SettingsUI.SettingsReorderBoard {
                        objectName: "secondaryOrder"
                        viewport: editor
                        entries: root.arrangedEntries("actions")
                        lanes: [
                            {
                                id: "actions",
                                label: ""
                            }
                        ]
                        rowHeight: 50
                        onMoveRequested: (key, lane, position) => root.reorder("actions", key, position)
                        rowContent: Component {
                            RowLayout {
                                id: actionRow
                                readonly property var modelData: parent.entry ? parent.entry.data : ({})
                                SettingsUI.SettingsSelector {
                                    objectName: "actionIdentity-" + actionRow.modelData.key
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: Infinity
                                    model: Modules.ControlCatalog.forPresentation("action").filter(d => d.id === actionRow.modelData.module || !Services.Settings.data.controlCentre.actions.some(e => e.module === d.id))
                                    textRole: "label"
                                    currentIndex: model.findIndex(d => d.id === actionRow.modelData.module)
                                    onActivated: index => Services.Settings.editEntry("actions", actionRow.modelData.key, "module", model[index].id)
                                }
                                SettingsUI.SettingsButton {
                                    objectName: "removeAction-" + actionRow.modelData.key
                                    flat: true
                                    implicitWidth: 28
                                    leftPadding: 6
                                    rightPadding: 6
                                    text: "−"
                                    Accessible.name: "Remove action"
                                    onClicked: Services.Settings.editEntry("actions", actionRow.modelData.key, "enabled", false)
                                }
                            }
                        }
                    }
                    RowLayout {
                        Label {
                            text: "Available"
                            color: Theme.Theme.text
                            font.pixelSize: 12
                        }
                        SettingsUI.SettingsSelector {
                            id: addAction
                            objectName: "availableActions"
                            Accessible.name: "Available actions"
                            Layout.fillWidth: true
                            model: root.available("actions", "action")
                            textRole: "label"
                        }
                        SettingsUI.SettingsButton {
                            text: "Add action"
                            enabled: addAction.currentIndex >= 0
                            onClicked: root.addConfigured("actions", addAction.model[addAction.currentIndex].id)
                        }
                    }
                }
            }
            SettingsUI.SettingsSection {
                title: "Media Player"
                objectName: "mediaPlayerSettings"
                collapsible: true
                expanded: true
                SettingsUI.VisualSettingsGroup {
                    title: "Artwork and typography"
                    collapsible: false
                    numbers: [
                        {
                            key: "mediaArtworkSize",
                            label: "Album artwork size",
                            min: 48,
                            max: 112,
                            step: 1
                        },
                        {
                            key: "mediaProgressBorderWidth",
                            label: "Artwork/progress border width",
                            min: 0,
                            max: 5,
                            step: .5
                        },
                        {
                            key: "mediaTitleSize",
                            label: "Title size",
                            min: 10,
                            max: 24,
                            step: 1
                        },
                        {
                            key: "mediaArtistSize",
                            label: "Artist size",
                            min: 10,
                            max: 20,
                            step: 1
                        }
                    ]
                    weights: [
                        {
                            key: "mediaTitleWeight",
                            label: "Title weight"
                        },
                        {
                            key: "mediaArtistWeight",
                            label: "Artist weight"
                        }
                    ]
                }
                SettingsUI.SettingsRow {
                    Label {
                        text: "Progress colour"
                        Layout.fillWidth: true
                    }
                    SettingsUI.SemanticPaletteSelector {
                        role: Services.Settings.data.appearance.mediaProgressRole
                        onRoleSelected: value => Services.Settings.setValue("appearance", "mediaProgressRole", value)
                    }
                }
                SettingsUI.SettingsRow {
                    Label {
                        text: "Playback controls"
                        Layout.fillWidth: true
                    }
                    SettingsUI.SettingsSelector {
                        objectName: "mediaControlsVisibility"
                        model: ["Always", "While playing", "Player available", "Hidden"]
                        currentIndex: ["always", "playing", "active", "hidden"].indexOf(Services.Settings.data.media.controlsVisibility)
                        onActivated: Services.Settings.setValue("media", "controlsVisibility", ["always", "playing", "active", "hidden"][currentIndex])
                    }
                }
                SettingsUI.SettingsHelp {
                    text: "Player available preserves controls for paused media. While playing hides them when playback pauses."
                }
                SettingsUI.SettingsToggle {
                    text: "Media enabled"
                    checked: Services.Settings.data.media.enabled
                    onClicked: Services.Settings.setValue("media", "enabled", checked)
                }
                SettingsUI.SettingsRow {
                    Label {
                        text: "Preferred player"
                        Layout.fillWidth: true
                    }
                    SettingsUI.SettingsTextField {
                        Layout.fillWidth: true
                        text: Services.Settings.data.media.preferredPlayer || ""
                        placeholderText: "Automatic"
                        onEditingFinished: Services.Settings.setValue("media", "preferredPlayer", text.trim() || null)
                    }
                }
                SettingsUI.SettingsRow {
                    Label {
                        text: "Artwork corner roundness"
                        Layout.fillWidth: true
                    }
                    SettingsUI.SettingsSlider {
                        objectName: "artRoundness-albumArt"
                        Layout.fillWidth: true
                        from: 0
                        to: 2
                        stepSize: .05
                        value: Services.Settings.data.appearance.roundness.roles.albumArt ?? Services.Settings.data.appearance.roundness.master
                        onMoved: Services.Settings.setRoundness("albumArt", value)
                    }
                    SettingsUI.SettingsButton {
                        text: "Default"
                        onClicked: Services.Settings.setRoundness("albumArt", null)
                    }
                }
            }
            SettingsUI.SettingsButton {
                flat: true
                text: "Reset Control Centre appearance"
                onClicked: {
                    const defaults = Schema.defaults().appearance;
                    const visual = Schema.clone(Services.Settings.data.appearance.visual);
                    for (const key of Object.keys(defaults.visual))
                        if (key !== "statusIconSize")
                            visual[key] = defaults.visual[key];
                    Services.Settings.setValue("appearance", "visual", visual);
                    Services.Settings.setRoundness("avatar", null);
                    Services.Settings.setRoundness("albumArt", null);
                }
            }
            SettingsUI.SettingsButton {
                flat: true
                text: "Reset Control Centre"
                onClicked: Services.Settings.resetSection("controlCentre")
            }
        }
    }
}
