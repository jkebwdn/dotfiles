import QtQuick
import QtQuick.Effects

// All gallery instances share Qt's bounded URL/sourceSize pixmap cache.
Rectangle {
    id: root
    property url source
    property bool blurred: false
    property color shade: "#1e1e2e"
    readonly property bool ready: wallpaper.status===Image.Ready
    color: shade
    clip: true
    Image {
        id: wallpaper; objectName:"lockPreviewWallpaper"
        anchors.fill:parent;source:root.source
        sourceSize:Qt.size(960,540);cache:true;asynchronous:true
        fillMode:Image.PreserveAspectCrop;smooth:true
        visible:!root.blurred
    }
    Loader {
        anchors.fill:parent
        active:root.blurred && root.ready
        sourceComponent: Component {
            MultiEffect {source:wallpaper;blurEnabled:true;blur:.6;blurMax:32;autoPaddingEnabled:false}
        }
    }
    Rectangle {anchors.fill:parent;color:root.shade;opacity:root.ready ? .42 : 0}
}
