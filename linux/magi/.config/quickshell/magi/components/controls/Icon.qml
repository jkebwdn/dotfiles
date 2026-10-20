import QtQuick
import QtQuick.Effects
import "../../icons" as Icons
import "../../theme" as Theme
Item {
    id: root
    property string role: "missing"
    property string moduleId: ""
    property real size: 16
    property color color: Theme.Theme.text
    readonly property var requested: Icons.IconRegistry.resolve(role)
    readonly property var canonical: Icons.IconRegistry.resolve(role, true)
    property int failureStage: 0
    readonly property var resolved: failureStage === 0 ? requested : failureStage === 1 ? canonical
        : ({icon: {kind: "placeholder", colorMode: "semantic"}})
    onRequestedChanged: failureStage = 0
    function recoverAsset() {
        if (asset.status !== Image.Error || failureStage >= 2) return
        failureStage = failureStage === 0 && (canonical.icon.kind === "glyph"
            || (canonical.icon.kind === "managed" && canonical.icon.url !== requested.icon.url)) ? 1 : 2
    }
    readonly property url placeholderSource: Qt.resolvedUrl("../../icons/packs/magi-default/missing.svg")
    readonly property bool assetIcon: (resolved.icon.kind === "managed" || resolved.icon.kind === "placeholder")
    readonly property bool semanticAsset: assetIcon
        && resolved.icon.colorMode !== "fixed"
    implicitWidth: size
    implicitHeight: size
    Text {
        anchors.centerIn: parent
        visible: root.resolved.icon.kind === "glyph"
        text: root.resolved.icon.text || ""
        font.family: root.resolved.icon.font || Theme.Theme.fontFamily
        font.pixelSize: root.size
        color: root.color
    }
    Image {
        id: asset
        anchors.fill: parent
        visible: root.assetIcon && !root.semanticAsset && status !== Image.Error
        source: root.resolved.icon.kind === "placeholder" ? root.placeholderSource
            : root.assetIcon ? root.resolved.icon.url : ""
        onStatusChanged: if (status === Image.Error) Qt.callLater(root.recoverAsset)
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
    }
    MultiEffect {
        anchors.fill: asset
        source: asset
        visible: root.semanticAsset && asset.status !== Image.Error
        autoPaddingEnabled: false
        colorization: 1
        // Separate state alpha from RGB tint. Preserve the SVG's own alpha mask;
        // muted/off states multiply it, just as Text's color alpha does.
        colorizationColor: Qt.rgba(root.color.r, root.color.g, root.color.b, 1)
        opacity: root.color.a
    }
}
