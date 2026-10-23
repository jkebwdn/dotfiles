// Direct wheel movement. Keep fractional high-resolution deltas; do not queue
// animations or change touch-flick physics. Positive input moves toward the start.
function delta(pixel, angle) { return pixel !== 0 ? pixel : angle * 0.4 }
function move(view, amount, horizontal) {
    if (!view || !amount) return false
    const key = horizontal ? "contentX" : "contentY"
    const start = horizontal ? view.originX : view.originY
    const length = horizontal ? view.contentWidth - view.width : view.contentHeight - view.height
    const next = Math.max(start, Math.min(start + Math.max(0,length), view[key] - amount))
    if (Math.abs(next-view[key]) < .001) return false
    view.cancelFlick()
    view[key] = next
    return true
}
function ancestor(view, amount) {
    for (let p = view.parent; p; p = p.parent)
        if (p.contentY !== undefined && p.cancelFlick !== undefined && move(p,amount,false)) return true
    return false
}
