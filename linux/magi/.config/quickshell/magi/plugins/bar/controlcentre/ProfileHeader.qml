import QtQuick
import QtQuick.Layouts
import "../../../components/controls" as Controls
import "../../../components/controls/VisualState.js" as VisualState
import "../../../services" as Services
import "../../../theme" as Theme

Rectangle {
    id: root
    color: Services.Settings.data.appearance.profileBackground.enabled ? Theme.Theme.roles[Services.Settings.data.appearance.profileBackground.role] : "transparent"
    radius: Theme.Theme.radius("controlTile", 10, width, height)
    objectName: "runtimeProfile"
    readonly property int contentPadding: Services.Settings.data.appearance.profileBackground.enabled ? 10 : 0
    implicitHeight: Math.max(Theme.RenderTokens.avatarSize, profileText.implicitHeight) + contentPadding * 2
    property string weatherSummary: Services.Weather.summary
    property bool preview: false
    property var profile: Services.Settings.data.profile
    property int localHour: new Date().getHours()
    Timer { interval: 60000; repeat: true; running: !root.preview; onTriggered: root.localHour = new Date().getHours() }
    RowLayout {
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: 14
        Controls.RoundedArtwork {
            objectName: "runtimeAvatar"
            Layout.preferredWidth: Theme.RenderTokens.avatarSize
            Layout.preferredHeight: Theme.RenderTokens.avatarSize
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.Theme.radius("avatar", 10, width, height)
            borderWidth: Theme.Theme.visual.avatarBorderWidth
            source: Services.AssetManager.assetUrl(root.profile.avatar)
            placeholder: "profile"
        }
        ColumnLayout {
            id: profileText
            Layout.fillHeight: false
            objectName: "profileTextStack"
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2
            Text {
                Layout.fillWidth: true
                objectName: "profileGreeting"
                text: VisualState.greeting(root.localHour, root.profile.greetingStyle, root.profile.displayName)
                color: Theme.Theme.text
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.visual.profileGreetingSize
                font.weight: Theme.Theme.visual.profileGreetingWeight
                elide: Text.ElideRight
                visible: text.length > 0
            }
            Text {
                Layout.fillWidth: true
                objectName: "profileWeather"
                text: root.weatherSummary || "Weather unavailable"
                color: Theme.Theme.subtext
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.visual.profileWeatherSize
                font.weight: Theme.Theme.visual.profileWeatherWeight
                elide: Text.ElideRight
                visible: text.length > 0
            }
            Text {
                objectName: "profileThirdLine"
                Layout.fillWidth: true
                visible: root.profile.subtitleMode === "custom" && text.length > 0
                text: root.profile.subtitle
                color: Theme.Theme.subtext
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.visual.profileThirdLineSize
                font.weight: Theme.Theme.visual.profileThirdLineWeight
                elide: Text.ElideRight
            }
        }
    }
}
