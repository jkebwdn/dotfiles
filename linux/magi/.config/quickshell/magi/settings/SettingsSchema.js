// MAGI's preference schema, not system or menu-session state.
const barIds = ["clock", "date", "workspaces", "volume", "wifi", "bluetooth", "battery", "controlcentre"]
const radiusRoles = ["barPill", "surface", "controlTile", "slider", "action"]
function defaults() {
    return {schemaVersion: 1,
        appearance: {theme: "catppuccin-mocha", roundness: {master: 1,
            roles: {barPill: null, surface: null, controlTile: null, slider: null, action: null}}},
        icons: {pack: "magi-legacy", modulePacks: {}, overrides: {global: {}, modules: {}}},
        bar: {left: ["clock", "date"], center: ["workspaces"],
            right: ["volume", "wifi", "bluetooth", "battery", "controlcentre"]},
        controlCentre: {columns: 4, controls: [
            {key: "network", module: "wifi", enabled: true, presentation: "tile"},
            {key: "power", module: "battery", enabled: true, presentation: "tile"},
            {key: "sound", module: "volume", enabled: true, presentation: "tile"},
            {key: "wireless", module: "bluetooth", enabled: true, presentation: "tile"}],
            sliders: [
                {key: "volume", module: "volume", enabled: true, presentation: "slider"},
                {key: "backlight", module: "brightness", enabled: true, presentation: "slider"}]}}
}
function clone(value) { return JSON.parse(JSON.stringify(value)) }
function object(value) { return value !== null && typeof value === "object" && !Array.isArray(value) }
function unsafe(value) {
    if (value === null || typeof value !== "object") return false
    return Object.keys(value).some(key => ["__proto__", "prototype", "constructor"].indexOf(key) >= 0 || unsafe(value[key]))
}
function analyze(input) {
    if (!object(input) || unsafe(input)) throw new Error("Settings must be a safe JSON object")
    if (!Number.isInteger(input.schemaVersion) || input.schemaVersion < 1)
        throw new Error("Invalid schema version")
    if (input.schemaVersion > 1) return {future: true, document: clone(input), effective: defaults(), errors: [], warnings: []}
    const errors = [], warnings = []
    // Preserve unknown fields and invalid raw values while building a safe effective copy.
    function fill(value, fallback, path) {
        if (value === undefined) return clone(fallback)
        if (object(fallback)) {
            if (!object(value)) { errors.push(path + ": expected object"); return clone(fallback) }
            const out = clone(value)
            for (const key of Object.keys(fallback)) out[key] = fill(value[key], fallback[key], path + "." + key)
            return out
        }
        return clone(value)
    }
    const document = clone(input), effective = fill(input, defaults(), "settings")
    function valid(test, path, fallback) {
        if (!test) { errors.push(path + ": invalid value"); return clone(fallback) }
        return null
    }
    const a = effective.appearance
    if (typeof a.theme !== "string" || !a.theme.length) { valid(false, "appearance.theme", ""); a.theme = "catppuccin-mocha" }

    const r = a.roundness
    if (typeof r.master !== "number" || !isFinite(r.master) || r.master < 0 || r.master > 2) {
        valid(false, "roundness.master", 1); r.master = 1
    }
    for (const role of radiusRoles) {
        const v = r.roles[role]
        if (v !== null && (typeof v !== "number" || !isFinite(v) || v < 0 || v > 2)) {
            valid(false, "roundness." + role, null); r.roles[role] = null
        }
    }
    if (typeof effective.icons.pack !== "string" || !effective.icons.pack.length) {
        valid(false, "icons.pack", ""); effective.icons.pack = "magi-legacy"
    } else if (effective.icons.pack !== "magi-legacy") {
        warnings.push("Unknown icon pack: " + effective.icons.pack); effective.icons.pack = "magi-legacy"
    }
    const seen = []
    for (const section of ["left", "center", "right"]) {
        const list = effective.bar[section]
        if (!Array.isArray(list) || list.some(id => typeof id !== "string")) {
            valid(false, "bar." + section, []); effective.bar[section] = defaults().bar[section]
        }
        effective.bar[section] = effective.bar[section].filter(id => {
            if (seen.indexOf(id) >= 0) { warnings.push("Duplicate bar placement: " + id); return false }
            seen.push(id)
            if (barIds.indexOf(id) < 0) { warnings.push("Unknown bar module: " + id); return false }
            return true
        })
    }
    const cc = effective.controlCentre
    if (!Number.isInteger(cc.columns) || cc.columns < 1 || cc.columns > 16) {
        valid(false, "controlCentre.columns", 4); cc.columns = 4
    }
    for (const group of ["controls", "sliders"]) {
        const keys = [], modules = [], presentation = group === "controls" ? "tile" : "slider"
        if (!Array.isArray(cc[group])) { valid(false, "controlCentre." + group, []); cc[group] = defaults().controlCentre[group] }
        cc[group] = cc[group].filter(entry => {
            if (!object(entry) || typeof entry.key !== "string" || !entry.key.length
                || typeof entry.module !== "string" || typeof entry.enabled !== "boolean"
                || entry.presentation !== presentation || keys.indexOf(entry.key) >= 0
                || modules.indexOf(entry.module) >= 0) {
                errors.push("Invalid/duplicate controlCentre." + group + " entry"); return false
            }
            keys.push(entry.key); modules.push(entry.module)
            const supported = group === "controls" ? ["wifi", "battery", "volume", "bluetooth"] : ["volume", "brightness"]
            if (supported.indexOf(entry.module) < 0) { warnings.push("Unavailable CC module: " + entry.module); return false }
            return true
        })
    }
    return {future: false, document: document, effective: effective, errors: errors, warnings: warnings}
}
