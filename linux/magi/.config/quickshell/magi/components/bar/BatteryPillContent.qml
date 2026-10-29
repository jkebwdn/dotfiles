import QtQuick
import "../controls" as Controls
import "../../icons" as Icons
import "../../theme" as MagiTheme
StatusPill {
    id: root
    styleId: "battery"
    property bool available: true
    property bool charging: false
    property int percentage: 72
    property bool hovered: false
    property real sharedExpansion: 0
    property bool showPercentage: MagiTheme.Theme.barItemStyle("battery").showPercentage !== false
    readonly property bool percentageVisible: available && showPercentage
    readonly property real iconRegionWidth: MagiTheme.Theme.statusIconSize + (percentageVisible ? 11 : 18)
    implicitWidth: iconRegionWidth + (percentageVisible ? label.implicitWidth + 11 : 0)
    color: "transparent"
    border.width: 0
    // Compose opaque fills first, then apply shared alpha once. The percentage
    // fill continues under the icon's inner curves without a transparent notch
    // or doubled alpha, while foreground content remains fully opaque.
    Item {
        id: backgrounds
        objectName: "batteryBackgrounds"
        anchors.fill: parent
        layer.enabled: true
        opacity: root.itemBackground.a * (1 - root.sharedExpansion)
        Rectangle {
            objectName: "batteryPercentageRegion"
            border.width: 0
            visible: root.percentageVisible
            anchors.fill: parent
            radius: root.radius
            color: Qt.alpha(root.hovered ? MagiTheme.Theme.barItemHoverBackground("battery", "percentage") : MagiTheme.Theme.barItemBackground("battery", "percentage"), 1)
        }
        Rectangle {
            objectName: "batteryIconRegion"
            border.width: 0
            width: root.iconRegionWidth; height: root.height
            radius: root.radius
            color: Qt.alpha(root.hovered ? MagiTheme.Theme.barItemHoverBackground("battery") : root.itemBackground, 1)
        }
    }
    // Draw the one outer border above both fills; neither region owns a border.
    Rectangle {
        objectName: "batteryOuterBorder"
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.border.width
        border.color: root.border.color
    }
    Controls.Icon {
        objectName: "batteryStatusIcon"
        x: 9; anchors.verticalCenter: parent.verticalCenter
        role: Icons.IconRegistry.batteryRole(root.available, root.charging, root.percentage)
        moduleId: "battery"; size: MagiTheme.Theme.statusIconSize
        color: MagiTheme.Theme.barItemForeground("battery", MagiTheme.Theme.text)
    }
    Text {
        id: label
        objectName: "batteryPercentageText"
        visible: root.percentageVisible
        x: root.iconRegionWidth + 2; anchors.verticalCenter: parent.verticalCenter
        text: root.available ? root.percentage + "%" : ""
        color: MagiTheme.Theme.roles[MagiTheme.Theme.barItemStyle("battery").percentageForegroundRole] || MagiTheme.Theme.text
        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 11
    }
}
