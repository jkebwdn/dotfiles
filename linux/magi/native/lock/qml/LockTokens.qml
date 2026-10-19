import QtQuick
QtObject {
    objectName: "visualTokens"
    property var palette: ({})
    readonly property color background: palette.background || "#1e1e2e"
    readonly property color surface: palette.surface || "#313244"
    property bool artworkAvailable: false
    readonly property color ink: palette.text || "#cdd6f4"
    readonly property color secondary: palette.subtext || "#bac2de"
    readonly property color accent: palette.accent || "#b4befe"
    readonly property color danger: palette.danger || "#f38ba8"
    readonly property color warning: palette.warning || "#f9e2af"
    readonly property string family: palette.fontFamily || "JetBrainsMono Nerd Font"
    readonly property int clockSize: 112
    readonly property int dateSize: 17
    readonly property int nameSize: 25
    readonly property int statusSize: 16
    readonly property int avatarSize: 112
    readonly property int gap: 16
    readonly property int dotSize: 9
    readonly property int dotGap: 10
    readonly property real backgroundTint: palette.wallpaperTint === undefined ? 0.42 : palette.wallpaperTint
    property real logicalWidth: 1920
    property real logicalHeight: 1080
    readonly property real visualScale: Math.max(0.8, Math.min(1.15,
        Math.pow(Math.min(logicalWidth / 1920, logicalHeight / 1080), 0.45)))
    readonly property real avatarRadius: palette.avatarRadius === undefined ? 12 : palette.avatarRadius
}
