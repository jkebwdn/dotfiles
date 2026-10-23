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

// Positions remain indexed by canonical section ID; composition controls traversal.
function compose(order, visible, heights, gaps) {
    const ids = ["profile", "controls", "sliders", "actions", "media"]
    const positions = [0,0,0,0,0]
    let height = 0, previous = -1
    for (const id of order) {
        const i = ids.indexOf(id)
        if (i < 0 || !visible[i]) continue
        if (previous >= 0) height += gaps[previous] || 0
        positions[i] = height; height += heights[i]; previous = i
    }
    return {positions:positions,height:height}
}
