function name(item) { return item ? String(item.title || item.id || "Background application") : "Background application" }
function tooltip(item) {
    if (!item) return ""
    const title = String(item.tooltipTitle || item.title || item.id || "").slice(0, 180)
    const description = String(item.tooltipDescription || "").slice(0, 600)
    return [title, description].filter(text => text.length > 0).join("\n")
}
function invoke(item, action, showMenu) {
    if (!item) return false
    try {
        if (action === "menu" || (action === "primary" && item.onlyMenu)) {
            if (!item.hasMenu || !item.menu) return false
            showMenu(); return true
        }
        const method = action === "primary" ? "activate" : action === "secondary" ? "secondaryActivate" : ""
        if (!method || typeof item[method] !== "function") return false
        item[method](); return true
    } catch (error) { return false } // An application may unregister between input and dispatch.
}
function scroll(item, x, y) {
    if (!item || typeof item.scroll !== "function") return false
    try {
        // Preserve Qt wheel deltas; the SNI API does not prescribe a degree conversion.
        if (y) item.scroll(Math.round(y), false)
        if (x) item.scroll(Math.round(x), true)
        return !!(x || y)
    } catch (error) { return false }
}
function partition(items, width, cell) {
    const slots = Math.max(1, Math.floor(Math.max(0, width - 8) / cell))
    const count = items.length > slots ? Math.max(0, slots - 1) : items.length
    return {visible: items.slice(0, count), overflow: items.slice(count)}
}
