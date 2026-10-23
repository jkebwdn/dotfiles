pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
SettingsUI.SettingsPage {
    id: root
    title: "Date & time"
    description: "Formats apply to the Bar and calendar."
    Repeater {
        model: [{key:"firstDay",label:"First day of week",names:["System locale","Monday","Sunday"],values:["locale","monday","sunday"]},
            {key:"density",label:"Calendar spacing",names:["Compact","Comfortable"],values:["compact","comfortable"]},
            {key:"timeFormat",label:"Time format",names:["24-hour","12-hour","System locale"],values:["24h","12h","locale"]},
            {key:"dateFormat",label:"Bar date format",names:["Day / month / year","Year-month-day","System locale"],values:["numeric","iso","locale"]}]
        SettingsUI.SettingsRow {
            required property var modelData
            Layout.fillWidth: true
            Label { text: parent.modelData.label; Layout.fillWidth: true; wrapMode: Text.Wrap }
            SettingsUI.SettingsSelector {
                readonly property var option: parent.modelData
                Accessible.name: option.label
                model: option.names
                currentIndex: option.values.indexOf(Services.Settings.data.calendar[option.key])
                onActivated: Services.Settings.setValue("calendar",option.key,option.values[currentIndex])
            }
        }
    }
    SettingsUI.SettingsToggle {
        text: "Show adjacent-month days"
        checked: Services.Settings.data.calendar.showAdjacentDays
        onClicked: Services.Settings.setValue("calendar","showAdjacentDays",checked)
    }
    SettingsUI.SettingsToggle {
        text: "Show ISO week numbers"
        checked: Services.Settings.data.calendar.showWeekNumbers
        onClicked: Services.Settings.setValue("calendar","showWeekNumbers",checked)
    }
    Label {
        Layout.fillWidth: true; wrapMode: Text.Wrap
        text: "Calendar: arrows select a day; Page Up/Down changes month; Home returns to today."
        color: Theme.Theme.text
    }
    SettingsUI.SettingsButton {
        actionKind: "reset";  text: "Reset date & time settings"; onClicked: Services.Settings.resetSection("calendar") }

}
