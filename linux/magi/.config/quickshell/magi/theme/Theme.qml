pragma Singleton
import QtQuick
import "../services" as MagiServices

QtObject {
    id: theme
    readonly property string selectedTheme: MagiServices.Settings.data.appearance.theme
    readonly property var definition: ThemeRegistry.resolve(selectedTheme)
    readonly property string effectiveTheme: definition.id
    readonly property string diagnostic: selectedTheme === effectiveTheme
        ? "" : "Unknown theme " + selectedTheme + "; using Catppuccin Mocha"
    readonly property var roles: definition.roles
    readonly property string iconPack: MagiServices.Settings.data.icons.pack
    readonly property var roundness: MagiServices.Settings.data.appearance.roundness

    readonly property var visual: MagiServices.Settings.data.appearance.visual
    readonly property real statusIconSize: visual.statusIconSize
    readonly property color controlOn: stateColor("primary", true)
    readonly property color controlOff: stateColor("primary", false)
    // Semantic role -> signed palette shade -> strength -> rendered ink.
    function stateColor(group, on) {
        const prefix = group === "secondary" ? "secondary" : "control"
        const role = visual[prefix + (on ? "On" : "Off")]
        return Qt.alpha(shadeAccent(roles[role] || text,
            on ? 0 : visual[prefix + "OffShade"]), on ? 1 : visual[prefix + "OffOpacity"])
    }
    function stateInk(group, toggle, active, available, armed) {
        if (armed) return danger
        return stateColor(group, available && (!toggle || active))
    }
    function controlInk(toggle, active, available, armed) {
        return stateInk("primary", toggle, active, available, armed)
    }
    function radius(role, reference, width, height) {
        const override = roundness.roles[role]
        const multiplier = override === null || override === undefined ? roundness.master : override
        return Math.max(0, Math.min(reference * multiplier, width / 2, height / 2))
    }
    // Positive shades darken; negative shades lighten. Both endpoints belong to
    // the selected palette. Light themes reverse the text/background anchors.
    readonly property color shadeDark: definition.dark ? background : text
    readonly property color shadeLight: definition.dark ? text : background
    function shadeAccent(accentColor, adjustment) {
        const amount = Math.max(-1, Math.min(1, adjustment))
        return Qt.tint(accentColor, Qt.alpha(amount >= 0 ? shadeDark : shadeLight, Math.abs(amount)))
    }
    function primaryAccent(role, fallbackRole) {
        if (ThemeRegistry.accentRoles.indexOf(role) >= 0 && roles[role] !== undefined)
            return roles[role]
        if (ThemeRegistry.accentRoles.indexOf(fallbackRole) >= 0 && roles[fallbackRole] !== undefined)
            return roles[fallbackRole]
        return accent
    }
    function primaryTileColor(accentColor) { return shadeAccent(accentColor, visual.tileBackgroundShade) }
    function primaryTileRim(accentColor) { return shadeAccent(accentColor, visual.tileBorderShade) }
    function onColor(role) {
        return roles["on" + role.charAt(0).toUpperCase() + role.slice(1)] || text
    }
    readonly property color background: roles.background
    readonly property color surface: roles.surface
    readonly property color elevated: roles.elevated
    readonly property color overlay: roles.overlay
    readonly property color border: roles.border
    readonly property color rim: roles.rim
    readonly property color text: roles.text
    readonly property color subtext: roles.subtext
    readonly property color muted: roles.muted
    readonly property color inactive: roles.inactive
    readonly property color accent: roles.accent
    readonly property color accentText: roles.onAccent
    readonly property color blue: roles.blue
    readonly property color lavender: roles.lavender
    readonly property color green: roles.green
    readonly property color yellow: roles.yellow
    readonly property color peach: roles.peach
    readonly property color red: roles.red
    readonly property color teal: roles.teal
    readonly property color focus: roles.focus
    readonly property color success: roles.success
    readonly property color warning: roles.warning
    readonly property color danger: roles.danger
    readonly property color sliderFill: roles[visual.sliderFill]
    readonly property color sliderTrack: roles[visual.sliderTrack]
    readonly property color sliderRim: roles[visual.sliderBorder]

    // Internal design tokens retain their accepted geometry.
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property real radiusSmall: radius("action", 6, 1000, 1000)
    readonly property real radiusMedium: radius("surface", 10, 1000, 1000)
    readonly property real radiusLarge: radius("surface", 14, 1000, 1000)
    readonly property int barPillHeight: 28
    readonly property real barPillRadius: radius("barPill", 8, 28, 28)
    readonly property int barSectionSpacing: 6
    readonly property int barEdgeMargin: 14
    readonly property int menuPadding: 12
    readonly property int menuTopPadding: 6
    readonly property int menuBottomPadding: 12
    readonly property int spacingSmall: 6
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 20
}
