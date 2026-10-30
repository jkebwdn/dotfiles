import QtQuick
import QtQuick.Shapes
Item {
    id: root
    required property var tokens
    property string status: ""
    property bool nativeArtwork: false
    Image {
        anchors.centerIn: parent; width: root.width; height: width
        visible: root.nativeArtwork; smooth: true; mipmap: true; asynchronous: false
        source: visible && root.indicatorState !== "hidden" ? "image://visual/fingerprint/"+root.indicatorState : ""
    }
    // Display-only mapping; these shapes never authorize authentication.
    readonly property string indicatorState: status === "" ? "hidden"
        : status.includes("unavailable") || status.includes("No fingerprint") ? "unavailable"
        : status.includes("timed out") ? "timeout"
        : status.includes("didn’t match") ? "failed"
        : status === "Try again" ? "retry"
        : status === "Fingerprint matched" ? "matched" : "waiting"
    readonly property color ink: ["failed","unavailable"].includes(indicatorState) ? tokens.danger
        : ["retry","timeout"].includes(indicatorState) ? tokens.warning : tokens.accent
    implicitWidth: 18; implicitHeight: 24
    opacity: indicatorState === "hidden" ? 0 : 1
    Accessible.role: Accessible.Indicator
    Accessible.name: status
    Shape {
        antialiasing: true
        anchors.centerIn: parent
        width: 24; height: 24; scale: root.width/24
        visible: !root.nativeArtwork && root.indicatorState === "waiting"
        ShapePath {
            strokeColor: root.ink; strokeWidth: 1.7; fillColor: "transparent"
            capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M4 9 C4 0 20 0 20 9 M2 13 C2 7 5 4 12 4 C19 4 22 8 22 13 M6 20 C8 17 7 13 8 10 C9 6 16 6 17 11 C18 15 16 19 20 21 M3 18 C5 15 4 11 6 9 M10 22 C13 18 10 14 12 11 M15 22 C13 18 16 14 14 11" }
        }
    }
    Shape {
        antialiasing: true
        anchors.centerIn: parent; width:24; height:24; scale:root.width/24
        visible: !root.nativeArtwork && root.indicatorState !== "waiting" && root.indicatorState !== "hidden"
        ShapePath {
            strokeColor: root.ink; strokeWidth: 2; fillColor: "transparent"
            capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.indicatorState === "matched" ? "M4 12 L9 17 L20 6"
                : root.indicatorState === "retry" ? "M20 9 A8 8 0 1 0 20 16 M20 3 L20 9 L14 9"
                : root.indicatorState === "timeout" ? "M12 3 A9 9 0 1 0 12 21 A9 9 0 1 0 12 3 M12 6 L12 12 L16 14"
                : root.indicatorState === "failed" ? "M12 3 A9 9 0 1 0 12 21 A9 9 0 1 0 12 3 M8 8 L16 16 M16 8 L8 16"
                : "M12 3 L22 21 L2 21 Z M12 9 L12 14 M12 17 L12 18" }
        }
    }
}
