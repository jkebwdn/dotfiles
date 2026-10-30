import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as UI
import "../../lockPresentation/LockLayout.js" as Model
import "../../lockPresentation/LockThemes.js" as Themes

UI.SettingsPage {
    id: root
    title: "Lock Screen"
    description: "Choose a composition and make it yours."
    maximumBodyWidth: 1100
    readonly property var saved: Services.Settings.data.lockScreen
    readonly property var selection: Themes.selection(saved)
    readonly property var theme: Themes.definition(selection.id)
    readonly property var layout: Model.normalize(saved)
    readonly property var colors: ({background:Theme.Theme.background.toString(),surface:Theme.Theme.surface.toString(),text:Theme.Theme.text.toString(),subtext:Theme.Theme.subtext.toString(),accent:Theme.Theme.accent.toString(),danger:Theme.Theme.red.toString(),warning:Theme.Theme.yellow.toString()})
    readonly property url wallpaperSource: {
        const shared=Services.Wallpaper.state.shared
        return shared && shared.path ? "file://"+shared.path.split("/").map(encodeURIComponent).join("/") : ""
    }
    readonly property real avatarRadius: {
        const rounding=Services.Settings.data.appearance.roundness
        const override=rounding.roles.avatar
        return Math.max(0,Math.min(48,12*(override===null ? rounding.master : override)))
    }
    function choose(id) { Services.Settings.setLockLayout(Themes.create(id, saved)) }
    function edit(key,value) { Services.Settings.setLockLayout(Themes.customize(saved,key,value)) }
    function supports(key) { return !selection.legacy && !selection.unavailable && Themes.supports(selection.id,key) }

    GridLayout {
        id: gallery;objectName:"lockThemeGallery"
        Layout.fillWidth:true;columns:Math.max(1,Math.min(4,Math.floor(width/270)));columnSpacing:12;rowSpacing:12
        Repeater {
            id: cards;model:Themes.catalogue()
            UI.SettingsChoiceCard {
                id:card
                required property var modelData
                required property int index
                objectName:"lockThemeCard-"+modelData.id
                Layout.fillWidth:true;Layout.minimumWidth:180;Layout.preferredHeight:(width-24)*9/16+86
                text:modelData.name;selected:!root.selection.legacy && !root.selection.unavailable && root.selection.id===modelData.id
                Accessible.description:modelData.description
                onClicked:root.choose(modelData.id)
                onNavigate:delta=>cards.itemAt((index+delta+cards.count)%cards.count).forceActiveFocus()
                ColumnLayout {
                    anchors.fill:parent;spacing:6
                    UI.LockThemePreview {Layout.fillWidth:true;Layout.preferredHeight:width*9/16;Layout.minimumHeight:width*9/16;Layout.maximumHeight:width*9/16;themeId:card.modelData.id;wallpaperSource:root.wallpaperSource;backgroundBlur:root.layout.effects.blur;avatarRadius:root.avatarRadius;selectedLayout:card.selected ? root.layout : null}
                    Text {Layout.fillWidth:true;text:card.modelData.description;color:Theme.Theme.subtext;font.pixelSize:11;wrapMode:Text.Wrap;maximumLineCount:2;elide:Text.ElideRight}
                }
            }
        }
    }
    UI.SettingsSection {
        title:root.selection.legacy ? "Custom (legacy)" : root.theme.name
        UI.SettingsHelp {visible:root.selection.legacy || root.selection.unavailable;text:root.selection.legacy ? "This lock screen uses an older custom layout. It is preserved until you choose a theme." : "This theme is unavailable. A safe default is shown; your saved layout is preserved until you choose a theme."}
        UI.SettingsHelp {visible:!root.selection.legacy && !root.selection.unavailable;text:root.theme.description}
        UI.LockLayoutCanvas {
            objectName:"lockThemeLivePreview"
            Layout.fillWidth:true;Layout.maximumWidth:Math.min(760,280*aspect);Layout.preferredHeight:width/aspect;Layout.alignment:Qt.AlignHCenter
            aspect:Math.max(.5,Screen.width/Math.max(1,Screen.height));layout:root.layout;palette:root.colors;interactive:false;wallpaperSource:root.wallpaperSource;avatarRadius:root.avatarRadius
        }
        UI.SettingsHelp {text:"Preview only · your session stays unlocked."}
    }
    UI.SettingsSection {
        visible:!root.selection.legacy && !root.selection.unavailable
        title:"Appearance"
        UI.SettingsToggle {objectName:"lockOption-avatar";visible:root.supports("avatar");text:"Show profile picture";checked:root.layout.elements.identity.visible;onClicked:root.edit("avatar",checked)}
        UI.SettingsSelector {objectName:"lockOption-avatarStyle";visible:root.supports("avatarStyle") && root.layout.elements.identity.visible;model:["Rounded border","Square frame"];currentIndex:["plain","frame"].indexOf(root.layout.effects.avatar);Accessible.name:"Profile picture treatment";onActivated:root.edit("avatarStyle",["plain","frame"][currentIndex])}
        UI.SettingsSelector {objectName:"lockOption-clockSize";visible:root.supports("clockSize");model:["split-corners","compact"].includes(root.selection.id) ? ["Small profile & clock","Standard profile & clock","Large profile & clock"] : ["Small clock","Standard clock","Large clock"];currentIndex:root.layout.elements.time.size<.875 ? 0 : root.layout.elements.time.size<1.075 ? 1 : 2;Accessible.name:"Clock size";onActivated:root.edit("clockSize",[.75,1,1.15][currentIndex])}
        UI.SettingsToggle {objectName:"lockOption-date";visible:root.supports("date");text:"Show date";checked:root.layout.effects.date;onClicked:root.edit("date",checked)}
        UI.SettingsSelector {objectName:"lockOption-edgeInset";visible:root.supports("edgeInset");model:["Close to edges","Balanced inset","Generous inset"];currentIndex:root.layout.elements.identity.offsetX<.04 ? 0 : root.layout.elements.identity.offsetX<.07 ? 1 : 2;Accessible.name:"Edge inset";onActivated:root.edit("edgeInset",[.03,.05,.08][currentIndex])}
        UI.SettingsToggle {objectName:"lockOption-media";visible:root.supports("media");text:"Show Now Playing title";checked:root.layout.elements.media.visible;onClicked:root.edit("media",checked)}
        UI.SettingsToggle {objectName:"lockOption-weather";visible:root.supports("weather");text:"Show cached weather";checked:root.layout.elements.weather.visible;onClicked:root.edit("weather",checked)}
        UI.SettingsToggle {objectName:"lockOption-artwork";visible:root.supports("artwork");text:"Show album artwork";checked:root.layout.effects.artwork;onClicked:root.edit("artwork",checked)}
    }
    UI.SettingsSection {
        visible:!root.selection.legacy && !root.selection.unavailable
        title:"Background & password appearance"
        UI.SettingsToggle {objectName:"lockBackgroundBlur";text:"Blur background";checked:root.layout.effects.blur;onClicked:root.edit("blur",checked)}
        UI.SettingsSelector {objectName:"lockCredentialStyle";model:["Password dots","Password line","Password segments","Password ring","Minimal password marks"];currentIndex:["dots","line","segments","ring","minimal"].indexOf(root.layout.effects.credential);Accessible.name:"Password marks";onActivated:root.edit("credential",["dots","line","segments","ring","minimal"][currentIndex])}
    }
    UI.SettingsButton {text:"Reset lock screen";flat:true;onClicked:Services.Settings.setLockLayout(Themes.create(Themes.defaultId(),null))}
}
