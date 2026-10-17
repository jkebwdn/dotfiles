import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as Centre
import "../../.config/quickshell/magi/components/calendar" as CalendarUI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    QtObject {
        id: media
        property bool available: false
        property bool playing: false
        property bool canPrevious: false
        property bool canNext: true
        property bool canToggle: true
        property string title: "A long track title ".repeat(30)
        property string artist: "Artist ".repeat(50)
        property string identity: "Player"
        property string artworkUrl: ""
        property real progress: .4
        property int toggles: 0
        property int nexts: 0
        property int previousCalls: 0
        function togglePlaying() { toggles++; playing = !playing }
        function next() { nexts++ }
        function previous() { previousCalls++ }
    }
    FloatingWindow {
        id: window
        visible: true; color: Theme.Theme.surface; implicitWidth: 700; implicitHeight: 700
        Centre.MediaSection { id: card; width: 280; height: implicitHeight; service: media }
        CalendarUI.CalendarContent { id: calendar; y: 180; width: 320; height: implicitHeight; service: Services.Calendar }
    }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "SecondarySurfaces"
        when: Services.Settings.ready
        function bounds(item, parent) {
            const p = item.mapToItem(parent, 0, 0)
            verify(p.x >= 0 && p.y >= 0 && p.x + item.width <= parent.width + 1 && p.y + item.height <= parent.height + 1, item.objectName + " bounds")
        }
        function test_presentation() {
            try {
            const art = findChild(card, "runtimeAlbumArt")
            const title = findChild(card, "mediaTitle")
            const toggle = findChild(card, "mediaToggle")
            const next = findChild(card, "mediaNext")
            const previous = findChild(card, "mediaPrevious")
            for (const palette of ["catppuccin-mocha", "catppuccin-frappe", "everforest-dark-hard", "everforest-light-hard"]) {
                Services.Settings.setTheme(palette)
                media.available = false; wait(30)
                compare(title.text, "Nothing playing")
                verify(card.visible && !toggle.visible)
                compare(art.progress, -1)
                media.available = true; wait(30)
                verify(toggle.visible)
                compare(title.color, Theme.Theme.text)
                for (const size of [48, 80, 112]) {
                    Services.Settings.setVisual("mediaArtworkSize", size)
                    for (const radius of [0, 1, 2]) {
                        Services.Settings.setRoundness("albumArt", radius)
                        for (const source of ["", "test-artwork.ppm", "portrait.ppm", "square.ppm"]) {
                            media.artworkUrl = source ? Qt.resolvedUrl(source) : ""
                            wait(20)
                            compare(art.width, size); compare(art.height, size)
                            bounds(art, card); bounds(title, card); bounds(toggle, card); bounds(next, card)
                            const image = findChild(art, "artworkSource")
                            const mask = findChild(art, "artworkMask")
                            const effect = findChild(art, "artworkEffect")
                            if (source) tryCompare(image, "status", Image.Ready)
                            verify(image.clip && image.layer.enabled && effect.maskEnabled)
                            compare(mask.width, image.width)
                            compare(mask.radius, Math.max(0, art.outerRadius - art.frameWidth))
                        }
                    }
                }
                toggle.forceActiveFocus(); keyClick(Qt.Key_Space)
                verify(media.playing); compare(toggle.label, "Pause")
                keyClick(Qt.Key_Return); verify(!media.playing)
                next.forceActiveFocus(); keyClick(Qt.Key_Return)
                mouseClick(previous); compare(media.previousCalls, 0)
                calendar.requestInitialFocus()
                Services.Calendar.model.resetToday(); wait(30)
                const today = Services.Calendar.model.today.getDate()
                let cell = findChild(calendar, "calendarDay-" + today)
                verify(cell.modelData.today && cell.modelData.selected)
                compare(cell.border.color, Theme.Theme.focus)
                calendar.navigate(Qt.Key_Right); wait(30)
                cell = findChild(calendar, "calendarDay-" + today)
                verify(cell.modelData.today && !cell.modelData.selected)
                compare(cell.border.color, Theme.Theme.accent)
                if (Quickshell.env("MAGI_SECONDARY_CAPTURES"))
                    grabImage(window.contentItem).save(Quickshell.env("MAGI_SECONDARY_CAPTURES") + "/calendar-media-" + palette + ".png")
                for (const density of ["compact", "comfortable"]) {
                    Services.Settings.setValue("calendar", "density", density)
                    Services.Settings.setValue("calendar", "showWeekNumbers", true)
                    wait(30)
                    compare(calendar.gridBottom, calendar.implicitHeight)
                    verify(calendar.gridTop > 0)
                    compare(calendar.cellHeight, density === "compact" ? 32 : 38)
                }
            }
            compare(media.toggles, 8); compare(media.nexts, 4)
            console.log("Secondary surfaces PASS")
            finish.start()
            } catch (error) { console.error("FAIL: " + error + " " + error.stack); throw error }
        }
    }
}
