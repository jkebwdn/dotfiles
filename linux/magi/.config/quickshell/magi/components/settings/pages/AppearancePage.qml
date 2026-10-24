pragma ComponentBehavior: Bound
import QtQuick
import ".." as SettingsUI
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
    // Presentation only: retain the complete adapter result in expandable details.
    function compactThemeResult(result) {
        const text = (result || "").toLowerCase()
        if (/manual/.test(text)) return "Manual step"
        if (/next prompt|new shell/.test(text)) return "New shell"
        if (/next launch/.test(text) && !/^reload/.test(text)) return "Next launch"
        if (/relaunch/.test(text)) return "Relaunch"
        if (/reload/.test(text)) return "Reload"
        if (/restart/.test(text)) return "Restart"
        if (/^applied|runtime update accepted/.test(text)) return "Applied"
        // Unknown future adapter wording stays available in details, never in the narrow column.
        return "Details"
    }
    title: "Appearance"
    description: ""
    property int packRequest: 0
    property string packError: ""
    Label { text: "Theme"; font.pixelSize: SettingsUI.SettingsMetrics.sectionSize; font.bold: true }
    SettingsUI.ThemeGallery {}
    RowLayout {
        Layout.fillWidth: true
        Label { text: "Icon Pack"; font.pixelSize: SettingsUI.SettingsMetrics.sectionSize; font.bold: true; Layout.fillWidth: true }
        SettingsUI.SettingsButton { text: "Install icon pack…"; onClicked: packDialog.open() }
    }
    SettingsUI.IconPackGallery {}
    SettingsUI.SettingsHelp {
        visible: root.packError.length > 0 || !Icons.IconRegistry.packs.some(p => p.id === Services.Settings.data.icons.pack)
        text: root.packError || "Selected pack unavailable; using MAGI Default."
    }
    SettingsUI.RoundnessPicker {}
    SettingsUI.SettingsHelp { visible: Theme.Theme.diagnostic.length > 0; text: Theme.Theme.diagnostic; color: Theme.Theme.warning }
    SettingsUI.SettingsHelp {
        objectName: "applicationThemeAttention"
        text: Services.ThemeOrchestrator.error || (Services.ThemeOrchestrator.targets.some(t => !!t.error || (t.enabled && /manual/i.test(t.result || "")))
            ? "Application themes need attention · expand below for errors or manual steps." : "")
        visible: text.length > 0
        color: Theme.Theme.warning
    }
    SettingsUI.SettingsSection {
        id: applicationThemes
        objectName: "applicationThemesSummary"
        collapsible: true
        readonly property var supportedApplications: Services.ThemeOrchestrator.targets.filter(t => t.id !== "magi" && t.available)
        title: "Application themes · " + supportedApplications.filter(t => t.enabled).length
            + " of " + supportedApplications.length + " following MAGI"
        description: supportedApplications.filter(t => t.enabled && t.statusLabel === "Applies next launch").length
            + " next launch · " + supportedApplications.filter(t => t.enabled && t.statusLabel === "Restart required").length + " restart required"
        SettingsUI.SettingsHelp {
            visible: Services.ThemeOrchestrator.busy
            text: Services.ThemeOrchestrator.summary
        }
        Label {
            visible: Services.ThemeOrchestrator.error.length > 0
            text: Services.ThemeOrchestrator.error; color: Theme.Theme.danger
            wrapMode: Text.Wrap; Layout.fillWidth: true
        }
        Repeater {
            model: Services.ThemeOrchestrator.targets
            ColumnLayout {
                id: targetRow
                required property var modelData
                property bool expanded: false
                readonly property bool needsAttention: !!modelData.error || reviewing
                    || (modelData.available && !modelData.configured)
                    || (modelData.enabled && /manual/i.test(modelData.result || ""))
                readonly property string shortStatus: pending ? "Working…" : modelData.error ? "Apply failed"
                    : !modelData.available ? (modelData.result === "Deferred" ? "Deferred" : "Unavailable")
                    : !modelData.configured ? "Setup" : reviewing ? "Review"
                    : !modelData.enabled ? (modelData.installed ? "Paused" : "Not following")
                    : modelData.statusLabel || root.compactThemeResult(modelData.result)
                spacing: 4
                readonly property bool reviewing: Services.ThemeOrchestrator.plan !== null
                    && Services.ThemeOrchestrator.plan.target === modelData.id
                readonly property bool pending: Services.ThemeOrchestrator.busy
                    && Services.ThemeOrchestrator.request !== null
                    && Services.ThemeOrchestrator.request.target === modelData.id
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: targetRow.modelData.label; font.bold: true; Layout.fillWidth: true; Layout.minimumWidth: 75; elide: Text.ElideRight }
                    SettingsUI.SettingsToggle {
                        Layout.fillWidth: false
                        Layout.preferredWidth: 135
                        objectName: "followTheme-" + targetRow.modelData.id
                        text: "Follow MAGI"
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
                    Label {
                        objectName: "themeSummary-" + targetRow.modelData.id
                        text: targetRow.shortStatus
                        Layout.preferredWidth: 110
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                        font.pixelSize: SettingsUI.SettingsMetrics.helperSize
                        color: targetRow.modelData.error ? Theme.Theme.danger : Theme.Theme.text
                    }
                    SettingsUI.SettingsButton {
                        objectName: "themeDetails-" + targetRow.modelData.id
                        flat: true; text: targetRow.expanded ? "▾" : "▸"
                        implicitWidth: 28; leftPadding: 4; rightPadding: 4
                        Accessible.name: "Details for " + targetRow.modelData.label
                        Accessible.description: targetRow.modelData.reason || targetRow.modelData.result
                        onClicked: targetRow.expanded = !targetRow.expanded
                    }
                }
                Label {
                    objectName: "themeStatus-" + targetRow.modelData.id
                    visible: targetRow.expanded || targetRow.needsAttention
                    text: targetRow.pending ? "Working…" : targetRow.modelData.error ||
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
                RowLayout {
                    visible: targetRow.expanded || !!targetRow.modelData.error
                    SettingsUI.SettingsButton {
                        visible: targetRow.modelData.enabled && targetRow.modelData.id !== "magi"
                        flat: true
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
                RowLayout {
                    visible: targetRow.modelData.id === "zen" && targetRow.modelData.enabled
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
            text: Services.ThemeOrchestrator.busy ? "Updating targets…" : "Refresh targets"
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
