// Object identity governs lifetimes; connector names only rank active objects.
function eligible(screens) {
    return (screens || []).filter(s => s && s.width > 0 && s.height > 0)
}
function main(screens, previous, focusedName) {
    const active = eligible(screens)
    const internal = active.filter(s => /^(eDP|LVDS|DSI)(-|$)/i.test(s.name))
        .sort((a,b) => a.name.localeCompare(b.name))
    return internal[0] || (active.includes(previous) ? previous : null)
        || active.find(s => s.name === focusedName)
        || active.slice().sort((a,b) => a.name.localeCompare(b.name))[0] || null
}
function selected(screens, mainScreen, external) {
    return external ? eligible(screens) : (mainScreen ? [mainScreen] : [])
}
function geometry(width, height, inset, offset, bottom, minimumWidth) {
    const horizontal = Math.max(0, Math.min(inset, (width - Math.min(width, minimumWidth)) / 2))
    const edge = Math.max(0, Math.min(offset, height - 48))
    return {inset: horizontal, width: Math.max(0, width - horizontal * 2),
        y: bottom ? Math.max(0, height - 48 - edge) : edge,
        edgeOffset: edge, reservation: 48 + edge,
        top: bottom ? 0 : 48 + edge, bottom: bottom ? 48 + edge : 0}
}
