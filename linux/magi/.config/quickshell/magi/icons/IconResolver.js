// Pure, data-only resolution. No user-selected QML or arbitrary file paths.
function resolve(registry, settings, role, moduleId) {
    const packs = registry.packs
    const base = packs.find(p => p.id === "magi-legacy")
    const warnings = []
    function fromPack(id, name, visited) {
        const pack = packs.find(p => p.id === id)
        if (!pack) { warnings.push("Unknown icon pack: " + id); return null }
        visited = visited || []
        if (visited.indexOf(id) >= 0) { warnings.push("Icon-pack parent cycle: " + id); return null }
        visited = visited.concat([id])
        const value = (pack.modules && pack.modules[moduleId] && pack.modules[moduleId][name]) || pack.roles[name]
        if (!value) return pack.parent ? fromPack(pack.parent, name, visited) : null
        if (value.kind === "glyph" && typeof value.text === "string")
            return {kind: "glyph", text: value.text, font: value.font || pack.font}
        if (value.kind === "svg" && pack.assets && pack.assets[value.assetId]) {
            const path = pack.assets[value.assetId]
            if (/^[a-zA-Z0-9_/-]+\.svg$/.test(path) && path.indexOf("..") < 0)
                return {kind: "svg", path: path}
        }
        if (value.kind === "managed-svg" && typeof pack.baseUrl === "string"
                && /^file:\/\//.test(pack.baseUrl) && /^[a-z0-9-]+\.svg$/.test(value.path))
            return {kind: "managed", url: pack.baseUrl + value.path}
        warnings.push("Invalid icon: " + id + "/" + name)
        return null
    }
    function override(value) {
        if (!value) return null
        if (value.source === "bundled") return fromPack(value.pack, value.icon)
        if (value.source === "user" && typeof value.assetId === "string"
                && /^icon:[a-f0-9]{64}\.svg$/.test(value.assetId))
            return {kind: "user", assetId: value.assetId}
        warnings.push("Invalid icon override: " + (value.assetId || role))
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
