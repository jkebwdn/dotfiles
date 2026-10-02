pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell

import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/icons" as Icons
import "../../.config/quickshell/magi/theme" as Theme

ShellRoot {
    ApplicationWindow {
        width: 700
        height: 520
        visible: true
        title: "MAGI icon-pack fixture"
        color: Theme.Theme.background

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Label {
                text: "Production Icon component · "
                    + Icons.IconRegistry.resolve("wifi", "").icon.colorMode
                    + " SVG tint"
                color: Theme.Theme.text
                font.pixelSize: 18
                font.bold: true
            }

            Repeater {
                model: [
                    {role: "wifi", label: "Wi-Fi / opacity"},
                    {role: "bluetooth", label: "Bluetooth"},
                    {role: "battery", label: "Battery / narrow"},
                    {role: "volume-high", label: "Volume"},
                    {role: "back", label: "Chevron / narrow"},
                    {role: "airplane-mode", label: "Airplane / dense"},
                    {role: "package", label: "Package / complex"}
                ]

                RowLayout {
                    id: iconRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 18

                    Label {
                        Layout.preferredWidth: 150
                        text: iconRow.modelData.label
                        color: Theme.Theme.subtext
                    }

                    Repeater {
                        model: [12, 16, 20, 24]
                        Item {
                            id: sizeCell
                            required property int modelData
                            Layout.preferredWidth: 54
                            Layout.preferredHeight: 34
                            Controls.Icon {
                                anchors.centerIn: parent
                                role: iconRow.modelData.role
                                size: sizeCell.modelData
                                color: Theme.Theme.text
                            }
                            Label {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                text: sizeCell.modelData
                                color: Theme.Theme.muted
                                font.pixelSize: 8
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.Theme.border
            }

            RowLayout {
                spacing: 24
                Label { text: "Semantic states"; color: Theme.Theme.subtext; Layout.preferredWidth: 150 }
                Controls.Icon { role: "wifi"; size: 24; color: Theme.Theme.text }
                Controls.Icon { role: "wifi"; size: 24; color: Theme.Theme.accent }
                Controls.Icon { role: "wifi"; size: 24; color: Theme.Theme.muted }
                Label { text: "default / accent / muted"; color: Theme.Theme.subtext }
            }

            RowLayout {
                spacing: 24
                Label { text: "Legacy fallback"; color: Theme.Theme.subtext; Layout.preferredWidth: 150 }
                Controls.Icon { role: "settings"; size: 24; color: Theme.Theme.text }
                Label { text: "settings is absent from the partial MAGI pack"; color: Theme.Theme.subtext }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
