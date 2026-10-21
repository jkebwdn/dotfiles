
import QtQuick
import Quickshell.Hyprland
import "../../../theme" as MagiTheme
import "WorkspaceModel.js" as WorkspaceModel

Rectangle {
    id: root

    property var outputScreen: null
    readonly property var outputMonitor: outputScreen ? Hyprland.monitorFor(outputScreen) : null
    readonly property var activeWorkspace: outputMonitor ? outputMonitor.activeWorkspace : null
    // One continuous workspace chip, styled by MAGI's active palette.
    color: MagiTheme.Theme.surface
    radius: MagiTheme.Theme.barPillRadius

    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: MagiTheme.Theme.barPillHeight


    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: WorkspaceModel.normalWorkspaces(Hyprland.workspaces.values)

            delegate: Rectangle {
                id: workspace

                required property var modelData

                readonly property bool isActive:
                    root.activeWorkspace !== null
                    && modelData.id === root.activeWorkspace.id

                implicitWidth: 28
                implicitHeight: MagiTheme.Theme.barPillHeight

                radius: root.radius

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
