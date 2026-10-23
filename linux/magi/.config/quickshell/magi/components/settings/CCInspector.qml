pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "." as SettingsUI
import "../../services" as Services
import "../../theme" as Theme
import "../../settings/SettingsSchema.js" as Schema

ColumnLayout {
    id: root
    property alias identitySection: identitySection
    property alias familySection: familySection
    readonly property bool individual: selection.scope === "module" && ["controls", "actions", "sliders"].includes(family)
    readonly property string familyLabel: ({
            controls: "Primary controls",
            actions: "Secondary controls",
            sliders: "Sliders"
        })[family] || ""
    function resetDisclosure() { familySection.expanded = !root.individual }
    Connections {
        target: root.selection
        function onInstanceChanged() { Qt.callLater(root.resetDisclosure) }
        function onFamilyChanged() { Qt.callLater(root.resetDisclosure) }
    }
    property bool behaviourOnly: false
    required property var selection
    readonly property string family: selection.family
    readonly property var entry: {
        for (const group of ["controls", "actions", "sliders"]) {
            const e = Services.Settings.data.controlCentre[group].find(e => e.module === selection.instance);
            if (e)
                return {
                    group: group,
                    value: e
                };
        }
        return null;
    }
    function accent(role) {
        if (entry)
            Services.Settings.editEntry(entry.group, entry.value.key, "accent", role);
    }
    Layout.fillWidth: true
    SettingsUI.SettingsSection {
        id: identitySection
        objectName: "ccIdentityInspector"
        visible: !root.behaviourOnly && (root.individual && root.entry !== null)
        title: (Schema.controlDefinitions().find(d => d.id === root.selection.instance)?.label || "Control")
        description: root.family === "sliders" ? "" : "Accent"
        SettingsUI.SettingsSelector {
            objectName: "ccInstanceAccent"
            visible: root.family !== "sliders"
            Accessible.name: identitySection.title + " accent"
            readonly property var roles: root.family === "actions" ? [null].concat(Schema.controlAccentRoles) : Schema.controlAccentRoles
            model: roles.map(role => role || "Shared accent")
            currentIndex: Math.max(0, roles.indexOf(root.entry?.value.accent || null))
            onActivated: index => root.accent(roles[index])
        }
    }
    SettingsUI.SettingsSection {
        id: familySection
        objectName: "ccFamilyInspector"
        title: root.individual ? root.familyLabel : ""
        collapsible: root.individual
        expanded: !root.individual
        SettingsUI.SettingsSection {
            title: "Profile Header"
            objectName: "profileHeaderSettings"
            collapsible: false
            visible: !root.behaviourOnly && (root.family === "profile")

            SettingsUI.SettingsRow {
                columns: 2
                Label {
                    Layout.columnSpan: 2
                    text: "Avatar shape"
                    Layout.fillWidth: true
                }
                SettingsUI.SettingsSlider {
                    Layout.row: 1
                    Layout.column: 0
                    objectName: "artRoundness-avatar"
                    Layout.fillWidth: true
                    from: 0
                    to: 2
                    stepSize: .05
                    value: Services.Settings.data.appearance.roundness.roles.avatar ?? Services.Settings.data.appearance.roundness.master
                    onMoved: Services.Settings.setRoundness("avatar", value)
                }
                SettingsUI.SettingsButton {
                    Layout.row: 1
                    Layout.column: 1
                    actionKind: "reset"
                    text: "Default"
                    onClicked: Services.Settings.setRoundness("avatar", null)
                }
            }
            SettingsUI.SettingsToggle {
                text: "Background"
                checked: Services.Settings.data.appearance.profileBackground.enabled
                onClicked: Services.Settings.setValue("appearance", "profileBackground", Object.assign({}, Services.Settings.data.appearance.profileBackground, {
                    enabled: checked
                }))
            }
            SettingsUI.SettingsRow {
                Label {
                    text: "Background colour"
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

            SettingsUI.VisualSettingsGroup {
                title: "Fine tune"
                objectName: "ccProfileFineTune"
                description: "Avatar and typography"
                collapsible: true
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
        }
        SettingsUI.SettingsSection {
            title: "Media Player"
            objectName: "mediaPlayerSettings"
            collapsible: false
            visible: root.family === "media"

            SettingsUI.SettingsRow {
                columns: 2
                visible: !root.behaviourOnly
                Label {
                    Layout.columnSpan: 2
                    text: "Artwork shape"
                    Layout.fillWidth: true
                }
                SettingsUI.SettingsSlider {
                    Layout.row: 1
                    Layout.column: 0
                    objectName: "artRoundness-albumArt"
                    Layout.fillWidth: true
                    from: 0
                    to: 2
                    stepSize: .05
                    value: Services.Settings.data.appearance.roundness.roles.albumArt ?? Services.Settings.data.appearance.roundness.master
                    onMoved: Services.Settings.setRoundness("albumArt", value)
                }
                SettingsUI.SettingsButton {
                    Layout.row: 1
                    Layout.column: 1
                    actionKind: "reset"
                    text: "Default"
                    onClicked: Services.Settings.setRoundness("albumArt", null)
                }
            }
            SettingsUI.SettingsRow {
                visible: !root.behaviourOnly
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
                    Accessible.name: "Playback controls"
                    Accessible.description: "Player available preserves controls for paused media. While playing hides them when playback pauses."
                    ToolTip.visible: hovered
                    ToolTip.text: Accessible.description
                    model: ["Always", "While playing", "Player available", "Hidden"]
                    currentIndex: ["always", "playing", "active", "hidden"].indexOf(Services.Settings.data.media.controlsVisibility)
                    onActivated: Services.Settings.setValue("media", "controlsVisibility", ["always", "playing", "active", "hidden"][currentIndex])
                }
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

            SettingsUI.VisualSettingsGroup {
                visible: !root.behaviourOnly
                title: "Fine tune"
                objectName: "ccMediaFineTune"
                description: "Artwork and typography"
                collapsible: true
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
        }
        SettingsUI.VisualSettingsGroup {
            title: root.individual ? "" : "Sliders"
            visible: !root.behaviourOnly && (root.family === "sliders")
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
        SettingsUI.SettingsSection {
            id: shapeSection
            visible: !root.behaviourOnly && (["controls", "actions", "sliders", "host"].includes(root.family))
            title: root.individual ? "" : ({
                    controls: "Primary controls",
                    actions: "Secondary controls",
                    sliders: "",
                    host: "Surface"
                })[root.family] || ""
            description: ""
            readonly property string radiusRole: ({
                    controls: "controlTile",
                    actions: "secondaryControl",
                    sliders: "slider",
                    host: "surface"
                })[root.family] || "surface"
            SettingsUI.SettingsHelp {
                visible: !root.behaviourOnly && (root.family === "host")
                text: "Shape and border styling are shared with other menus."
            }
            SettingsUI.SettingsRow {
                columns: 2
                Label {
                    Layout.columnSpan: 2
                    text: "Shape"
                    Layout.fillWidth: true
                }
                SettingsUI.SettingsSlider {
                    Layout.row: 1
                    Layout.column: 0
                    Layout.fillWidth: true
                    from: 0
                    to: 2
                    stepSize: .05
                    objectName: "ccFamilyShape"
                    value: Services.Settings.data.appearance.roundness.roles[shapeSection.radiusRole] ?? Services.Settings.data.appearance.roundness.master
                    onMoved: Services.Settings.setRoundness(shapeSection.radiusRole, value)
                }
                SettingsUI.SettingsButton {
                    Layout.row: 1
                    Layout.column: 1
                    actionKind: "reset"
                    text: "Default"
                    onClicked: Services.Settings.setRoundness(shapeSection.radiusRole, null)
                }
            }
            SettingsUI.SettingsRow {
                visible: !root.behaviourOnly && (root.family === "host")
                Label {
                    text: "Surface background"
                    Layout.fillWidth: true
                }
                SettingsUI.SemanticPaletteSelector {
                    model: ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "border", "accent"].concat(Theme.ThemeRegistry.accentRoles)
                    role: Services.Settings.data.appearance.controlCentreBackgroundRole
                    onRoleSelected: value => Services.Settings.setValue("appearance", "controlCentreBackgroundRole", value)
                }
            }
            SettingsUI.SurfaceStyleSettings {
                visible: !root.behaviourOnly && (root.family === "host")
                title: "Border"
                group: "surfaceBorders"
                targets: [
                    {
                        id: "controlcentre",
                        label: "Show border"
                    }
                ]
            }
        }
        SettingsUI.SettingsSection {
            visible: !root.behaviourOnly && (["controls", "actions"].includes(root.family))
            title: ""
            SettingsUI.SettingsRow {
                columns: 2
                Label {
                    text: "Columns"
                    Layout.fillWidth: true
                }
                SettingsUI.SettingsNumber {
                    objectName: root.family === "controls" ? "primaryColumns" : "secondaryColumns"
                    from: 1
                    to: 16
                    value: Services.Settings.data.controlCentre[root.family === "controls" ? "columns" : "actionColumns"]
                    onValueModified: Services.Settings.setValue("controlCentre", root.family === "controls" ? "columns" : "actionColumns", value)
                }
            }
        }
        SettingsUI.VisualSettingsGroup {
            title: "Fine tune"
            objectName: "ccPrimaryFineTune"
            visible: !root.behaviourOnly && (root.family === "controls")
            collapsible: true
            description: ""
            numbers: [
                {
                    key: "primaryIconSize",
                    label: "Icon size",
                    min: 16,
                    max: 48,
                    step: 1
                },
                {
                    key: "primaryContainerSize",
                    label: "Container size",
                    min: 60,
                    max: 96,
                    step: 1
                },
                {
                    key: "tileBackgroundShade",
                    label: "Background shade",
                    min: -1,
                    max: 1,
                    step: .02,
                    shade: true
                },
                {
                    key: "tileBorderShade",
                    label: "Border shade",
                    min: -1,
                    max: 1,
                    step: .02,
                    shade: true
                },
                {
                    key: "tileBorderWidth",
                    label: "Border width",
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
            title: "Fine tune"
            objectName: "ccSecondaryFineTune"
            description: ""
            visible: !root.behaviourOnly && (root.family === "actions")
            collapsible: true
            numbers: [
                {
                    key: "secondaryContainerSize",
                    label: "Minimum container size",
                    min: 32,
                    max: 72,
                    step: 1
                },
                {
                    key: "secondaryBackgroundOpacity",
                    label: "Accent background opacity",
                    min: 0,
                    max: 1,
                    step: .05
                },
                {
                    key: "secondaryBorderWidth",
                    label: "Border width",
                    min: 0,
                    max: 6,
                    step: .5
                },
                {
                    key: "secondaryIconSize",
                    label: "Icon size",
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
                    key: "secondaryBorder",
                    label: "Border role"
                },
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
            visible: !root.behaviourOnly && (["profile", "controls", "sliders", "actions", "media"].includes(root.family))
            title: "Section spacing"
            collapsible: true
            numbers: [
                {
                    key: ({
                            profile: "profileControlsGap",
                            controls: "controlsSlidersGap",
                            sliders: "slidersActionsGap",
                            actions: "actionsMediaGap",
                            media: "mediaSectionGap"
                        })[root.family] || "profileControlsGap",
                    label: "Gap after this section",
                    min: 0,
                    max: 48,
                    step: 1
                }
            ]
        }
    }
}
