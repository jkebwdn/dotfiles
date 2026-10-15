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
    Component.onCompleted: Services.ThemeOrchestrator.refresh()
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
        Label { text: "System Theme"; font.bold: true }
        Label {
            text: Services.ThemeOrchestrator.summary || "External targets are opt-in. Review each integration before enabling Follow MAGI Theme."
            color: Theme.Theme.subtext; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
        Label {
            visible: Services.ThemeOrchestrator.error.length > 0
            text: Services.ThemeOrchestrator.error; color: Theme.Theme.danger
            wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
        Repeater {
            model: Services.ThemeOrchestrator.targets
            ColumnLayout {
                id: targetRow
                required property var modelData
                readonly property bool reviewing: Services.ThemeOrchestrator.plan !== null
                    && Services.ThemeOrchestrator.plan.target === modelData.id
                readonly property bool pending: Services.ThemeOrchestrator.busy
                    && Services.ThemeOrchestrator.request !== null
                    && Services.ThemeOrchestrator.request.target === modelData.id
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: targetRow.modelData.label; Layout.fillWidth: true }
                    CheckBox {
                        objectName: "followTheme-" + targetRow.modelData.id
                        text: "Follow MAGI Theme"
                        checked: targetRow.modelData.enabled || targetRow.reviewing || (targetRow.pending
                            && ["plan", "enable", "resume"].indexOf(Services.ThemeOrchestrator.request.op) >= 0)
                        enabled: !Services.ThemeOrchestrator.busy && targetRow.modelData.id !== "magi"
                            && targetRow.modelData.available
                        onClicked: {
                            if (targetRow.reviewing) Services.ThemeOrchestrator.plan = null
                            else if (targetRow.modelData.enabled) Services.ThemeOrchestrator.disable(targetRow.modelData.id)
                            else if (targetRow.modelData.id === "zen" && !targetRow.modelData.confirmedProfile)
                                Services.ThemeOrchestrator.preview("zen", profileInput.text)
                            else Services.ThemeOrchestrator.follow(targetRow.modelData.id)
                            checked = Qt.binding(() => targetRow.modelData.enabled || targetRow.reviewing
                                || (targetRow.pending && ["plan", "enable", "resume"].indexOf(Services.ThemeOrchestrator.request.op) >= 0))
                        }
                    }
                    SettingsUI.SettingsButton {
                        visible: targetRow.modelData.enabled && targetRow.modelData.id !== "magi"
                        text: "Retry"; enabled: !Services.ThemeOrchestrator.busy
                        onClicked: Services.ThemeOrchestrator.retry(targetRow.modelData.id)
                    }
                    SettingsUI.SettingsButton {
                        visible: !targetRow.modelData.enabled && targetRow.modelData.phase !== "disabled"
                            && targetRow.modelData.id !== "magi" && !!targetRow.modelData.error
                        text: "Remove hooks"; enabled: !Services.ThemeOrchestrator.busy
                        onClicked: Services.ThemeOrchestrator.disable(targetRow.modelData.id)
                    }
                }
                Label {
                    objectName: "themeStatus-" + targetRow.modelData.id
                    text: targetRow.pending ? "Working…" : targetRow.modelData.error ||
                        (!targetRow.modelData.available ? "Unavailable — " + targetRow.modelData.reason :
                         !targetRow.modelData.configured ? "Setup required — " + targetRow.modelData.reason :
                         targetRow.reviewing ? "Confirm integration below to start following MAGI." :
                         !targetRow.modelData.enabled && !targetRow.modelData.installed ?
                            (targetRow.modelData.result === "Not enrolled" ? "Available — check Follow MAGI Theme to enroll" : targetRow.modelData.result) :
                         !targetRow.modelData.enabled ? "Integration installed — updates paused" : targetRow.modelData.result) +
                        (targetRow.modelData.publishedPalette ? " · " + targetRow.modelData.publishedPalette : "")
                    color: targetRow.modelData.error ? Theme.Theme.danger :
                        !targetRow.modelData.available ? Theme.Theme.muted :
                        targetRow.modelData.enabled ? Theme.Theme.text : Theme.Theme.accent
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
                RowLayout {
                    visible: targetRow.modelData.id === "zen" && targetRow.modelData.enabled
                    Layout.fillWidth: true
                    Label {
                        objectName: targetRow.modelData.id === "zen" ? "zenWorkspaceColor" : ""
                        text: "Set this Zen workspace's base colour to " + Services.ThemeOrchestrator.zenWorkspaceColor
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }
                    SettingsUI.SettingsButton {
                        objectName: targetRow.modelData.id === "zen" ? "copyZenWorkspaceColor" : ""
                        text: "Copy"
                        enabled: !Services.ThemeOrchestrator.copyingZenColor
                        onClicked: Services.ThemeOrchestrator.copyZenWorkspaceColor()
                    }
                    Label {
                        text: Services.ThemeOrchestrator.copyMessage
                        visible: text.length > 0
                    }
                }
                TextField {
                    id: profileInput
                    visible: targetRow.modelData.id === "zen" && !targetRow.modelData.confirmedProfile
                    Layout.fillWidth: true
                    placeholderText: "Confirm the new Profile Directory from about:support"
                }
                ColumnLayout {
                    id: review
                    visible: targetRow.reviewing
                    Layout.fillWidth: true
                    onVisibleChanged: if (visible) Qt.callLater(() => {
                        root.contentY = Math.max(0, Math.min(root.contentHeight - root.height,
                            targetRow.mapToItem(content, 0, 0).y))
                    })
                    Label { text: "Enable " + targetRow.modelData.label + " integration?"; font.bold: true }
                    Label {
                        text: Services.ThemeOrchestrator.plan ? Services.ThemeOrchestrator.plan.boundary : ""
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    ScrollView {
                        Layout.fillWidth: true; Layout.preferredHeight: 140
                        TextArea {
                            readOnly: true; wrapMode: TextEdit.Wrap
                            text: targetRow.reviewing ? Services.ThemeOrchestrator.plan.edits.map(e => e.diff).join("\n") : ""
                            font.family: "monospace"; font.pixelSize: 11
                        }
                    }
                    RowLayout {
                        SettingsUI.SettingsButton {
                            objectName: "confirmTheme-" + targetRow.modelData.id
                            text: "Enable Follow MAGI Theme"; enabled: !Services.ThemeOrchestrator.busy
                            onClicked: Services.ThemeOrchestrator.enable()
                        }
                        SettingsUI.SettingsButton {
                            objectName: "cancelTheme-" + targetRow.modelData.id
                            text: "Cancel"; onClicked: Services.ThemeOrchestrator.plan = null
                        }
                    }
                }
            }
        }
        SettingsUI.SettingsButton {
            text: Services.ThemeOrchestrator.busy ? "Updating targets…" : "Refresh targets"
            enabled: !Services.ThemeOrchestrator.busy
            onClicked: Services.ThemeOrchestrator.refresh()
        }
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
                {key:"tileBorderWidth",label:"Primary tile border width",min:0,max:6,step:.5}]
        }
        SettingsUI.VisualSettingsGroup {
            title: "Primary icon states"
            numbers: [{key:"controlOffShade",label:"Off shade",min:-1,max:1,step:.02,shade:true},
                {key:"controlOffOpacity",label:"Off strength",min:0,max:1,step:.05}]
            colors: [{key:"controlOn",label:"On role"},{key:"controlOff",label:"Off role"}]
        }
        SettingsUI.VisualSettingsGroup {
            title: "Secondary icon states"
            numbers: [{key:"secondaryOffShade",label:"Off shade",min:-1,max:1,step:.02,shade:true},
                {key:"secondaryOffOpacity",label:"Off strength",min:0,max:1,step:.05}]
            colors: [{key:"secondaryOn",label:"On role"},{key:"secondaryOff",label:"Off role"}]
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
