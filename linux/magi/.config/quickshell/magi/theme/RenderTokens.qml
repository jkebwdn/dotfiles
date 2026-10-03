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
    readonly property int tileSize: 60
    readonly property real tileRadius: Theme.radius("controlTile", 10, tileSize, tileSize)
    readonly property real tileBorder: Theme.visual.tileBorderWidth
    readonly property int tileIconSize: 32
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
