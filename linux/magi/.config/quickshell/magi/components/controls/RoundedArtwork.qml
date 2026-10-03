import QtQuick
import QtQuick.Effects
import "../../theme" as Theme
import "VisualState.js" as VisualState
Item {
    id: root
    property url source
    property real radius: 10
    property real borderWidth: 2
    property color borderColor: Theme.Theme.rim
    property color progressColor: Theme.Theme.accent
    property real progress: -1
    property string placeholder: "music"
    Rectangle { anchors.fill: parent; radius: root.radius; color: Theme.Theme.overlay }
    Image {
        id: image
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        color: "white"
        layer.enabled: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: image
        visible: image.status === Image.Ready
        maskEnabled: true
        maskSource: mask
        autoPaddingEnabled: false
    }
    Icon { anchors.centerIn: parent; role: root.placeholder; size: 24; color: Theme.Theme.subtext; visible: image.status !== Image.Ready }
    Rectangle { anchors.fill: parent; radius: root.radius; color: "transparent"; border.color: root.borderColor; border.width: root.borderWidth }
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
            const points = VisualState.perimeter(width, height, Math.max(0, root.radius - root.borderWidth / 2), root.borderWidth / 2)
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
            ctx.lineWidth = root.borderWidth; ctx.strokeStyle = root.progressColor; ctx.stroke()
        }
    }
}
