import QtQuick
import QtQuick.Effects
import "../../icons" as Icons
import "../../theme" as Theme
import "../../services" as Services
Item {
    id: root
    property string role: "missing"
    property string moduleId: ""
    property real size: 16
    property color color: Theme.Theme.text
    readonly property var resolved: Icons.IconRegistry.resolve(role, moduleId)
    readonly property bool assetIcon: resolved.icon.kind === "svg"
        || resolved.icon.kind === "managed" || resolved.icon.kind === "user"
    readonly property bool semanticAsset: assetIcon
        && resolved.icon.colorMode !== "fixed"
    implicitWidth: size
    implicitHeight: size
    Text {
        anchors.centerIn: parent
        visible: root.resolved.icon.kind === "glyph"
            || (root.assetIcon && asset.status === Image.Error)
        text: asset.status === Image.Error ? "?" : root.resolved.icon.text || ""
        font.family: root.resolved.icon.font || Theme.Theme.fontFamily
        font.pixelSize: root.size
        color: root.color
    }
    Image {
        id: asset
        anchors.fill: parent
        visible: root.assetIcon && !root.semanticAsset && status !== Image.Error
        source: root.resolved.icon.kind === "svg" ? Qt.resolvedUrl("../../icons/packs/" + root.resolved.icon.path)
            : root.resolved.icon.kind === "managed" ? root.resolved.icon.url
            : root.resolved.icon.kind === "user" ? Services.AssetManager.assetUrl(root.resolved.icon.assetId) : ""
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
