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

// One geometry contract for the live panel and its Settings editor. Callers supply
// measured profile/media heights and output room; editor labels never add padding.
function geometry(layout, metrics) {
    const padding = metrics.padding, tileGap = 12, actionGap = 8
    const columns = Math.max(1, Math.min(layout.columns,
        Math.floor((metrics.availableWidth - 2 * padding + tileGap) / (metrics.tileSize + tileGap))))
    const width = Math.min(metrics.availableWidth, Math.max(300,
        columns * metrics.tileSize + (columns - 1) * tileGap + 2 * padding))
    const innerWidth = width - 2 * padding
    const actionColumns = Math.max(1, Math.min(layout.actionColumns, metrics.actions,
        Math.max(1, Math.floor((innerWidth + actionGap) / (metrics.actionSize + actionGap)))))
    const rows = Math.ceil(metrics.controls / columns), actionRows = Math.ceil(metrics.actions / actionColumns)
    const gridHeight = rows ? rows * metrics.tileSize + (rows - 1) * tileGap : 0
    const actionHeight = actionRows ? actionRows * metrics.actionSize + (actionRows - 1) * actionGap : 0
    const ids = ["profile", "controls", "sliders", "actions", "media"]
    const visible = [metrics.profile, metrics.controls > 0, metrics.sliders > 0, metrics.actions > 0, true]
        .map((show, i) => show && layout.layout.includes(ids[i]))
    const heights = [metrics.profileHeight, gridHeight, metrics.sliderHeight, actionHeight, metrics.mediaHeight]
    const sections = compose(layout.layout, visible, heights, metrics.gaps)
    return {width:width, innerWidth:innerWidth, columns:columns, actionColumns:actionColumns,
        rows:rows, actionRows:actionRows, gridHeight:gridHeight, actionHeight:actionHeight,
        visible:visible, heights:heights, sections:sections,
        height:Math.min(metrics.availableHeight, Math.max(42, sections.height + metrics.topPadding + padding))}
}
