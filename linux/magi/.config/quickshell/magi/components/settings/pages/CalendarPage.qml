pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
Flickable {
    id: root
    contentHeight: content.implicitHeight + 48
    clip: true
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: content
        x: 24; y: 24; width: root.width - 48; spacing: 18
        Label { text: "Date & time"; font.pixelSize: 26; font.bold: true }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "Click the bar time or date to expand the calendar. Formats below apply to both the bar and its expanded header."
            color: Theme.Theme.subtext
        }
        Repeater {
            model: [{key:"firstDay",label:"First day of week",names:["System locale","Monday","Sunday"],values:["locale","monday","sunday"]},
                {key:"density",label:"Calendar spacing",names:["Compact","Comfortable"],values:["compact","comfortable"]},
                {key:"timeFormat",label:"Time format",names:["24-hour","12-hour","System locale"],values:["24h","12h","locale"]},
                {key:"dateFormat",label:"Bar date format",names:["Day / month / year","Year-month-day","System locale"],values:["numeric","iso","locale"]}]
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Label { text: parent.modelData.label; Layout.fillWidth: true }
                ComboBox {
                    readonly property var option: parent.modelData
                    model: option.names
                    currentIndex: option.values.indexOf(Services.Settings.data.calendar[option.key])
                    onActivated: Services.Settings.setValue("calendar",option.key,option.values[currentIndex])
                }
            }
        }
        CheckBox {
            text: "Show adjacent-month days"
            checked: Services.Settings.data.calendar.showAdjacentDays
            onClicked: Services.Settings.setValue("calendar","showAdjacentDays",checked)
        }
        CheckBox {
            text: "Show ISO week numbers"
            checked: Services.Settings.data.calendar.showWeekNumbers
            onClicked: Services.Settings.setValue("calendar","showWeekNumbers",checked)
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "Week numbers use the ISO week containing each row's Thursday. Reopening returns to today. Arrow keys select a day, Page Up/Down change month, and Home returns to today."
            color: Theme.Theme.subtext
        }
        SettingsUI.SettingsButton { text: "Reset date & time settings"; onClicked: Services.Settings.resetSection("calendar") }
    }
}
