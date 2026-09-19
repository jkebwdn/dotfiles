pragma Singleton

import QtQuick
import "../services" as MagiServices
import "palettes" as Palettes

QtObject {
    id: theme

    // Selected palette, persisted through MAGI settings
    property string palette: MagiServices.Settings.palette

    onPaletteChanged: {
        if (MagiServices.Settings.palette !== palette)
            MagiServices.Settings.palette = palette
    }

    readonly property bool isEverforest: palette === "everforest"

    // Palette instances must be explicit properties of QtObject.
    // QtObject does not support arbitrary child objects.
    readonly property QtObject catppuccin: Palettes.CatppuccinMocha {}
    readonly property QtObject everforest: Palettes.EverforestDarkHard {}

    readonly property QtObject active:
        isEverforest ? everforest : catppuccin

    // Semantic colours
    readonly property color background: active.background
    readonly property color surface: active.surface
    readonly property color elevated: active.elevated
    readonly property color border: active.border

    readonly property color text: active.text
    readonly property color muted: active.muted

    readonly property color accent: active.accent
    readonly property color accentText: active.accentText

    readonly property color success: active.success
    readonly property color warning: active.warning
    readonly property color danger: active.danger

    // Typography
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // Corner radii
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 14

    // Spacing
    readonly property int spacingSmall: 6
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 20
}
