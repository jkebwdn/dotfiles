pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "PlayerSelection.js" as Selection
import "../components/controls/VisualState.js" as VisualState

Scope {
    id: root
    property var players: []
    property string preferredPlayer: ""
    property var activePlayer: null
    property bool cacheArtwork: true
    property int artworkRequest: 0
    property string artworkUrl: ""
    readonly property bool available: activePlayer !== null
    readonly property string identity: available ? activePlayer.identity || activePlayer.desktopEntry || "" : ""
    readonly property string title: available ? activePlayer.trackTitle || "" : ""
    readonly property string artist: available ? activePlayer.trackArtist || "" : ""
    readonly property bool playing: available && activePlayer.isPlaying
    readonly property bool canToggle: available && (activePlayer.canTogglePlaying
        || (playing ? activePlayer.canPause : activePlayer.canPlay))
    readonly property bool canPrevious: available && activePlayer.canGoPrevious
    readonly property bool canNext: available && activePlayer.canGoNext

    readonly property bool progressSupported: available && !!activePlayer.positionSupported && !!activePlayer.lengthSupported
    readonly property real progress: VisualState.progress(progressSupported ? activePlayer.position : 0,
        progressSupported ? activePlayer.length : 0, progressSupported)
    Timer {
        interval: 1000; repeat: true
        running: root.progressSupported && root.playing && MenuController.activeMenu === "controlcentre"
        onTriggered: root.activePlayer.positionChanged()
    }
    function refresh() {
        activePlayer = Selection.choose(players, preferredPlayer, activePlayer)
        refreshArtwork()
    }
    function refreshArtwork() {
        const source = available ? activePlayer.trackArtUrl || "" : ""
        artworkUrl = ""
        artworkRequest = source && cacheArtwork ? AssetManager.cacheArtwork(source, Selection.identifier(activePlayer)) : 0
    }
    function previous() { if (canPrevious) activePlayer.previous() }
    function togglePlaying() {
        if (!canToggle) return
        if (activePlayer.canTogglePlaying) activePlayer.togglePlaying()
        else if (playing) activePlayer.pause()
        else activePlayer.play()
    }
    function next() { if (canNext) activePlayer.next() }
    onPlayersChanged: Qt.callLater(refresh)
    onPreferredPlayerChanged: Qt.callLater(refresh)
    Connections {
        target: AssetManager
        function onCompleted(requestId, operation, assetId, url, error) {
            if (operation === "artwork" && requestId === root.artworkRequest && !error)
                root.artworkUrl = url
        }
    }
    Instantiator {
        model: root.players
        delegate: Item {
            id: watcher
            required property var modelData
            visible: false
            Connections {
                target: watcher.modelData
                function onIsPlayingChanged() { Qt.callLater(root.refresh) }
                function onTrackTitleChanged() { Qt.callLater(root.refreshArtwork) }
                function onTrackArtistChanged() { }
                function onTrackArtUrlChanged() { Qt.callLater(root.refreshArtwork) }
                function onIdentityChanged() { Qt.callLater(root.refresh) }
                function onCanControlChanged() { Qt.callLater(root.refresh) }
            }
        }
    }
    Component.onCompleted: refresh()
}
