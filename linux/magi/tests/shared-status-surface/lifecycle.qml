pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/theme" as Theme

// Windowless real-component regression. No pointer injection or system writes.
ShellRoot {
    id: test
    property int failures: 0
    property int step: 0
    property int statusWidth: 180
    property int bodiesCreated: 0
    property bool guardOpen: false

    Component {
        id: dummyBody
        Item { Component.onCompleted: test.bodiesCreated++ }
    }
    QtObject {
        id: centre
        property int expandedWidth: Theme.RenderTokens.controlWidth
        property int menuHeight: Theme.RenderTokens.controlBodyHeight
        property int viewPadding: Theme.RenderTokens.padding
        property int viewBottomPadding: Theme.RenderTokens.padding
        property Component menuContent: dummyBody
    }
    QtObject {
        id: wifi
        property int expandedWidth: 328
        property int menuHeight: 390
        property Component menuContent: dummyBody
    }
    QtObject {
        id: bluetooth
        property int expandedWidth: 326
        property int menuHeight: 350
        property Component menuContent: dummyBody
    }
    QtObject {
        id: volume
        property int expandedWidth: 280
        property int menuHeight: 100
        property Component menuContent: dummyBody
    }
    Bar.SharedStatusSurface {
        id: surface
        combined: true
        modules: [centre, wifi, bluetooth, volume]
        statusContent: Component {
            Item { implicitWidth: test.statusWidth; implicitHeight: 28 }
        }
    }

    function check(condition, message) {
        if (!condition) {
            failures++
            console.error("FAIL: " + message + " phase=" + surface.phase
                + " height=" + surface.revealedHeight
                + " opacity=" + surface.contentOpacity)
        }
    }
    function opened(module) {
        check(surface.phase === 3 && surface.displayedModule === module
            && surface.contentOpacity === 1
            && surface.revealedHeight === module.menuHeight
            && surface.interactive, "open settles to requested interactive body")
    }
    function closed() {
        check(surface.phase === 0 && surface.revealedHeight === 0
            && surface.contentOpacity === 0
            && surface.animatedWidth === surface.collapsedWidth
            && surface.expansion === 0 && !surface.interactive,
            "close returns exactly to compact geometry")
    }
    Connections {
        target: surface
        function onRevealedHeightChanged() {
            if (test.guardOpen)
                test.check(surface.revealedHeight > 0, "view switch never collapses")
        }
    }

    property var steps: makeSteps()
    function makeSteps() {
        const result = []
        function add(delay, run) { result.push({delay: delay, run: run}) }
        add(20, () => { surface.requestedModule = centre })
        add(550, () => {
            opened(centre); guardOpen = true
            centre.expandedWidth = 440; centre.menuHeight = 310
        })
        add(300, () => {
            opened(centre)
            check(surface.animatedWidth === 440 && surface.height === 346,
                "same-view geometry grows without collapse or content fade")
            check(surface.contentOpacity === 1, "retarget preserves visible content")
            centre.expandedWidth = 360; centre.menuHeight = 260
        })
        add(40, () => { centre.expandedWidth = 320; centre.menuHeight = 208 })
        add(300, () => {
            opened(centre)
            check(surface.animatedWidth === 320 && surface.height === 244,
                "interrupted same-view retarget settles to latest dimensions")
            guardOpen = false
        })
        add(550, () => { opened(centre); surface.requestedModule = null })
        add(550, () => { closed(); surface.requestedModule = centre })
        add(550, () => { opened(centre); guardOpen = true; surface.requestedModule = wifi })
        add(550, () => { opened(wifi); surface.requestedModule = centre })
        add(550, () => {
            opened(centre)
            check(surface.height === 244, "CC drops excess detail height")
            surface.requestedModule = bluetooth
        })
        add(550, () => { opened(bluetooth); surface.requestedModule = volume })
        add(550, () => {
            opened(volume)
            check(surface.height === 136, "Volume uses its own short geometry")
            surface.requestedModule = centre
        })
        add(25, () => { surface.requestedModule = wifi })
        add(25, () => { surface.requestedModule = centre })
        add(550, () => {
            opened(centre); guardOpen = false; surface.requestedModule = null
        })
        add(550, () => { closed() })

        // Reverse closing during fade, vertical retraction and narrowing.
        for (const timing of [{delay: 30, phase: 4}, {delay: 115, phase: 5},
                              {delay: 250, phase: 6}]) {
            add(20, () => { surface.requestedModule = centre })
            add(550, () => { opened(centre); surface.requestedModule = null })
            add(timing.delay, () => {
                check(surface.phase === timing.phase, "reached interruption phase " + timing.phase)
                surface.requestedModule = wifi
            })
            add(550, () => { opened(wifi); surface.requestedModule = null })
            add(550, () => { closed() })
        }

        // Interrupt horizontal widening and vertical reveal.
        for (const timing of [{delay: 45, phase: 1}, {delay: 220, phase: 2}]) {
            add(20, () => { surface.requestedModule = centre })
            add(timing.delay, () => {
                check(surface.phase === timing.phase, "reached interruption phase " + timing.phase)
                surface.requestedModule = null
            })
            add(30, () => { surface.requestedModule = wifi })
            add(550, () => { opened(wifi); surface.requestedModule = null })
            add(550, () => { closed() })
        }

        add(20, () => { statusWidth = 240 })
        add(50, () => { closed(); surface.requestedModule = centre })
        add(550, () => { opened(centre); statusWidth = 320 })
        add(300, () => {
            check(surface.animatedWidth >= 372, "open geometry accommodates richer compact state")
            surface.requestedModule = null
        })
        add(550, () => {
            closed()
            // Same event-loop burst must resolve to its last request.
            surface.requestedModule = centre
            surface.requestedModule = null
            surface.requestedModule = wifi
        })
        add(550, () => { opened(wifi); surface.requestedModule = null })
        add(550, () => {
            closed()
            check(bodiesCreated === 4, "module bodies survive switching and closing")
        })
        return result
    }

    function nextStep() {
        if (step === steps.length) {
            console.log("RESULT: " + failures + " failures; " + step + " steps")
            Qt.quit()
            return
        }
        clock.interval = steps[step].delay
        clock.start()
    }
    Component.onCompleted: nextStep()
    Timer {
        id: clock
        onTriggered: {
            test.steps[test.step++].run()
            test.nextStep()
        }
    }
}
