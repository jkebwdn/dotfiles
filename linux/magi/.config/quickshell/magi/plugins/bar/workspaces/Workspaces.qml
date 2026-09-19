
import QtQuick
import Quickshell.Hyprland
import "../../../theme" as MagiTheme

Rectangle {
    id: root

    // One continuous workspace chip, styled by MAGI's active palette.
    color: MagiTheme.Theme.surface
    radius: MagiTheme.Theme.radiusMedium

    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: 26

    Component.onCompleted: Hyprland.refreshWorkspaces()

    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                id: workspace

                required property var modelData

                readonly property bool isActive:
                    Hyprland.focusedWorkspace !== null
                    && modelData.id === Hyprland.focusedWorkspace.id

                readonly property bool isVisible:
                    modelData.lastIpcObject !== null
                    && (modelData.lastIpcObject.windows > 0 || isActive)

                visible: isVisible

                implicitWidth: isVisible ? 28 : 0
                implicitHeight: 26

                radius: MagiTheme.Theme.radiusSmall

                color: isActive
                    ? MagiTheme.Theme.accent
                    : mouseArea.containsMouse
                        ? MagiTheme.Theme.elevated
                        : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent

                    text: workspace.modelData.id

                    color: workspace.isActive
                        ? MagiTheme.Theme.accentText
                        : MagiTheme.Theme.muted

                    font.family: MagiTheme.Theme.fontFamily
                    font.pixelSize: 12

                    font.weight: workspace.isActive
                        ? Font.ExtraBold
                        : Font.Normal
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: Hyprland.dispatch(
                        'hl.dsp.focus({workspace="' + workspace.modelData.id + '"})'
                    )
                }
            }
        }
    }
}
