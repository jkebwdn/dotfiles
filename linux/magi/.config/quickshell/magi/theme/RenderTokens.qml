pragma Singleton
import QtQuick

// Measured reference values and explicit logical-pixel adaptations are recorded
// in docs/design/render-visual-specification.md. Scoped to the CC reference pass.
QtObject {
    readonly property int controlWidth: 320
    readonly property int controlBodyHeight: 208
    readonly property int padding: 14
    readonly property int outerRadius: 11
    readonly property int tileSize: 60
    readonly property int tileRadius: 10
    readonly property int tileBorder: 3
    readonly property int tileIconSize: 32
    readonly property int tileSliderGap: 24
    readonly property int sliderHeight: 48
    readonly property int sliderGap: 20
    readonly property int sliderRadius: 10
    readonly property int sliderBorder: 2
    readonly property int sliderIconSize: 28
    readonly property int powerGap: 20
    readonly property int powerHeight: 36
    readonly property string textFamily: "Noto Sans"
    readonly property int secondarySize: 12

    readonly property color surface: "#423d55"
    readonly property color group: "#514b69"
    readonly property color sliderFill: "#413d50"
    readonly property color sliderTrack: "#4d485e"
    readonly property color sliderRim: "#655e82"
    readonly property color wifi: "#4f9192"
    readonly property color wifiRim: "#69a1a2"
    readonly property color power: "#9b4e63"
    readonly property color powerRim: "#aa687a"
    readonly property color sound: "#9b7668"
    readonly property color soundRim: "#aa8a7e"
    readonly property color bluetooth: "#6c92c5"
    readonly property color bluetoothRim: "#81a2cd"
    readonly property color foreground: "#f7f5fb"
    readonly property color secondary: "#c8c3d5"
}
