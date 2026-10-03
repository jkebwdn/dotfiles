pragma ComponentBehavior: Bound
import QtQuick
import ".." as SettingsUI
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../icons" as Icons
import "../../controls" as MagiControls
Flickable {
    id: root
    contentHeight: content.implicitHeight + 48
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: content
        x: 24; y: 24; width: root.width - 48
        spacing: 20
        Label { text: "Appearance"; font.pixelSize: 26; font.bold: true }
        Label { text: "Palette and shape changes preview immediately."; color: Theme.Theme.subtext }
        Label { text: "Theme"; font.bold: true }
        ComboBox {
            Layout.fillWidth: true
            model: Theme.ThemeRegistry.themes
            textRole: "label"
            currentIndex: Theme.ThemeRegistry.ids.indexOf(Services.Settings.data.appearance.theme)
            onActivated: index => Services.Settings.setTheme(model[index].id)
        }
        RowLayout {
            Repeater {
                model: ["background", "surface", "text", "accent", "blue", "green", "yellow", "red"]
                Rectangle {
                    required property string modelData
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.Theme.radiusSmall
                    color: Theme.Theme.roles[modelData]
                    border.color: Theme.Theme.border
                    border.width: 1
                    ToolTip.visible: hover.hovered
                    ToolTip.text: modelData
                    HoverHandler { id: hover }
                }
            }
        }
        Label { visible: Theme.Theme.diagnostic.length > 0; text: Theme.Theme.diagnostic; color: Theme.Theme.warning }
        Label { text: "Icon pack"; font.bold: true }
        RowLayout {
            ComboBox {
                Layout.fillWidth: true
                model: Icons.IconRegistry.packs
                textRole: "label"
                currentIndex: Math.max(0, model.findIndex(p => p.id === Services.Settings.data.icons.pack))
                onActivated: index => Services.Settings.setIconPack(model[index].id)
            }
            MagiControls.Icon { role: "wifi"; size: 24 }
            MagiControls.Icon { role: "bluetooth"; size: 24 }
            MagiControls.Icon { role: "volume"; size: 24 }
            SettingsUI.SettingsButton { text: "Default"; onClicked: Services.Settings.setIconPack("magi-legacy") }
        }
        Label {
            visible: !Icons.IconRegistry.packs.some(p => p.id === Services.Settings.data.icons.pack)
            text: "Unknown icon pack; using MAGI Legacy."
            color: Theme.Theme.warning
        }
        Label { text: "Roundness"; font.bold: true }
        Label { text: "Square (0) → reference (1) → rounder (2). Role defaults follow Master."; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.Theme.subtext }
        Repeater {
            model: [{id:"master",label:"Master"},{id:"barPill",label:"Bar pills"},
                {id:"surface",label:"Expanded surfaces"},{id:"controlTile",label:"Control Centre tiles"},
                {id:"slider",label:"Sliders"},{id:"action",label:"Buttons / actions"},{id:"avatar",label:"Avatar"}]
            RowLayout {
                id: radiusRow
                required property var modelData
                readonly property var setting: modelData.id === "master" ? Services.Settings.data.appearance.roundness.master
                    : Services.Settings.data.appearance.roundness.roles[modelData.id]
                Layout.fillWidth: true
                Label { text: radiusRow.modelData.label; Layout.preferredWidth: 155 }
                Slider {
                    Layout.fillWidth: true
                    from: 0; to: 2; stepSize: .05
                    value: parent.setting === null ? Services.Settings.data.appearance.roundness.master : parent.setting
                    onMoved: Services.Settings.setRoundness(parent.modelData.id, value)
                }
                Label { text: parent.setting === null ? "Default" : Number(parent.setting).toFixed(2); Layout.preferredWidth: 55 }
                SettingsUI.SettingsButton { text: "Default"; onClicked: Services.Settings.setRoundness(parent.modelData.id, parent.modelData.id === "master" ? 1 : null) }
            }
        }
        SettingsUI.VisualSettingsGroup {
            title: "Status and controls"
            description: "Tile shades: − lighter · 0 original palette accent · + darker. Border and background use the same accent."
            numbers: [{key:"statusIconSize",label:"Status icon size",min:16,max:28,step:1},
                {key:"tileBackgroundShade",label:"Primary tile background shade",min:-1,max:1,step:.02,shade:true},
                {key:"tileBorderShade",label:"Primary tile border shade",min:-1,max:1,step:.02,shade:true},
                {key:"tileBorderWidth",label:"Primary tile border width",min:0,max:6,step:.5},
                {key:"controlOffOpacity",label:"Off-state opacity",min:.1,max:.6,step:.05}]
            colors: [{key:"controlOn",label:"On / action colour"},{key:"controlOff",label:"Off-state colour"}]
        }
        SettingsUI.VisualSettingsGroup {
            title: "Sliders"
            numbers: [{key:"sliderBorderWidth",label:"Border width",min:0,max:5,step:.5}]
            colors: [{key:"sliderTrack",label:"Empty track"},{key:"sliderFill",label:"Fill"},{key:"sliderBorder",label:"Border"}]
        }
        SettingsUI.VisualSettingsGroup {
            title: "Profile"
            numbers: [{key:"avatarBorderWidth",label:"Avatar border",min:0,max:5,step:.5}]
        }
        SettingsUI.SettingsButton { text: "Reset appearance"; onClicked: Services.Settings.resetSection("appearance") }
    }
}
