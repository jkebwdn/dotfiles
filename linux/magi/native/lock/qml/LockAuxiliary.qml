import QtQuick
Column {
    id: root
    required property var tokens
    property var snapshot: ({})
    property bool media: false
    property string style: "standard"
    property bool showLocation: false
    property bool showArtwork: true
    property url artworkSource: "image://visual/media"
    spacing: 8
    visible: snapshot.available === true
    Row {
        objectName: "nowPlayingTitle"
        visible: root.media && root.style === "title"
        width: parent.width; height: 24; spacing: 8
        LockMediaIcon {width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter; ink: tokens.secondary}
        Text {
            width: parent.width-28; anchors.verticalCenter: parent.verticalCenter
            text: root.snapshot.title || ""; textFormat: Text.PlainText
            elide: Text.ElideRight; maximumLineCount: 1
            font.family: tokens.family; font.pixelSize: 16; color: tokens.secondary
        }
    }
    Image {
        visible: root.media && root.style === "artwork" && root.showArtwork && root.snapshot.artwork === true
        width: 112; height: 112; anchors.horizontalCenter: parent.horizontalCenter
        source: visible ? root.artworkSource : ""; fillMode: Image.PreserveAspectFit
    }
    Image {
        visible: root.media && root.style === "artwork" && (!root.showArtwork || root.snapshot.artwork !== true) && root.snapshot.icon === true
        width:48;height:48;anchors.horizontalCenter:parent.horizontalCenter
        source:visible ? "image://visual/media-icon" : ""
    }
    Text {
        visible: !root.media || root.style !== "title"
        width: parent.width; horizontalAlignment: Text.AlignHCenter
        text: root.media ? (root.snapshot.title || "") : ((root.snapshot.temperature || "") + (root.style === "compact" ? " · " + (root.snapshot.condition || "") : ""))
        textFormat: Text.PlainText; elide: Text.ElideRight; maximumLineCount: 1
        font.family: tokens.family; font.pixelSize: root.media ? 22 : root.style === "compact" ? 22 : 32; color: tokens.ink
    }
    Text {
        visible: root.media ? root.style !== "minimal" && root.style !== "title" : root.style === "standard"; width: parent.width; horizontalAlignment: Text.AlignHCenter
        text: root.media ? (root.snapshot.artist || "") : (root.snapshot.condition || "")
        textFormat: Text.PlainText; elide: Text.ElideRight
        font.family: tokens.family; font.pixelSize: 16; color: tokens.secondary
    }
    Text {
        visible: root.showLocation && !root.media; width:parent.width; horizontalAlignment:Text.AlignHCenter
        text: root.snapshot.location || ""; textFormat:Text.PlainText;elide:Text.ElideRight
        font.family:tokens.family;font.pixelSize:14;color:tokens.secondary
    }
}
