// One semantic fallback authority; no module overrides or parent graph.
function descriptor(pack, role) {
    const value = pack && pack.roles && Object.prototype.hasOwnProperty.call(pack.roles, role)
        ? pack.roles[role] : null
    if (!value || typeof value !== "object") return null
    if (typeof value.text === "string" && value.text.trim() && value.text.trim() !== "?")
        return {kind: "glyph", text: value.text, font: value.font || "sans-serif"}
    if (typeof value.asset === "string" && /^[a-z0-9]+(?:-[a-z0-9]+)*\.svg$/.test(value.asset)
            && typeof pack.baseUrl === "string" && /^file:\/\//.test(pack.baseUrl))
        return {kind: "managed", url: pack.baseUrl + value.asset,
            colorMode: value.colorMode === "fixed" ? "fixed" : "semantic"}
    return null
}
function resolve(registry, settings, role, skipSelected) {
    const packs = registry && Array.isArray(registry.packs) ? registry.packs : []
    const selected = packs.find(p => p && p.id === (settings || {}).pack)
    const canonical = packs.find(p => p && p.id === "magi-default")
    const chosen = skipSelected !== true && descriptor(selected, role)
    if (chosen) return {icon: chosen, sourcePack: selected.id, diagnostic: ""}
    const fallback = descriptor(canonical, role)
    if (fallback) return {icon: fallback, sourcePack: "magi-default",
        diagnostic: "Using MAGI default: " + role}
    // A bundled renderer-owned asset also works before the async inventory loads.
    return {icon: {kind: "placeholder", colorMode: "semantic"}, sourcePack: "",
        diagnostic: "Missing semantic icon: " + role}
}
