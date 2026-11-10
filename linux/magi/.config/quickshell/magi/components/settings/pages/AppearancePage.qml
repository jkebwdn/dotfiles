pragma ComponentBehavior: Bound
import QtQuick
import ".." as SettingsUI
import "../SettingsFeedback.js" as Feedback
import QtQuick.Dialogs
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../settings/SettingsSchema.js" as Schema
import "../../../theme" as Theme
import "../../../icons" as Icons
import "../../controls" as MagiControls
SettingsUI.SettingsPage {
    id: root
    onRevisited: Services.ThemeOrchestrator.refresh()
    Component.onCompleted: Services.ThemeOrchestrator.refresh()
    Keys.onEscapePressed: event => {
        if (Services.ThemeOrchestrator.plan) { Services.ThemeOrchestrator.plan = null; event.accepted = true }
        else event.accepted = false
    }
    // Presentation only: preserve complete adapter results in each disclosure.
    function needsAttention(target) {
        return !!target.error || !target.available || !target.configured
            || ["failed", "error", "unavailable", "unsupported"].includes(target.phase)
            || /failed|error|unsupported|unavailable/i.test(target.statusLabel || "")
    }
    function applicationIcon(id) {
        return ({magi:"preferences-desktop-theme",hyprland:"preferences-desktop-display",
            ghostty:"com.mitchellh.ghostty",gtk:"org.xfce.thunar",zen:"zen-browser",
            yazi:"yazi",neovim:"nvim",starship:"utilities-terminal",fastfetch:"utilities-terminal",
            btop:"btop",cava:"multimedia-volume-control","ascii-splash":"utilities-terminal"})[id] || "application-x-executable"
    }
    maximumBodyWidth: 1100
    title: "Appearance"
    description: ""
    property int packRequest: 0
    property string packError: ""
    Label { text: "Themes"; font.pixelSize: SettingsUI.SettingsMetrics.sectionSize; font.bold: true }
    SettingsUI.ThemeGallery {}
    Label { text: "Icon packs"; font.pixelSize: SettingsUI.SettingsMetrics.sectionSize; font.bold: true }
    SettingsUI.IconPackGallery {}
    SettingsUI.SettingsButton {
        objectName: "installIconPack"
        Layout.alignment: Qt.AlignHCenter
        text: "Install icon pack…"; onClicked: packDialog.open()
    }
    SettingsUI.SettingsHelp {
        visible: root.packError.length > 0 || !Icons.IconRegistry.packs.some(p => p.id === Services.Settings.data.icons.pack)
        text: root.packError || "Selected pack unavailable; using MAGI Default."
    }
    SettingsUI.RoundnessPicker {}
    SettingsUI.SettingsHelp { visible: Theme.Theme.diagnostic.length > 0; text: Theme.Theme.diagnostic; color: Theme.Theme.warning }
    SettingsUI.SettingsSection {
        id: applicationThemes
        objectName: "applicationThemesSummary"
        collapsible: true
        readonly property int attentionCount: Services.ThemeOrchestrator.targets.filter(t => root.needsAttention(t)).length
        title: "Application themes"
        description: Services.ThemeOrchestrator.error ? "Application themes need attention" : attentionCount ? attentionCount + (attentionCount === 1 ? " application needs attention" : " applications need attention") : ""
        SettingsUI.SettingsHelp {
            visible: Services.ThemeOrchestrator.busy
            text: "Updating application themes…"
        }
        Label {
            visible: Services.ThemeOrchestrator.error.length > 0
            text: Feedback.savedContext(Services.Settings.saveState) + "Could not update application themes. Review the details below and retry."; color: Theme.Theme.danger
            wrapMode: Text.Wrap; Layout.fillWidth: true
            ToolTip.visible: themeErrorHover.hovered
            ToolTip.text: Services.ThemeOrchestrator.error
            HoverHandler { id: themeErrorHover }
        }
        Repeater {
            model: Services.ThemeOrchestrator.targets
            ColumnLayout {
                id: targetRow
                required property var modelData
                property bool expanded: false
                onReviewingChanged: if (reviewing) expanded = true
                objectName: "applicationRow-" + modelData.id
                readonly property var iconPresentation: Services.LauncherIcons.resolve({name:modelData.label, icon:root.applicationIcon(modelData.id)})
                readonly property bool needsAttention: root.needsAttention(modelData)
                readonly property string shortStatus: pending ? "Working…" : modelData.error ? "Apply failed"
                    : !modelData.available ? "Unavailable" : !modelData.configured ? "Setup required"
                    : reviewing ? "Review" : !modelData.enabled ? "Disabled" : modelData.statusLabel || modelData.result
                spacing: 4
                readonly property bool reviewing: Services.ThemeOrchestrator.plan !== null
                    && Services.ThemeOrchestrator.plan.target === modelData.id
                readonly property bool pending: Services.ThemeOrchestrator.busy
                    && Services.ThemeOrchestrator.request !== null
                    && Services.ThemeOrchestrator.request.target === modelData.id
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Item {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        Image {
                            id: applicationImage
                            anchors.fill: parent
                            source: targetRow.iconPresentation.source
                            sourceSize.width: 24; sourceSize.height: 24
                            fillMode: Image.PreserveAspectFit
                        }
                        Label { anchors.centerIn: parent; visible: applicationImage.status !== Image.Ready; text: targetRow.iconPresentation.fallbackText }
                    }
                    SettingsUI.SettingsButton {
                        id: disclosure
                        objectName: "themeDetails-" + targetRow.modelData.id
                        flat: true
                        Layout.fillWidth: true; Layout.minimumWidth: 0
                        text: targetRow.modelData.label
                        Accessible.name: (targetRow.expanded ? "Hide details for " : "Details for ") + targetRow.modelData.label
                        Accessible.description: targetRow.expanded ? "Expanded" : "Collapsed"
                        onClicked: targetRow.expanded = !targetRow.expanded
                        contentItem: RowLayout {
                            spacing: 6
                            Label { text: disclosure.text; font.bold: true; Layout.maximumWidth: Math.max(0, disclosure.availableWidth - 22); elide: Text.ElideRight }
                            Label { text: targetRow.expanded ? "▾" : "▸" }
                            Item { Layout.fillWidth: true }
                        }
                    }
                    Label {
                        objectName: "themeAttention-" + targetRow.modelData.id
                        visible: targetRow.needsAttention
                        text: "!"; color: Theme.Theme.warning
                        Accessible.name: targetRow.modelData.label + " needs attention"
                        ToolTip.visible: attentionHover.hovered
                        ToolTip.text: "Open details for " + targetRow.modelData.label
                        HoverHandler { id: attentionHover }
                    }
                    SettingsUI.SettingsToggle {
                        Layout.fillWidth: false
                        Layout.preferredWidth: 34
                        objectName: "followTheme-" + targetRow.modelData.id
                        text: ""
                        Accessible.name: "Follow MAGI for " + targetRow.modelData.label
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
                }
                Label {
                    objectName: "themeSummary-" + targetRow.modelData.id
                    visible: targetRow.expanded
                    text: "Status · " + targetRow.shortStatus
                    color: targetRow.needsAttention ? Theme.Theme.warning : Theme.Theme.subtext
                    wrapMode: Text.Wrap; Layout.fillWidth: true
                }
                Label {
                    objectName: "themeStatus-" + targetRow.modelData.id
                    visible: targetRow.expanded
                    text: targetRow.pending ? "Working…" : (targetRow.modelData.error ? Feedback.savedContext(Services.Settings.saveState) + "Could not update " + targetRow.modelData.label + ". Retry below; open details for the diagnostic." : "") ||
                        (!targetRow.modelData.available ? "Unavailable — " + targetRow.modelData.reason :
                         !targetRow.modelData.configured ? "Setup required — " + targetRow.modelData.reason :
                         targetRow.reviewing ? "Confirm integration below to start following MAGI." :
                         !targetRow.modelData.enabled && !targetRow.modelData.installed ?
                            (targetRow.modelData.result === "Not enrolled" ? "Available — check Follow MAGI Theme to enroll" : targetRow.modelData.result) :
                         !targetRow.modelData.enabled ? "Integration installed — updates paused" : targetRow.modelData.result) +
                        (targetRow.modelData.publishedPalette ? " · " + targetRow.modelData.publishedPalette : "")
                    color: targetRow.modelData.error ? Theme.Theme.danger : Theme.Theme.text
                    font.pixelSize: SettingsUI.SettingsMetrics.helperSize
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap; Layout.fillWidth: true
                }
                SettingsUI.SettingsHelp {
                    objectName: "themeIntegration-" + targetRow.modelData.id
                    visible: targetRow.expanded && text.length > 0
                    text: [targetRow.modelData.boundary ? "Integration · " + targetRow.modelData.boundary : "",
                        targetRow.modelData.compatibility ? "Compatibility · " + targetRow.modelData.compatibility : "",
                        targetRow.modelData.activationDetail ? "Activation · " + targetRow.modelData.activationDetail : "",
                        targetRow.modelData.path ? "Configuration · " + targetRow.modelData.path : ""].filter(Boolean).join("\n")
                }
                SettingsUI.SettingsHelp {
                    visible: targetRow.expanded && !!targetRow.modelData.error
                    text: targetRow.modelData.error || ""
                }
                RowLayout {
                    visible: targetRow.expanded
                    SettingsUI.SettingsButton {
                        visible: targetRow.modelData.enabled && targetRow.modelData.id !== "magi"
                        flat: true
                        text: "Retry"; enabled: !Services.ThemeOrchestrator.busy
                        onClicked: Services.ThemeOrchestrator.retry(targetRow.modelData.id)
                    }
                    SettingsUI.SettingsButton {
                        visible: !targetRow.modelData.enabled && targetRow.modelData.phase !== "disabled"
                            && targetRow.modelData.id !== "magi" && !!targetRow.modelData.error
                        text: "Disable integration"; enabled: !Services.ThemeOrchestrator.busy
                        onClicked: Services.ThemeOrchestrator.disable(targetRow.modelData.id)
                    }
                }
                RowLayout {
                    visible: targetRow.expanded && targetRow.modelData.id === "zen" && targetRow.modelData.enabled
                    Layout.fillWidth: true
                    Label {
                        objectName: targetRow.modelData.id === "zen" ? "zenWorkspaceColor" : ""
                        text: "Set this Zen workspace's base colour to " + Services.ThemeOrchestrator.zenWorkspaceColor
                        wrapMode: Text.Wrap; Layout.fillWidth: true
                    }
                    SettingsUI.SettingsButton {
                        objectName: targetRow.modelData.id === "zen" ? "copyZenWorkspaceColor" : ""
                        text: "Copy"
                        enabled: !Services.ThemeOrchestrator.copyingZenColor
                        onClicked: Services.ThemeOrchestrator.copyZenWorkspaceColor()
                    }
                    Label {
                        text: Services.ThemeOrchestrator.copyMessage
                        Layout.maximumWidth: 120
                        wrapMode: Text.Wrap
                        visible: text.length > 0
                    }
                }
                SettingsUI.SettingsTextField {
                    id: profileInput
                    visible: targetRow.expanded && targetRow.modelData.id === "zen" && !targetRow.modelData.confirmedProfile
                    Layout.fillWidth: true
                    placeholderText: "Confirm the new Profile Directory from about:support"
                }
                ColumnLayout {
                    id: review
                    visible: targetRow.reviewing
                    Layout.fillWidth: true
                    onVisibleChanged: if (visible) Qt.callLater(() => {
                        root.contentY = Math.max(0, Math.min(root.contentHeight - root.height,
                            targetRow.mapToItem(root.body, 0, 0).y))
                    })
                    Label { text: "Enable " + targetRow.modelData.label + " integration?"; font.bold: true }
                    Label {
                        text: Services.ThemeOrchestrator.plan ? Services.ThemeOrchestrator.plan.boundary : ""
                        Layout.fillWidth: true; wrapMode: Text.Wrap
                    }
                    ScrollView {
                        id: reviewScroll
                        SettingsUI.ScrollInput { view: reviewScroll.contentItem }
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
                            primary: true; text: "Enable Follow MAGI Theme"; enabled: !Services.ThemeOrchestrator.busy
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
            text: Services.ThemeOrchestrator.busy ? "Checking applications…" : "Check application status"
            enabled: !Services.ThemeOrchestrator.busy
            onClicked: Services.ThemeOrchestrator.refresh()
        }
    }
    SettingsUI.SettingsSection {
        objectName: "advancedShellStyling"
        title: "Advanced shell styling"
        collapsible: true

    SettingsUI.SettingsRow {
        Label { text: "Settings navigation accent"; Layout.fillWidth: true }
        SettingsUI.SettingsSelector {
            Accessible.name: "Settings navigation accent"
            model: ["background","surface","elevated","overlay","text","subtext","muted","accent","blue","lavender","green","yellow","peach","red","teal","border"]
            currentIndex: model.indexOf(Services.Settings.data.appearance.navigationAccent)
            onActivated: Services.Settings.setValue("appearance", "navigationAccent", currentText)
        }
    }

    SettingsUI.SurfaceStyleSettings { title: "Expanded-surface borders — shared"; group: "surfaceBorders" }
    SettingsUI.SettingsHelp { text: "Border colour and width affect Hub content/selector, Control Centre, Wi-Fi and Bluetooth menus. Enable each border in its owning editor." }
    SettingsUI.SettingsSection {
        title: "Shared shell roundness"
        collapsible: false
        Label { text: "Defaults follow Master roundness."; wrapMode: Text.Wrap; Layout.fillWidth: true; color: Theme.Theme.text }
        Repeater {
            model: [
                {id:"surface",label:"Surfaces and cards — shared"},
                {id:"action",label:"Buttons and switches — shared"}]
            GridLayout {
                columns: 3
                id: radiusRow
                required property var modelData
                readonly property var setting: modelData.id === "master" ? Services.Settings.data.appearance.roundness.master
                    : Services.Settings.data.appearance.roundness.roles[modelData.id]
                Layout.fillWidth: true
                Label { text: radiusRow.modelData.label; Layout.fillWidth: true; Layout.columnSpan: 3; wrapMode: Text.Wrap }
                SettingsUI.SettingsSlider {
                    Layout.fillWidth: true
                    from: 0; to: 2; stepSize: .05
                    value: parent.setting === null ? Services.Settings.data.appearance.roundness.master : parent.setting
                    onMoved: Services.Settings.setRoundness(parent.modelData.id, value)
                }
                Label { text: parent.setting === null ? "Default" : Number(parent.setting).toFixed(2); Layout.preferredWidth: 55 }
                SettingsUI.SettingsButton {
                    actionKind: "reset"; text: "Default"; onClicked: Services.Settings.setRoundness(parent.modelData.id, parent.modelData.id === "master" ? 1 : null) }
            }
        }
    }
    SettingsUI.SettingsButton {
        actionKind: "reset"; text: "Reset shared borders"; onClicked: {
        Services.Settings.setValue("appearance","surfaceBorders", Schema.defaults().appearance.surfaceBorders)
        Services.Settings.setValue("appearance","notificationBorders", Schema.defaults().appearance.notificationBorders)
    } }

    }
    SettingsUI.SettingsButton {
        actionKind: "reset";  text: "Reset appearance"; onClicked: Services.Settings.resetSection("appearance") }


    FileDialog {
        id: packDialog
        objectName: "iconPackInstallDialog"
        title: "Install a local MAGI icon-pack manifest"
        nameFilters: ["JSON manifests (*.json)"]
        onAccepted: { root.packError = ""; root.packRequest = Services.AssetManager.importIconPack(selectedFile) }
    }
    Connections {
        target: Services.AssetManager
        function onCompleted(requestId, operation, assetId, url, error) {
            if (requestId !== root.packRequest || operation !== "icon-pack") return
            root.packError = error
            if (!error) Services.Settings.setIconPack(assetId.slice(5))
        }
    }
}
