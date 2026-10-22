pragma ComponentBehavior: Bound
import QtQuick
import ".." as SettingsUI
import QtQuick.Dialogs
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
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
    description: "Palette and shape changes preview immediately."
    property int packRequest: 0
    property string packError: ""
    GridLayout {
        objectName: "themeAndIconPack"
        Layout.fillWidth: true
        columns: root.body.width >= 440 ? 2 : 1
        columnSpacing: SettingsUI.SettingsMetrics.gap
        ColumnLayout {
            Layout.fillWidth: true; Layout.minimumWidth: 0
            Label { text: "Theme"; font.bold: true }
            SettingsUI.SettingsSelector {
                Accessible.name: "Theme"
                Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.maximumWidth: Infinity
                model: Theme.ThemeRegistry.themes
                textRole: "label"
                currentIndex: Theme.ThemeRegistry.ids.indexOf(Services.Settings.data.appearance.theme)
                onActivated: index => Services.Settings.setTheme(model[index].id)
            }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.minimumWidth: 0
            Label { text: "Icon Pack"; font.bold: true }
            SettingsUI.SettingsSelector {
                objectName: "iconPackSelector"
                Accessible.name: "Icon Pack"
                Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.maximumWidth: Infinity
                model: Icons.IconRegistry.packs
                textRole: "label"
                currentIndex: model.findIndex(p => p.id === Services.Settings.data.icons.pack)
                onActivated: index => Services.Settings.setIconPack(model[index].id)
            }
        }
    }
    SettingsUI.SettingsButton { text: "Install icon pack…"; onClicked: packDialog.open() }
    SettingsUI.SettingsHelp {
        text: root.packError || (!Icons.IconRegistry.packs.some(p => p.id === Services.Settings.data.icons.pack)
            ? "Selected icon pack is unavailable; using MAGI Default." : "Shell icons follow this pack. Application icons use the system icon theme.")
    }
    RowLayout {
        Repeater {
            model: ["background", "surface", "text", "accent", "blue", "green", "yellow", "red"]
            Rectangle {
                required property string modelData
                implicitWidth: 24
                implicitHeight: 24
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
            + " of " + supportedApplications.length + " applications following MAGI"
        description: "Choose which applications follow MAGI. Expand a row for integration details."
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
                readonly property string shortStatus: pending ? "Working…" : modelData.error ? "Error"
                    : !modelData.available ? (modelData.result === "Deferred" ? "Deferred" : "Unavailable")
                    : !modelData.configured ? "Setup" : reviewing ? "Review"
                    : !modelData.enabled ? (modelData.installed ? "Paused" : "Not following")
                    : root.compactThemeResult(modelData.result)
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
    SettingsUI.SettingsButton { flat: true; text: "Reset appearance"; onClicked: Services.Settings.resetSection("appearance") }


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
