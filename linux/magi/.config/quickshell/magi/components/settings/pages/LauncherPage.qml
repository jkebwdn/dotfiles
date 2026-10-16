pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
SettingsUI.SettingsPage {
    id: root
    onRevisited: Services.Launcher.refresh()
    Component.onCompleted: Services.Launcher.refresh()
    title: "Application Launcher"
    description: "SUPER + SPACE · Search installed applications"
    SettingsUI.SettingsSection {
        title: "Presentation"
        Repeater {
            model: [{key:"enabled",label:"Enable launcher"}, {key:"showIcons",label:"Show application icons"},
                {key:"showLabels",label:"Show names"}, {key:"showSubtitles",label:"Show descriptions in list mode"}]
            SettingsUI.SettingsToggle {
                required property var modelData
                text: modelData.label; checked: Services.Settings.data.launcher[modelData.key]
                onClicked: Services.Settings.setValue("launcher", modelData.key, checked)
            }
        }
        Repeater {
            model: [{key:"layout",label:"Layout",values:["list","grid"]},
                {key:"position",label:"Panel position",values:["center","top"]}]
            SettingsUI.SettingsRow {
                required property var modelData
                Layout.fillWidth: true
                Label { text: parent.modelData.label; Layout.fillWidth: true; wrapMode: Text.Wrap }
                SettingsUI.SettingsSelector {
                    id: choice
                    readonly property var option: parent.modelData
                    Accessible.name: option.label
                    model: option.values
                    currentIndex: option.values.indexOf(Services.Settings.data.launcher[option.key])
                    onActivated: Services.Settings.setValue("launcher", option.key, option.values[currentIndex])
                }
            }
        }
    }
    SettingsUI.SettingsSection {
        title: "Dimensions"
        description: "List and grid sizes are configured independently."
        Repeater {
            model: [{key:"panelWidth",label:"List width",min:320,max:800}, {key:"gridWidth",label:"Grid width",min:420,max:1200},
                {key:"rowHeight",label:"List row height",min:40,max:96}, {key:"iconSize",label:"Icon size",min:20,max:64},
                {key:"visibleRows",label:"Visible rows (grid up to 3)",min:3,max:12}, {key:"gridColumns",label:"Grid columns",min:3,max:8}]
            SettingsUI.SettingsRow {
                required property var modelData
                Layout.fillWidth: true
                Label { text: parent.modelData.label; Layout.fillWidth: true; wrapMode: Text.Wrap }
                SettingsUI.SettingsNumber {
                    readonly property var option: parent.modelData
                Accessible.name: option.label
                    from: option.min; to: option.max
                    value: Services.Settings.data.launcher[option.key]
                    onValueModified: Services.Settings.setValue("launcher", option.key, value)
                }
            }
        }
    }
    SettingsUI.SettingsSection {
        title: "Artwork"
        description: "Local images for the launcher header and background."
        Repeater {
            model: [{key:"headerEnabled",label:"Show header image"}, {key:"backgroundEnabled",label:"Show background image"}]
            SettingsUI.SettingsToggle {
                required property var modelData
                text: modelData.label; checked: Services.Settings.data.launcher[modelData.key]
                onClicked: Services.Settings.setValue("launcher", modelData.key, checked)
            }
        }
        SettingsUI.SettingsRow {
            Label { text: "Header position"; Layout.fillWidth: true }
            SettingsUI.SettingsSelector {
                model: ["top", "bottom"]
                currentIndex: model.indexOf(Services.Settings.data.launcher.headerPosition)
                onActivated: Services.Settings.setValue("launcher", "headerPosition", model[currentIndex])
            }
        }
        Repeater {
            model: [{key:"headerImage",label:"Header image — absolute local path"}, {key:"backgroundImage",label:"Background image — absolute local path"}]
            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                SettingsUI.SettingsHelp { text: parent.modelData.label }
                SettingsUI.SettingsTextField {
                    readonly property string settingKey: parent.modelData.key
                    Layout.fillWidth: true; placeholderText: "/home/…/image.png"
                    text: Services.Settings.data.launcher[settingKey]
                    onEditingFinished: Services.Settings.setValue("launcher", settingKey, text.trim())
                }
            }
        }
    }
    SettingsUI.SettingsSection {
        title: "Hidden applications"
        Label {
            Layout.fillWidth: true; wrapMode: Text.Wrap
            text: "Right-click an application in the launcher to hide it. Hidden applications stay out of search in both layouts."
            color: Theme.Theme.text
        }
        Label {
            visible: Services.Launcher.hiddenApplications.length === 0
            text: "No hidden applications"; color: Theme.Theme.text
        }
        Repeater {
            model: Services.Launcher.hiddenApplications
            RowLayout {
                id: hiddenRow
                required property var modelData
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                        text: hiddenRow.modelData.name
                    }
                    Label {
                        visible: !!hiddenRow.modelData.unavailable
                        text: "Not currently available"; color: Theme.Theme.text
                    }
                }
                SettingsUI.SettingsButton {
                    text: "Restore"
                    Accessible.name: "Restore " + hiddenRow.modelData.name
                    onClicked: Services.Launcher.restore(hiddenRow.modelData.id)
                }
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.Wrap
            text: "Resetting launcher settings also restores all hidden applications."
            color: Theme.Theme.text
        }
    }
    SettingsUI.SettingsButton { flat: true; text: "Reset launcher settings and restore hidden apps"; onClicked: Services.Settings.resetSection("launcher") }

}
