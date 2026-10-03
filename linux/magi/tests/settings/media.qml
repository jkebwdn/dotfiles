pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services

ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property var players: []
    function check(ok, label) { if (!ok) { failures++; console.error("FAIL: " + label) } }
    QtObject {
        id: first
        property string dbusName: "org.mpris.MediaPlayer2.alpha"
        property string desktopEntry: "alpha"
        property string identity: "Alpha"
        property string trackTitle: "First"
        property string trackArtist: "Artist A"
        property string trackArtUrl: ""
        property bool positionSupported: true
        property bool lengthSupported: true
        property real position: 25
        property real length: 100
        property bool isPlaying: false
        property bool canControl: true
        property bool canTogglePlaying: true
        property bool canGoPrevious: true
        property bool canGoNext: true
        property int previousCalls: 0
        property int toggleCalls: 0
        property int nextCalls: 0
        function previous() { previousCalls++ }
        function togglePlaying() { toggleCalls++ }
        function next() { nextCalls++ }
    }
    QtObject {
        id: second
        property string dbusName: "org.mpris.MediaPlayer2.beta"
        property string desktopEntry: "beta"
        property string identity: "Beta"
        property string trackTitle: "Second"
        property string trackArtist: "Artist B"
        property string trackArtUrl: ""
        property bool isPlaying: true
        property bool canControl: true
        property bool canTogglePlaying: true
        property bool canGoPrevious: false
        property bool canGoNext: true
        function previous() {}
        function togglePlaying() {}
        function next() {}
    }
    Services.MediaController { id: media; players: test.players; cacheArtwork: false }
    Timer {
        interval: 120; running: true; repeat: true
        onTriggered: {
            switch (test.step++) {
            case 0:
                test.check(!media.available, "starts absent")
                test.players = [first]
                break
            case 1:
                test.check(media.available && media.title === "First" && media.artist === "Artist A", "player appears")
                test.check(media.progress === .25, "real supported position/duration")
                first.position = 50
                first.trackTitle = "Changed"
                media.previous(); media.togglePlaying(); media.next()
                break
            case 2:
                test.check(media.progress === .5, "nonlinear position update")
                test.check(media.title === "Changed", "metadata updates live")
                test.check(first.previousCalls === 1 && first.toggleCalls === 1 && first.nextCalls === 1, "playback actions dispatched")
                test.players = [first, second]
                break
            case 3:
                test.check(media.activePlayer === second, "playing player wins predictable selection")
                media.preferredPlayer = "alpha"
                break
            case 4:
                test.check(media.activePlayer === first, "explicit preference wins")
                test.players = []
                break
            case 5:
                test.check(!media.available && media.title === "" && media.progress === -1, "player disappearance clears state")
                console.log("RESULT: " + test.failures + " failures; MPRIS selection, metadata and actions")
                Qt.quit()
            }
        }
    }
}
