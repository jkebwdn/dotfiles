pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import "../../services" as Services
import "../../theme" as Theme

// Artwork owns its colour and alpha. This is intentionally not a StatusPill,
// semantic icon, blur region or input target.
Item {
    id: root
    objectName: "barCustomImage"
    property var configuration: Services.Settings.data.bar.modules.customImage || ({})
    readonly property var asset: configuration.asset || null
    readonly property string sourceUrl: asset ? Services.AssetManager.assetUrl(asset.id) : ""
    readonly property var bounds: asset ? configuration.trim === false
        ? [0, 0, asset.width, asset.height] : asset.bounds : [0, 0, 1, 1]
    readonly property real imageScale: Math.min((configuration.height || 32) / bounds[3], 240 / bounds[2])
    // Derive decode size from Settings, never Image.width: before Loader sizes
    // its child, width can be the decode's own implicit width (Qt recursion).
    readonly property size decodeSize: asset ? Qt.size(
        Math.min(asset.width, Math.max(1, Math.ceil(asset.width * imageScale * Screen.devicePixelRatio))),
        Math.min(asset.height, Math.max(1, Math.ceil(asset.height * imageScale * Screen.devicePixelRatio)))) : Qt.size(1, 1)
    readonly property var presenter: renderer.item
    readonly property bool barVisible: sourceUrl.length > 0 && presenter !== null && presenter.status === Image.Ready
    implicitWidth: sourceUrl ? bounds[2] * imageScale : 0
    // Retain existing Row/SharedStatusSurface geometry; artwork is centered on it.
    implicitHeight: Theme.Theme.barPillHeight
    visible: barVisible
    Item {
        id: viewport
        anchors.centerIn: parent
        width: root.implicitWidth
        height: root.bounds[3] * root.imageScale
        clip: true
        Loader {
            id: renderer
            x: -root.bounds[0] * root.imageScale
            y: -root.bounds[1] * root.imageScale
            width: root.asset ? root.asset.width * root.imageScale : 0
            height: root.asset ? root.asset.height * root.imageScale : 0
            active: root.sourceUrl.length > 0
            sourceComponent: root.sourceUrl.endsWith(".gif") ? animated : still
        }
    }
    Component {
        id: animated
        AnimatedImage {
            source: root.sourceUrl
            // Bound cached-frame memory to the rendered size on this output.
            sourceSize: root.decodeSize
            cache: false
            smooth: true
            paused: !root.visible
        }
    }
    Component {
        id: still
        Image {
            source: root.sourceUrl
            sourceSize: root.decodeSize
            smooth: true
        }
    }
}
