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
    property string powerStatus: ""
    property int powerConfirmation: 0
    property string fingerprintStatus: ""
    property string authStatus: "Locked"
    property var visual: ({})
    property string timeLabel: ""
    property string dateLabel: ""
    property bool wallpaperAvailable: false
    property bool avatarAvailable: false
    property url preparedMediaSource: "image://visual/media"
    property url preparedDepthSource: "image://visual/depth"
    LockTokens { id: design; palette: root.visual; artworkAvailable: root.wallpaperAvailable; logicalWidth: root.width; logicalHeight: root.height }
    LockBackground { anchors.fill: parent; tokens: design; artworkAvailable: root.wallpaperAvailable }
    readonly property var layout: Layout.normalize(visual.lockScreen)
    readonly property var elementBoxes: ({time:timeHost, identity:identityHost, authentication:authHost, weather:weatherHost, media:mediaHost})
    Item {
        id: plane
        width: root.width / design.visualScale; height: root.height / design.visualScale
        scale: design.visualScale; transformOrigin: Item.TopLeft
        readonly property real frameWidth: Math.min(600, (root.width-32)/scale)
        readonly property real frameHeight: Math.min(650, (root.height-80)/scale)
        LockElementHost {
            id: timeHost; objectName: "timeHost"; elementId: "time"; configuration: root.layout.elements.time
            canvasWidth: plane.width; canvasHeight: plane.height; baseWidth: plane.frameWidth
            composition: root.layout.space === "composition"
            flowX: (plane.width-plane.frameWidth)/2; flowY: (plane.height-plane.frameHeight)/2
            // Adjacent top-left identity keeps a logical gutter even on compact outputs.
            readonly property bool adjacentIdentity: !composition && identityHost.visible
                && configuration.anchor === "top-left" && identityHost.configuration.anchor === "top-left"
                && Math.abs(configuration.offsetY-identityHost.configuration.offsetY) < .02
            x: adjacentIdentity ? Math.max(16, identityHost.x+identityHost.width*identityHost.scale+12) : composition ? flowX : resolved.x
            width: adjacentIdentity ? Math.min(plane.frameWidth, (plane.width-x-16)/scale) : Math.min(plane.frameWidth, (plane.width-32)/scale)
            contentHeight: timeBlock.height
            LockClock { id: timeBlock; fitHeight: timeHost.adjacentIdentity ? identityHost.height*identityHost.scale/timeHost.scale : 0; width: parent.width; tokens: design; timeLabel: root.timeLabel; dateLabel: root.dateLabel; alignment: timeHost.configuration.alignment }
        }
        LockElementHost {
            id: identityHost; objectName: "identityHost"; elementId: "identity"; configuration: root.layout.elements.identity
            canvasWidth: plane.width; canvasHeight: plane.height; baseWidth: configuration.alignment === "center" ? plane.frameWidth : design.avatarSize
            composition: root.layout.space === "composition"
            flowX: (plane.width-plane.frameWidth)/2; flowY: (plane.height-plane.frameHeight)/2 + plane.frameHeight*.36
            contentHeight: profile.height
            LockProfile { id: profile; nativeArtwork: root.visual.nativeArtwork === true; compact: timeHost.adjacentIdentity; alignment: identityHost.configuration.alignment; width: parent.width; tokens: design; displayName: root.visual.displayName || ""; treatment:root.layout.effects.avatar; artworkAvailable: root.avatarAvailable }
        }
        Image {
            anchors.fill: parent; z:1.5
            visible: root.layout.effects.depth && root.visual.depthAvailable === true
            source: visible ? root.preparedDepthSource : ""
            fillMode: Image.PreserveAspectCrop; smooth:true
        }
        LockElementHost {
            id: weatherHost; elementId:"weather"; configuration:root.layout.elements.weather
            canvasWidth:plane.width;canvasHeight:plane.height;baseWidth:300;contentHeight:weatherBlock.height
            LockAuxiliary {id:weatherBlock;width:parent.width;tokens:design;snapshot:root.visual.weather || ({});style:root.layout.effects.weather;showLocation:root.layout.effects.location}
        }
        LockElementHost {
            id: mediaHost; objectName: "mediaHost"; elementId:"media"; configuration:root.layout.elements.media
            canvasWidth:plane.width;canvasHeight:plane.height;baseWidth:340;contentHeight:mediaBlock.height
            readonly property bool underIdentity: root.layout.effects.media === "title" && timeHost.adjacentIdentity
            x: underIdentity ? identityHost.x : resolved.x
            y: underIdentity ? Math.max(identityHost.y+identityHost.height*identityHost.scale, timeHost.y+timeHost.height*timeHost.scale)+12 : resolved.y
            width: underIdentity ? Math.min(440, (plane.width-identityHost.x-16)/scale) : Math.min(340, (plane.width-32)/scale)
            LockAuxiliary {id:mediaBlock;artworkSource:root.preparedMediaSource;width:parent.width;tokens:design;media:true;snapshot:root.visual.media || ({});style:root.layout.effects.media;showArtwork:root.layout.effects.artwork}
        }
        LockElementHost {
            id: authHost; objectName: "authHost"; elementId: "authentication"; configuration: root.layout.elements.authentication
            canvasWidth: plane.width; canvasHeight: plane.height; baseWidth: plane.frameWidth
            composition: root.layout.space === "composition"
            flowX: (plane.width-plane.frameWidth)/2; flowY: identityHost.y + identityHost.height*identityHost.scale + design.gap
            contentHeight: authBlock.height
            Rectangle {
                objectName: "authContrastBackdrop"
                anchors.fill:parent;anchors.margins:-8;z:-1;radius:12;color:design.background
                visible: (root.layout.effects.depth && root.visual.depthAvailable === true)
                    || (root.layout.elements.media.visible && !!root.visual.media && root.visual.media.available === true
                        && Layout.overlaps(mediaHost, authHost, 8 * authHost.scale))
            }
            Column {
                id: authBlock; width: parent.width; spacing: 8
                readonly property real trailingSlot: 0
                Text {
                    objectName: "authFeedback"
                    width: parent.width-authBlock.trailingSlot; height: 32
                    text: root.powerStatus || (root.authStatus === "Locked" || root.authStatus === "Enter password, then Enter" ? (!root.inputActive ? passwordStatus.message : "") : passwordStatus.message)
                    textFormat: Text.PlainText; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    horizontalAlignment: authHost.configuration.alignment === "right" ? Text.AlignRight : authHost.configuration.alignment === "left" ? Text.AlignLeft : Text.AlignHCenter
                    color: passwordStatus.failed || passwordStatus.unavailable || root.powerStatus !== "" ? design.danger : design.secondary
                    font.family: design.family; font.pixelSize: 14
                }
                LockCredential { alignment: authHost.configuration.alignment; width: parent.width-authBlock.trailingSlot; tokens: design; characterCount: root.characterCount; style:root.layout.effects.credential }
                LockStatus { id: passwordStatus; nativeArtwork: root.visual.nativeArtwork === true; fingerprintStatus: root.fingerprintStatus; alignment: authHost.configuration.alignment; width: parent.width; tokens: design; authStatus: root.authStatus; capsLock: root.capsLock; capsKnown: root.capsKnown; inputActive: root.inputActive; characterCount: root.characterCount }
                Item {
                    objectName: "powerActions"
                    width: parent.width; height: 28
                    Row {
                        x: authHost.configuration.alignment === "right" ? parent.width-authBlock.trailingSlot-width : authHost.configuration.alignment === "left" ? 0 : (parent.width-width)/2
                        spacing: 12
                        Text { objectName: "powerReboot"; text: root.powerConfirmation === 1 ? "CONFIRM REBOOT" : "REBOOT"; color: design.secondary; font.family: design.family; font.pixelSize: 13; height: 28; verticalAlignment: Text.AlignVCenter }
                        Text { text: "|"; color: design.secondary; font.pixelSize: 13; height: 28; verticalAlignment: Text.AlignVCenter }
                        Text { objectName: "powerSuspend"; text: root.powerConfirmation === 2 ? "CONFIRM SUSPEND" : "SUSPEND"; color: design.secondary; font.family: design.family; font.pixelSize: 13; height: 28; verticalAlignment: Text.AlignVCenter }
                        Text { objectName: "powerCancel"; visible: root.powerConfirmation !== 0; text: "CANCEL"; color: design.secondary; font.family: design.family; font.pixelSize: 13; height: 28; verticalAlignment: Text.AlignVCenter }
                    }
                }
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
