pragma Singleton
import QtQuick

// Geometry/typography only. Palette roles live in Theme, never in render tokens.
// Measured reference values and explicit logical-pixel adaptations are recorded
// in docs/design/render-visual-specification.md. Scoped to the CC reference pass.
QtObject {
    readonly property int controlWidth: 320
    readonly property int controlBodyHeight: 208
    readonly property int padding: 14
    readonly property real outerRadius: Theme.radius("surface", 11, controlWidth, controlBodyHeight)
    readonly property real avatarSize: Theme.visual.avatarSize
    readonly property real mediaArtworkSize: Theme.visual.mediaArtworkSize
    readonly property real profileHeight: Math.max(84, avatarSize)
    readonly property real mediaHeight: Math.max(100, mediaArtworkSize + 20)
    readonly property real tileSize: Theme.visual.primaryContainerSize
    readonly property real tileRadius: Theme.radius("controlTile", 10, tileSize, tileSize)
    readonly property real tileBorder: Theme.visual.tileBorderWidth
    readonly property real tileIconSize: Theme.visual.primaryIconSize
    readonly property real actionIconSize: Theme.visual.secondaryIconSize
    readonly property real actionSize: Math.max(Theme.visual.secondaryContainerSize, actionIconSize + 6)
    readonly property int tileSliderGap: 24
    readonly property int sliderHeight: 48
    readonly property int sliderGap: 20
    readonly property real sliderRadius: Theme.radius("slider", 10, 1000, sliderHeight)
    readonly property real sliderBorder: Theme.visual.sliderBorderWidth
    readonly property int sliderIconSize: 28
    readonly property int powerGap: 20
    readonly property int powerHeight: 36
    readonly property string textFamily: "Noto Sans"
    readonly property int secondarySize: 12

}
