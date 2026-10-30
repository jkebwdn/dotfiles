import QtQuick
import "../../theme" as Theme
import "../lockPresentation/LockThemes.js" as Themes
import "../lockPresentation/LockLayout.js" as Model

// Lightweight diagram of the shared theme model; no lock scenes or observers.
Item {
    id: root
    objectName:"lockThemeMini"
    property string themeId: "centered"
    property url wallpaperSource
    property bool backgroundBlur: false
    property real avatarRadius: 12
    property var selectedLayout: null
    readonly property bool compactClock: themeId==="split-corners" || themeId==="compact"
    readonly property var layout: selectedLayout || Themes.create(themeId, null)
    readonly property var boxes: ({time:{width:400,height:150,scale:1},identity:{width:124,height:124,scale:1},authentication:{width:500,height:130,scale:1},media:{width:340,height:themeId==="media" ? 180 : 28,scale:1},weather:{width:300,height:72,scale:1}})
    readonly property var positions: {
        const flow=Model.curatedPositions(layout,1600,900,boxes)
        if(flow)return flow
        return {identity:{x:48,y:36},time:{x:188,y:36},media:{x:48,y:180},weather:{x:1200,y:50},authentication:{x:1052,y:725}}
    }
    LockPreviewBackground {anchors.fill:parent;source:root.wallpaperSource;blurred:root.backgroundBlur;shade:Theme.Theme.background}
    Item {
        width:1600;height:900;scale:Math.min(root.width/width,root.height/height);transformOrigin:Item.TopLeft
        x:(root.width-width*scale)/2;y:(root.height-height*scale)/2
        Repeater {
            model:Model.ids()
            Item {
                id: module
                required property string modelData
                x:root.positions[modelData].x;y:root.positions[modelData].y
                width:root.boxes[modelData].width;height:root.boxes[modelData].height
                visible:root.layout.elements[modelData].visible
                Rectangle {visible:module.modelData==="identity";objectName:"lockThemeAvatar";width:124;height:124;radius:root.layout.effects.avatar==="frame" ? 4 : root.avatarRadius;antialiasing:true;anchors.horizontalCenter:parent.horizontalCenter;color:Theme.Theme.elevated;border.color:Theme.Theme.accent;border.width:4}
                Column {
                    visible:module.modelData==="time";width:parent.width;spacing:6
                    Text {width:parent.width;text:"09:41";height:root.compactClock ? 94 : 120;font.pixelSize:root.compactClock ? 80 : 100;color:Theme.Theme.text;horizontalAlignment:root.layout.elements.time.alignment==="left" ? Text.AlignLeft : Text.AlignHCenter}
                    Text {width:parent.width;text:"FRIDAY, 30 OCTOBER";height:root.compactClock ? 24 : 34;font.pixelSize:root.compactClock ? 20 : 28;color:Theme.Theme.subtext;horizontalAlignment:root.layout.elements.time.alignment==="left" ? Text.AlignLeft : Text.AlignHCenter}
                }
                Column {
                    visible:module.modelData==="authentication";width:parent.width;spacing:14
                    Text {width:parent.width;text:"• • • •";font.pixelSize:30;color:Theme.Theme.text;horizontalAlignment:root.themeId==="split-corners" || root.themeId==="editorial" ? Text.AlignRight : Text.AlignHCenter}
                    Text {width:parent.width;text:"ENTER PASSWORD";font.pixelSize:26;color:Theme.Theme.subtext;horizontalAlignment:root.themeId==="split-corners" || root.themeId==="editorial" ? Text.AlignRight : Text.AlignHCenter}
                    Text {width:parent.width;text:"REBOOT  |  SUSPEND";font.pixelSize:22;color:Theme.Theme.subtext;horizontalAlignment:root.themeId==="split-corners" || root.themeId==="editorial" ? Text.AlignRight : Text.AlignHCenter}
                }
                Column {
                    visible:module.modelData==="media";width:parent.width;spacing:14
                    Rectangle {visible:root.themeId==="media";width:100;height:100;anchors.horizontalCenter:parent.horizontalCenter;radius:12;color:Theme.Theme.accent;opacity:.55}
                    Text {text:"♫  Morning light";width:parent.width;font.pixelSize:26;color:Theme.Theme.text;horizontalAlignment:root.themeId==="split-corners" ? Text.AlignLeft : Text.AlignHCenter}
                }
            }
        }
    }
}
