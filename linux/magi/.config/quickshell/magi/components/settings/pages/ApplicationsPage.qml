pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as UI
import "../../../settings/SettingsSchema.js" as Schema
UI.SettingsPage {
    id: root
    title: "Transparency & blur"
    readonly property var policy: Services.Settings.data.applicationAppearance
    function edit(key,value) { Services.Settings.setValue("applicationAppearance",key,value) }
    GridLayout {
        Layout.fillWidth: true; columns: width >= 580 ? 2 : 1
        columnSpacing: UI.SettingsMetrics.sectionGap; rowSpacing: UI.SettingsMetrics.sectionGap
        UI.ApplicationAppearancePreview {
            objectName: "applicationPreview"
            Layout.fillWidth: true; Layout.minimumWidth: 240; Layout.preferredWidth: 360; Layout.alignment: Qt.AlignTop
            backgroundOpacity: root.policy.managed ? root.policy.backgroundOpacity : 1
            blurEnabled: root.policy.blurEnabled
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.minimumWidth: 260; Layout.alignment: Qt.AlignTop; spacing: 12
            UI.SettingsToggle {
                objectName: "applicationManaged"; Layout.fillWidth: true
                text: "Use shared appearance"; checked: root.policy.managed
                Accessible.name: "Manage shell and supported application backgrounds"
                onClicked: root.edit("managed",checked)
            }
            UI.SettingsRow {
                Label { text: "Background opacity"; Layout.fillWidth: true }
                Label { text: Math.round(root.policy.backgroundOpacity*100)+"%"; color: Theme.Theme.subtext }
            }
            UI.SettingsSlider {
                objectName: "applicationOpacity"; Layout.fillWidth: true; enabled: root.policy.managed
                from: 50; to: 100; stepSize: 1; value: Math.round(root.policy.backgroundOpacity*100)
                Accessible.name: "Background opacity, "+Math.round(value)+" percent"
                onMoved: root.edit("backgroundOpacity",value/100)
            }
            UI.SettingsToggle {
                objectName: "applicationBlur"; Layout.fillWidth: true; enabled: root.policy.managed
                text: "Blur behind backgrounds"; checked: root.policy.blurEnabled
                onClicked: root.edit("blurEnabled",checked)
            }
            UI.SettingsHelp { text: "For the Bar, MAGI menus and supported applications. Text and content stay opaque." }
            UI.SettingsHelp { text: "Wallpaper and lock-screen styling stay separate." }
            UI.SettingsHelp { text: Services.ApplicationAppearanceService.active ? ({"released":"Using individual defaults","reload-required":"Reload Ghostty to finish","reload_requested":"Ghostty reload requested","next_launch":"Ready for next launch","reload_required":"Reload independent Ghostty instances","error":"Could not apply appearance"})[Services.ApplicationAppearanceService.status] || "" : "Preview only · native review pending" }
        }
    }
    UI.SettingsSection {
        id: globalBlurSection
        objectName: "globalBlurSettings"
        title: "Global blur"
        collapsible: true
        readonly property var policy: Services.Settings.data.appearance.globalBlur
        function edit(key, value) {
            const next = Object.assign({}, policy)
            next[key] = value
            Services.Settings.setValue("appearance", "globalBlur", next)
        }
        UI.SettingsHelp { text: "Affects all blurred desktop surfaces, including applications and shell panels." }
        UI.SettingsToggle {
            objectName: "globalBlurManaged"; Layout.fillWidth: true
            text: "Customize global blur"; checked: globalBlurSection.policy.managed
            onClicked: globalBlurSection.edit("managed", checked)
        }
        UI.SettingsRow {
            Label { text: "Amount"; Layout.fillWidth: true }
            Label { text: globalBlurSection.policy.size; color: Theme.Theme.subtext }
        }
        UI.SettingsSlider {
            objectName: "globalBlurAmount"; Layout.fillWidth: true
            enabled: globalBlurSection.policy.managed
            from: 1; to: 40; stepSize: 1; value: globalBlurSection.policy.size
            Accessible.name: "Global blur amount, " + value + " of 40"
            onMoved: globalBlurSection.edit("size", Math.round(value))
        }
        UI.SettingsRow {
            Label { text: "Subtle"; color: Theme.Theme.subtext }
            Item { Layout.fillWidth: true }
            Label { text: "Strong"; color: Theme.Theme.subtext }
        }
        UI.SettingsHelp { text: "Turning this off restores your desktop’s configured amount. Blur passes and which surfaces use blur stay unchanged." }
        UI.SettingsHelp {
            text: Services.GlobalBlurService.status === "error" ? "Could not apply global blur"
                : Services.GlobalBlurService.status === "applied" ? "Applied" : "Using desktop defaults"
        }
        UI.SettingsHelp { visible: Services.GlobalBlurService.error.length > 0; text: Services.GlobalBlurService.error }
        UI.SettingsButton {
            actionKind: "reset"; text: "Reset global blur"
            onClicked: Services.Settings.setValue("appearance", "globalBlur", Schema.defaults().appearance.globalBlur)
        }
    }

    UI.SettingsSection {
        objectName: "applicationSupport"; title: "Application support"; collapsible: true
        UI.SettingsHelp { text: "MAGI panels update immediately. Ghostty background changes need a configuration reload." }
        Repeater {
            model: [
                {name:"Ghostty",status:Services.ThemeOrchestrator.targets.find(t => t.id === "ghostty")?.statusLabel || "Applies next launch",detail:"Native background alpha. Safe reload is requested for the running application owner; independent instances may need Reload Configuration. Coloured cells remain opaque."},
                {name:"Zen",status:"Partial · deferred",detail:"Chrome transparency exists on Linux. Current workspace styling needs verification; webpage content is unchanged."},
                {name:"GTK / Thunar",status:"Deferred",detail:"Views, toolbars and dialogs need coherent transparency. Existing appearance is preserved."},
                {name:"Neovim / btop",status:"Via Ghostty",detail:"Base backgrounds inherit the terminal. Floating panels and deliberate coloured backgrounds remain opaque."},
                {name:"Yazi / yatline",status:"Partial · via Ghostty",detail:"Default-background areas inherit; explicit cell backgrounds remain intentional."},
                {name:"Starship / Fastfetch",status:"Via Ghostty",detail:"Terminal output; no independent transparency adapter."}
            ]
            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true; spacing: 4
                UI.SettingsRow { Label { text: modelData.name; Layout.fillWidth: true } Label { text: modelData.status; color: Theme.Theme.subtext } }
                UI.SettingsHelp { text: modelData.detail }
            }
        }
    }
    UI.SettingsSection {
        objectName: "applicationAdvanced"; title: "Details"; collapsible: true
        UI.SettingsHelp { text: "Unsupported applications stay unchanged. Only painted panel backgrounds use transparency; controls and content keep their colour. The preview illustrates intent." }
        UI.SettingsHelp { text: "Turning shared appearance off restores individual panel backgrounds and removes the Ghostty override. Reload Ghostty to restore its own configured opacity." }
        UI.SettingsHelp { visible: Services.ApplicationAppearanceService.error.length>0; text: Services.ApplicationAppearanceService.error }
    }
    UI.SettingsButton { actionKind: "reset"; text: "Reset shared appearance"; onClicked: Services.Settings.resetSection("applicationAppearance") }
}
