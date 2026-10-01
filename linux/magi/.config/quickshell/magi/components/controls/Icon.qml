import QtQuick
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
    implicitWidth: size
    implicitHeight: size
    Text {
        anchors.centerIn: parent
        visible: root.resolved.icon.kind === "glyph" || asset.status === Image.Error
        text: asset.status === Image.Error ? "?" : root.resolved.icon.text || ""
        font.family: root.resolved.icon.font || Theme.Theme.fontFamily
        font.pixelSize: root.size
        color: root.color
    }
    Image {
        id: asset
        anchors.fill: parent
        visible: (root.resolved.icon.kind === "svg" || root.resolved.icon.kind === "managed"
            || root.resolved.icon.kind === "user") && status !== Image.Error
        source: root.resolved.icon.kind === "svg" ? Qt.resolvedUrl("../../icons/packs/" + root.resolved.icon.path)
            : root.resolved.icon.kind === "managed" ? root.resolved.icon.url
            : root.resolved.icon.kind === "user" ? Services.AssetManager.assetUrl(root.resolved.icon.assetId) : ""
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
    }
}
