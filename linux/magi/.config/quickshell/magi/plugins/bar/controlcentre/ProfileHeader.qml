import QtQuick
import QtQuick.Layouts
import "../../../components/controls" as Controls
import "../../../components/controls/VisualState.js" as VisualState
import "../../../services" as Services
import "../../../theme" as Theme

Item {
    id: root
    objectName: "runtimeProfile"
    implicitHeight: Math.max(Theme.RenderTokens.profileHeight, profileText.implicitHeight)
    // Future provider supplies a summary; no location or forecast is fabricated.
    property string weatherSummary: ""
    readonly property var profile: Services.Settings.data.profile
    property int localHour: new Date().getHours()
    Timer { interval: 60000; repeat: true; running: true; onTriggered: root.localHour = new Date().getHours() }
    RowLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 14
        Controls.RoundedArtwork {
            objectName: "runtimeAvatar"
            Layout.preferredWidth: Theme.RenderTokens.avatarSize
            Layout.preferredHeight: Theme.RenderTokens.avatarSize
            radius: Theme.Theme.radius("avatar", 10, width, height)
            borderWidth: Theme.Theme.visual.avatarBorderWidth
            source: Services.AssetManager.assetUrl(root.profile.avatar)
            placeholder: "profile"
        }
        ColumnLayout {
            id: profileText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2
            Text {
                Layout.fillWidth: true
                objectName: "profileGreeting"
                text: VisualState.greeting(root.localHour) + (root.profile.displayName ? " " + root.profile.displayName : "")
                color: Theme.Theme.text
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.visual.profileGreetingSize
                font.bold: true
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
                elide: Text.ElideRight
            }
        }
    }
}
