import QtQuick
import QtQuick.Effects
import "../../theme" as Theme
import "VisualState.js" as VisualState
Item {
    id: root
    property int fillMode: Image.PreserveAspectCrop
    property url source
    property real radius: 10
    property real borderWidth: 2
    property color borderColor: Theme.Theme.rim
    property color progressColor: Theme.Theme.accent
    property real progress: -1
    property string placeholder: "music"
    // The frame and image have separate, concentric contours. The image never
    // sits beneath the frame's antialiased outer edge, including with no frame.
    readonly property real frameWidth: Math.max(0, Math.min(borderWidth, width / 2, height / 2))
    readonly property real outerRadius: Math.max(0, Math.min(radius, width / 2, height / 2))
    clip: true
    Rectangle { anchors.fill: parent; radius: root.outerRadius; color: Theme.Theme.overlay }
    Item {
        id: imageBounds
        objectName: "artworkImageBounds"
        anchors.fill: parent
        anchors.margins: root.frameWidth
        Image {
            id: image
            objectName: "artworkSource"
            anchors.fill: parent
            source: root.source
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: root.fillMode
            clip: true
            layer.enabled: true
            visible: false
        }
        Rectangle {
            id: mask
            objectName: "artworkMask"
            anchors.fill: parent
            radius: Math.max(0, root.outerRadius - root.frameWidth)
            color: "white"
            antialiasing: true
            layer.enabled: true
            visible: false
        }
        MultiEffect {
            objectName: "artworkEffect"
            anchors.fill: parent
            source: image
            visible: image.status === Image.Ready
            maskEnabled: true
            maskSource: mask
            // The default zero-width threshold promotes faint edge coverage to
            // opaque pixels. Smooth across the mask's full antialiased alpha range.
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            autoPaddingEnabled: false
        }
    }
    Icon { anchors.centerIn: parent; role: root.placeholder; size: 24; color: Theme.Theme.subtext; visible: image.status !== Image.Ready }
    Rectangle { anchors.fill: parent; radius: root.outerRadius; color: "transparent"; border.color: root.borderColor; border.width: root.frameWidth }
    Canvas {
        id: progressBorder
        anchors.fill: parent
        visible: root.progress >= 0 && root.borderWidth > 0
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: requestPaint()
        Connections {
            target: root
            function onProgressChanged() { progressBorder.requestPaint() }
            function onRadiusChanged() { progressBorder.requestPaint() }
            function onBorderWidthChanged() { progressBorder.requestPaint() }
            function onProgressColorChanged() { progressBorder.requestPaint() }
        }
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (root.progress < 0 || root.borderWidth <= 0) return
            const points = VisualState.perimeter(width, height, Math.max(0, root.outerRadius - root.frameWidth / 2), root.frameWidth / 2)
            let length = 0
            for (let i = 1; i < points.length; ++i) length += Math.hypot(points[i][0]-points[i-1][0],points[i][1]-points[i-1][1])
            let remaining = length * Math.min(1, root.progress)
            ctx.beginPath(); ctx.moveTo(points[0][0], points[0][1])
            for (let i = 1; i < points.length && remaining > 0; ++i) {
                const a = points[i-1], b = points[i], distance = Math.hypot(b[0]-a[0],b[1]-a[1])
                const fraction = distance > 0 ? Math.min(1, remaining/distance) : 0
                ctx.lineTo(a[0]+(b[0]-a[0])*fraction,a[1]+(b[1]-a[1])*fraction)
                remaining -= distance
            }
            ctx.lineWidth = root.frameWidth; ctx.strokeStyle = root.progressColor; ctx.stroke()
        }
    }
}
