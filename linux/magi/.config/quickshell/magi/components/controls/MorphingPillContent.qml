import QtQuick

import "../../theme" as MagiTheme

Item {
    id: root

    required property var pill
    property string icon: "missing"
    property string moduleId: ""
    property string collapsedText: ""
    property string expandedTitle: ""
    property string expandedStatus: ""
    property color iconColor: MagiTheme.Theme.text
    property color textColor: MagiTheme.Theme.text
    property color statusColor: MagiTheme.Theme.muted

    readonly property real expansionProgress: {
        if (!pill || pill.expandedWidth <= pill.collapsedWidth)
            return 0
        return Math.max(0, Math.min(1,
            (pill.animatedWidth - pill.collapsedWidth)
                / (pill.expandedWidth - pill.collapsedWidth)
        ))
    }
    readonly property real compactContentWidth:
        iconText.implicitWidth
        + (collapsedText.length > 0 ? 6 + compactLabel.implicitWidth : 0)
    readonly property real compactStartX:
        Math.max(8, (width - compactContentWidth) / 2)

    anchors.fill: parent

    Icon {
        id: iconText

        x: root.compactStartX
            + (10 - root.compactStartX) * root.expansionProgress
        anchors.verticalCenter: parent.verticalCenter
        role: root.icon
        moduleId: root.moduleId
        color: root.iconColor
        size: 13
    }

    Text {
        id: compactLabel

        x: iconText.x + iconText.implicitWidth + 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.collapsedText
        color: root.textColor
        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 11
        font.bold: true
        opacity: 1 - root.expansionProgress
        visible: opacity > 0 && text.length > 0
    }

    Text {
        anchors {
            left: iconText.right
            leftMargin: 9
            right: expandedStatusText.visible
                ? expandedStatusText.left
                : parent.right
            rightMargin: expandedStatusText.visible ? 10 : 12
            verticalCenter: parent.verticalCenter
        }
        text: root.expandedTitle
        color: root.textColor
        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 11
        font.bold: true
        elide: Text.ElideRight
        opacity: root.expansionProgress
        visible: opacity > 0
    }

    Text {
        id: expandedStatusText

        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: root.expandedStatus
        color: root.statusColor
        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 9
        font.bold: true
        opacity: root.expansionProgress
        visible: opacity > 0 && text.length > 0
    }
}
