// Pure, data-only resolution. No user-selected QML or arbitrary file paths.
function resolve(registry, settings, role, moduleId) {
    const packs = registry.packs
    const base = packs.find(p => p.id === "magi-legacy")
    const warnings = []
    function fromPack(id, name) {
        const pack = packs.find(p => p.id === id)
        if (!pack) { warnings.push("Unknown icon pack: " + id); return null }
        const value = (pack.modules && pack.modules[moduleId] && pack.modules[moduleId][name]) || pack.roles[name]
        if (!value) return null
        if (value.kind === "glyph" && typeof value.text === "string")
            return {kind: "glyph", text: value.text, font: value.font || pack.font}
        if (value.kind === "svg" && pack.assets && pack.assets[value.assetId]) {
            const path = pack.assets[value.assetId]
            if (/^[a-zA-Z0-9_/-]+\.svg$/.test(path) && path.indexOf("..") < 0)
                return {kind: "svg", path: path}
        }
        warnings.push("Invalid icon: " + id + "/" + name)
        return null
    }
    function override(value) {
        if (!value) return null
        if (value.source === "bundled") return fromPack(value.pack, value.icon)
        warnings.push("User icon import is not enabled: " + (value.assetId || role))
        return null
    }
    const overrides = settings.overrides || {}
    const individual = overrides.modules && overrides.modules[moduleId]
    const selected = (settings.modulePacks || {})[moduleId] || settings.pack
    const icon = override(individual && individual[role])
        || override(overrides.global && overrides.global[role])
        || fromPack(selected, role)
        || (selected !== settings.pack ? fromPack(settings.pack, role) : null)
        || fromPack(base.id, role) || fromPack(base.id, "missing")
    return {icon: icon, diagnostic: warnings.join("; ")}
}
