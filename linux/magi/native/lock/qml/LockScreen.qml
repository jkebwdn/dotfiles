import QtQuick
import "LockLayout.js" as Layout
Item {
    id: root
    property string outputLabel: ""
    property string nativeState: "Acquiring"
    property string developmentNotice: ""
    property int characterCount: 0
    property bool inputActive: false
    property bool capsLock: false
    property bool capsKnown: true
    property string fingerprintStatus: ""
    property string authStatus: "Locked"
    property var visual: ({})
    property string timeLabel: ""
    property string dateLabel: ""
    property bool wallpaperAvailable: false
    property bool avatarAvailable: false
    LockTokens { id: design; palette: root.visual; artworkAvailable: root.wallpaperAvailable; logicalWidth: root.width; logicalHeight: root.height }
    LockBackground { anchors.fill: parent; tokens: design; artworkAvailable: root.wallpaperAvailable }
    readonly property var layout: Layout.normalize(visual.lockScreen)
    readonly property var elementBoxes: ({time:timeHost, identity:identityHost, authentication:authHost})
    Item {
        id: plane
        width: root.width / design.visualScale; height: root.height / design.visualScale
        scale: design.visualScale; transformOrigin: Item.TopLeft
        readonly property real frameWidth: Math.min(600, (root.width-32)/scale)
        readonly property real frameHeight: Math.min(650, (root.height-80)/scale)
        LockElementHost {
            id: timeHost; elementId: "time"; configuration: root.layout.elements.time
            canvasWidth: plane.width; canvasHeight: plane.height; baseWidth: plane.frameWidth
            composition: root.layout.space === "composition"
            flowX: (plane.width-plane.frameWidth)/2; flowY: (plane.height-plane.frameHeight)/2
            contentHeight: timeBlock.height
            LockClock { id: timeBlock; width: parent.width; tokens: design; timeLabel: root.timeLabel; dateLabel: root.dateLabel; alignment: timeHost.configuration.alignment }
        }
        LockElementHost {
            id: identityHost; elementId: "identity"; configuration: root.layout.elements.identity
            canvasWidth: plane.width; canvasHeight: plane.height; baseWidth: plane.frameWidth
            composition: root.layout.space === "composition"
            flowX: (plane.width-plane.frameWidth)/2; flowY: (plane.height-plane.frameHeight)/2 + plane.frameHeight*.36
            contentHeight: profile.height
            LockProfile { id: profile; width: parent.width; tokens: design; displayName: root.visual.displayName || ""; artworkAvailable: root.avatarAvailable }
        }
        LockElementHost {
            id: authHost; elementId: "authentication"; configuration: root.layout.elements.authentication
            canvasWidth: plane.width; canvasHeight: plane.height; baseWidth: plane.frameWidth
            composition: root.layout.space === "composition"
            flowX: (plane.width-plane.frameWidth)/2; flowY: identityHost.y + identityHost.height*identityHost.scale + design.gap
            contentHeight: authBlock.height
            Column {
                id: authBlock; width: parent.width; spacing: design.gap
                LockCredential { width: parent.width; tokens: design; characterCount: root.characterCount }
                LockFingerprint { width: parent.width; tokens: design; status: root.fingerprintStatus }
                LockStatus { width: parent.width; tokens: design; authStatus: root.authStatus; capsLock: root.capsLock; capsKnown: root.capsKnown; inputActive: root.inputActive; characterCount: root.characterCount }
            }
        }
    }
    Text {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 28; anchors.horizontalCenter: parent.horizontalCenter
        text: root.developmentNotice || "M A G I"; textFormat: Text.PlainText
        width: parent.width-32; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
        font.family: design.family; font.pixelSize: 11; color: design.secondary; opacity: 0.7
    }
}
