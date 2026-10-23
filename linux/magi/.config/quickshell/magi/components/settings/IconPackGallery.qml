pragma ComponentBehavior: Bound
import QtQuick
import "../../icons" as Icons
import "../../services" as Services
import "../controls" as Controls

SettingsGallery {
    id: gallery
    objectName: "iconPackGallery"
    model: Icons.IconRegistry.packs
    cardWidth: 216
    cardHeight: 92
    currentIndex: model.findIndex(pack => pack.id === Services.Settings.data.icons.pack)
    delegate: SettingsChoiceCard {
        id: card
        required property var modelData
        required property int index
        objectName: "iconPackChoice-" + modelData.id
        width: gallery.cardWidth
        height: gallery.cardHeight
        text: modelData.label
        activeFocusOnTab: activeFocus || selected || (gallery.currentIndex < 0 && index === 0)
        selected: gallery.currentIndex === index
        onClicked: Services.Settings.setIconPack(modelData.id)
        onNavigate: delta => gallery.focusIndex(index + delta)
        onActiveFocusChanged: if (activeFocus)
            gallery.reveal(index)
        Row {
            anchors.centerIn: parent
            spacing: 12
            Repeater {
                model: ["wifi", "bluetooth", "volume", "battery", "settings"]
                Controls.Icon {
                    required property string modelData
                    role: modelData
                    previewPack: card.modelData.id
                    size: 26
                }
            }
        }
    }
}
