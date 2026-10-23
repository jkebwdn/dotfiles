pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../theme" as Theme
import "../../services" as Services

SettingsGallery {
    id: gallery
    objectName: "themeGallery"
    model: Theme.ThemeRegistry.themes
    currentIndex: Theme.ThemeRegistry.ids.indexOf(Services.Settings.data.appearance.theme)
    delegate: SettingsChoiceCard {
        id: card
        required property var modelData
        required property int index
        objectName: "themeChoice-" + modelData.id
        width: gallery.cardWidth
        height: gallery.cardHeight
        text: modelData.label
        activeFocusOnTab: activeFocus || selected || (gallery.currentIndex < 0 && index === 0)
        selected: gallery.currentIndex === index
        onClicked: Services.Settings.setTheme(modelData.id)
        onNavigate: delta => gallery.focusIndex(index + delta)
        onActiveFocusChanged: if (activeFocus)
            gallery.reveal(index)
        Rectangle {
            anchors.fill: parent
            color: card.modelData.roles.background
            radius: Theme.Theme.radius("action", 6, width, height)
            Rectangle {
                anchors {
                    fill: parent
                    margins: 8
                }
                color: card.modelData.roles.surface
                radius: Theme.Theme.radius("action", 5, width, height)
                Text {
                    x: 8
                    y: 5
                    text: "Aa"
                    color: card.modelData.roles.text
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }
                Row {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 8
                    }
                    spacing: 5
                    Repeater {
                        model: ["accent", "blue", "green", "red"]
                        Rectangle {
                            required property string modelData
                            width: 19
                            height: 7
                            radius: 3
                            color: card.modelData.roles[modelData]
                        }
                    }
                }
                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        margins: 8
                    }
                    width: 20
                    height: 20
                    radius: 6
                    color: card.modelData.roles.accent
                }
            }
        }
    }
}
