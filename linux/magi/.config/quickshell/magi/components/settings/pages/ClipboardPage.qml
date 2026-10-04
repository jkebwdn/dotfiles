pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI

Flickable {
    id: root
    property bool eraseArmed: false
    contentHeight: content.implicitHeight + 48
    clip: true
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: content
        x: 24; y: 24; width: root.width - 48; spacing: 16
        Label { text: "Clipboard"; font.pixelSize: 26; font.bold: true }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "SUPER + SHIFT + V opens history. New copies are collected; the clipboard already present at startup is skipped."
            color: Theme.Theme.subtext
        }
        Repeater {
            model: [{key:"enabled",label:"Collect clipboard history"},
                {key:"includeImages",label:"Include PNG and JPEG images"},
                {key:"includeFiles",label:"Include file / URI lists"},
                {key:"persistHistory",label:"Keep history across restarts (stored on disk)"}]
            CheckBox {
                required property var modelData
                text: modelData.label
                checked: Services.Settings.data.clipboard[modelData.key]
                onClicked: Services.Settings.setValue("clipboard", modelData.key, checked)
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "History, including pins, is normally session-only. Persistence saves unencrypted clipboard data in your user storage. Turning it off removes MAGI's saved history; backups may retain it."
            color: Theme.Theme.subtext
        }
        RowLayout {
            Layout.fillWidth: true
            Label { text: "Maximum history entries"; Layout.fillWidth: true }
            SpinBox {
                from: 10; to: 200; stepSize: 10
                value: Services.Settings.data.clipboard.historyLimit
                onValueModified: Services.Settings.setValue("clipboard", "historyLimit", value)
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "Sensitive-marked copies are ignored, but apps may omit that hint. Wayland does not reliably identify the source app. Pause collection before copying private content. Images and history have additional memory limits; lowering the entry limit may unpin excess items."
            color: Theme.Theme.subtext
        }
        RowLayout {
            SettingsUI.SettingsButton {
                text: "Clear unpinned"; enabled: Services.Clipboard.ready
                onClicked: Services.Clipboard.clear()
            }
            SettingsUI.SettingsButton {
                text: root.eraseArmed ? "Confirm erase including pins" : "Erase all history…"
                enabled: Services.Clipboard.ready
                onClicked: {
                    if (root.eraseArmed) { Services.Clipboard.erase(); root.eraseArmed = false }
                    else { root.eraseArmed = true; disarm.restart() }
                }
            }
        }
        Label { visible: root.eraseArmed; text: "This also removes favourites. Click again to confirm."; color: Theme.Theme.warning }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: Services.Clipboard.error || (Services.Clipboard.monitoring ? "Collecting new copies" : "Collection paused or unavailable")
            color: Services.Clipboard.error ? Theme.Theme.warning : Theme.Theme.subtext
        }
        SettingsUI.SettingsButton { text: "Reset clipboard settings"; onClicked: Services.Settings.resetSection("clipboard") }
    }
    Timer { id: disarm; interval: 5000; onTriggered: root.eraseArmed = false }
}
