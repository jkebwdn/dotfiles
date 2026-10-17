// A visible section contributes its outgoing gap only if another visible section
// follows. Hidden sections contribute neither height nor gaps.
function arrange(visible, heights, gaps) {
    const positions = []
    let height = 0, previous = -1
    for (let i = 0; i < visible.length; ++i) {
        if (visible[i]) {
            if (previous >= 0) height += gaps[previous]
            positions.push(height)
            height += heights[i]
            previous = i
        } else positions.push(height)
    }
    return {positions: positions, height: height}
}
