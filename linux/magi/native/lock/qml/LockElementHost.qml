import QtQuick
import "LockLayout.js" as Layout
Item {
    id: root
    property string elementId
    property var configuration
    property real canvasWidth
    property real canvasHeight
    property real baseWidth
    property real contentHeight
    property bool composition: false
    property real flowX: 0
    property real flowY: 0
    width: Math.min(baseWidth, Math.max(1,canvasWidth-32)/configuration.size)
    height: contentHeight
    scale: configuration.size
    transformOrigin: Item.TopLeft
    readonly property var resolved: Layout.position(configuration,canvasWidth,canvasHeight,width*scale,height*scale)
    x: composition ? flowX : resolved.x
    y: composition ? flowY : resolved.y
    visible: configuration.visible
    z: configuration.z
}
