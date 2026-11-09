pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import "../../services" as Services

// A sibling of the panel, never a child of its clipped body or blur region.
// No input handlers, focus, semantic tint, background, shadow or animation timer.
Item {
    id: root
    objectName: "controlCentreDecoration"
    property var configuration: Services.Settings.data.controlCentre.decoration
    property rect panelRect: Qt.rect(0, 0, 0, 0)
    property real availableWidth: parent ? parent.width : 0
    property real availableHeight: parent ? parent.height : 0
    property bool panelReady: false
    property bool panelPresent: false
    property bool animate: true
    property bool playbackEnabled: true
    readonly property var asset: configuration.asset
    readonly property var bounds: asset ? asset.bounds : [0, 0, 1, 1]
    readonly property string sourceUrl: asset ? Services.AssetManager.assetUrl(asset.id) : ""
    readonly property real inset: Math.min(configuration.overlap, panelRect.width / 8)
    readonly property real imageScale: Math.max(0, Math.min(configuration.height / bounds[3],
        panelRect.height / bounds[3], (availableHeight - 16) / bounds[3],
        (panelRect.x + inset - 8) / bounds[2]))
    readonly property bool fits: height >= 96 && width > inset && panelRect.width > 0
    readonly property bool ready: sourceUrl.length > 0 && presenter !== null && presenter.status === Image.Ready
    readonly property bool revealing: configuration.enabled && ready && fits && panelReady && panelPresent
    readonly property bool animating: revealMotion.running
    readonly property var presenter: renderer.item
    property real progress: 0
    function syncReveal() {
        revealMotion.stop()
        const destination = revealing ? 1 : 0
        if (!animate || progress === destination) {
            progress = destination
            return
        }
        // Set timing before start: dependent Behavior bindings can otherwise
        // start opening with the previous 60ms closing duration.
        revealMotion.from = progress
        revealMotion.to = destination
        revealMotion.duration = revealing ? configuration.duration : 60
        revealMotion.easing.type = revealing ? Easing.InOutCubic : Easing.OutCubic
        revealMotion.start()
    }
    onRevealingChanged: syncReveal()
    onAnimateChanged: syncReveal()
    Component.onCompleted: syncReveal()
    width: bounds[2] * imageScale
    height: bounds[3] * imageScale
    x: Math.min(availableWidth - width, panelRect.x + inset - width + 12 * (1 - progress))
    y: Math.max(8, Math.min(availableHeight - height - 8,
        Math.max(panelRect.y, Math.min(panelRect.y + panelRect.height - height,
            panelRect.y + (panelRect.height - height) / 2 + configuration.verticalOffset))))
    opacity: progress
    visible: configuration.enabled && ready && fits && panelPresent && progress > 0
    // Only this artwork viewport clips transparent source margins. The panel and
    // window bounds are independent; the complete measured alpha union fits here.
    clip: true
    transform: Scale { origin.x: root.width / 2; xScale: root.configuration.flip ? -1 : 1 }
    NumberAnimation {
        id: revealMotion
        target: root
        property: "progress"
    }
    // Decode resolution never follows animated panel geometry.
    readonly property size decodeSize: asset ? Qt.size(
        Math.min(asset.width, Math.ceil(asset.width * configuration.height / bounds[3] * Screen.devicePixelRatio)),
        Math.min(asset.height, Math.ceil(asset.height * configuration.height / bounds[3] * Screen.devicePixelRatio))) : Qt.size(1, 1)
    Loader {
        id: renderer
        active: root.configuration.enabled && root.sourceUrl.length > 0
        x: -root.bounds[0] * root.imageScale
        y: -root.bounds[1] * root.imageScale
        width: root.asset ? root.asset.width * root.imageScale : 0
        height: root.asset ? root.asset.height * root.imageScale : 0
        sourceComponent: root.sourceUrl.endsWith(".gif") ? animated : still
    }
    Component {
        id: still
        Image {
            source: root.sourceUrl
            sourceSize: root.decodeSize
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }
    Component {
        id: animated
        AnimatedImage {
            source: root.sourceUrl
            sourceSize: root.decodeSize
            cache: false
            smooth: true
            paused: !root.visible || !root.panelReady || !root.playbackEnabled
        }
    }
}
