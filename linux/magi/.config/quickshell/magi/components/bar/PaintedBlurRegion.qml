pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import Quickshell

// Explicit window-local geometry avoids extending blur into transparent input areas.
Region {
    id: root
    property Item target: null
    property bool painted: true
    property real cornerRadius: 0
    readonly property point origin: {
        const transform = watch.transform
        return target ? target.mapToItem(null, 0, 0) : Qt.point(0, 0)
    }
    property TransformWatcher watch: TransformWatcher {
        a: root.target
        b: root.target && root.target.Window.window ? root.target.Window.window.contentItem : null
    }
    x: Math.floor(origin.x); y: Math.floor(origin.y)
    width: painted && target && target.visible && target.opacity > 0 ? Math.ceil(target.width) : 0
    height: width > 0 ? Math.ceil(target.height) : 0
    radius: cornerRadius
}
