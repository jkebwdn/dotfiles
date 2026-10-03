// MAGI's preference schema, not system or menu-session state.
const barIds = ["clock", "date", "workspaces", "volume", "wifi", "bluetooth", "battery", "controlcentre"]
const radiusRoles = ["barPill", "surface", "controlTile", "slider", "action", "avatar"]
const controlAccentRoles = ["red", "peach", "yellow", "green", "teal", "blue", "lavender"]
const controlAccentDefaults = {wifi: "teal", bluetooth: "blue", "power-saver": "green",
    "airplane-mode": "lavender", battery: "red", settings: "lavender", vpn: "blue",
    dnd: "lavender", caffeine: "yellow"}
function defaults() {
    return {schemaVersion: 4,
        appearance: {theme: "catppuccin-mocha", roundness: {master: 1,
            roles: {barPill: null, surface: null, controlTile: null, slider: null, action: null, avatar: null}},
            visual: {statusIconSize: 18, tileBackgroundShade: 0.28, tileBorderShade: 0.48,
                tileBorderWidth: 4, controlOn: "text",
                controlOff: "background", controlOffOpacity: 0.28,
                sliderTrack: "elevated", sliderFill: "overlay", sliderBorder: "lavender",
                sliderBorderWidth: 2, avatarBorderWidth: 2}},
        icons: {pack: "magi-legacy", modulePacks: {}, overrides: {global: {}, modules: {}}},
        profile: {displayName: "", subtitle: "", subtitleMode: "greeting", avatar: null},
        media: {enabled: true, preferredPlayer: null, emptyState: "collapse"},
        bar: {left: ["clock", "date"], center: ["workspaces"],
            right: ["volume", "wifi", "bluetooth", "battery", "controlcentre"]},
        controlCentre: {columns: 4, actionColumns: 6, sections: {
            profile: true, quickControls: true, sliders: true, actions: true, media: true
        }, controls: [
            {key: "network", module: "wifi", accent: "teal", enabled: true, presentation: "tile"},
            {key: "wireless", module: "bluetooth", accent: "blue", enabled: true, presentation: "tile"},
            {key: "power-saver", module: "power-saver", accent: "green", enabled: true, presentation: "tile"},
            {key: "airplane-mode", module: "airplane-mode", accent: "lavender", enabled: true, presentation: "tile"}],
            sliders: [
                {key: "volume", module: "volume", enabled: true, presentation: "slider"},
                {key: "backlight", module: "brightness", enabled: true, presentation: "slider"}],
            actions: [
                {key: "vpn", module: "vpn", enabled: true, presentation: "action"},
                {key: "dnd", module: "dnd", enabled: true, presentation: "action"},
                {key: "caffeine", module: "caffeine", enabled: true, presentation: "action"},
                {key: "lock", module: "lock", enabled: true, presentation: "action"},
                {key: "hibernate", module: "hibernate", enabled: true, presentation: "action"},
                {key: "shutdown", module: "shutdown", enabled: true, presentation: "action"}]}}
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
    if (input.schemaVersion > 4) return {future: true, document: clone(input), effective: defaults(), errors: [], warnings: []}
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

    const visualDefaults = defaults().appearance.visual
    const numberRanges = {statusIconSize: [16, 28], tileBackgroundShade: [-1, 1],
        tileBorderShade: [-1, 1], tileBorderWidth: [0, 6],
        controlOffOpacity: [0.1, 0.6], sliderBorderWidth: [0, 5], avatarBorderWidth: [0, 5]}
    for (const key of Object.keys(visualDefaults)) {
        const value = a.visual[key], range = numberRanges[key]
        const good = range ? typeof value === "number" && isFinite(value) && value >= range[0] && value <= range[1]
            : ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "accent",
                "blue", "lavender", "green", "yellow", "peach", "red", "teal", "border"].indexOf(value) >= 0
        if (!good) { valid(false, "appearance.visual." + key, null); a.visual[key] = visualDefaults[key] }
    }
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
    }
    function validIconDescriptor(value) {
        return object(value)
            && (value.colorMode === undefined
                || ["semantic", "fixed"].indexOf(value.colorMode) >= 0)
            && (value.source === "user"
            ? typeof value.assetId === "string" && /^icon:[a-f0-9]{64}\.svg$/.test(value.assetId)
            : value.source === "bundled" && typeof value.pack === "string" && value.pack.length
                && typeof value.icon === "string" && value.icon.length)
    }
    if (!object(effective.icons.modulePacks)) {
        valid(false, "icons.modulePacks", {}); effective.icons.modulePacks = {}
    } else for (const key of Object.keys(effective.icons.modulePacks)) {
        if (!/^[a-z0-9-]+$/.test(key) || typeof effective.icons.modulePacks[key] !== "string") {
            errors.push("icons.modulePacks." + key + ": invalid value"); delete effective.icons.modulePacks[key]
        }
    }
    if (!object(effective.icons.overrides) || !object(effective.icons.overrides.global)
            || !object(effective.icons.overrides.modules)) {
        valid(false, "icons.overrides", {}); effective.icons.overrides = defaults().icons.overrides
    } else {
        for (const role of Object.keys(effective.icons.overrides.global)) {
            if (!/^[a-z0-9-]+$/.test(role) || !validIconDescriptor(effective.icons.overrides.global[role])) {
                errors.push("icons.overrides.global." + role + ": invalid value")
                delete effective.icons.overrides.global[role]
            }
        }
        for (const moduleId of Object.keys(effective.icons.overrides.modules)) {
            const roles = effective.icons.overrides.modules[moduleId]
            if (!/^[a-z0-9-]+$/.test(moduleId) || !object(roles)) {
                errors.push("icons.overrides.modules." + moduleId + ": invalid value")
                delete effective.icons.overrides.modules[moduleId]; continue
            }
            for (const role of Object.keys(roles)) if (!/^[a-z0-9-]+$/.test(role) || !validIconDescriptor(roles[role])) {
                errors.push("icons.overrides.modules." + moduleId + "." + role + ": invalid value")
                delete roles[role]
            }
        }
    }
    function textField(section, key, maximum) {
        const value = effective[section][key]
        if (typeof value !== "string" || value.length > maximum) {
            valid(false, section + "." + key, ""); effective[section][key] = ""
        }
    }
    textField("profile", "displayName", 80)
    textField("profile", "subtitle", 160)
    if (["greeting", "custom"].indexOf(effective.profile.subtitleMode) < 0) {
        valid(false, "profile.subtitleMode", "greeting"); effective.profile.subtitleMode = "greeting"
    }
    if (effective.profile.avatar !== null
            && (typeof effective.profile.avatar !== "string"
                || !/^avatar:[a-f0-9]{64}\.(png|jpg|webp)$/.test(effective.profile.avatar))) {
        valid(false, "profile.avatar", null); effective.profile.avatar = null
    }
    if (typeof effective.media.enabled !== "boolean") {
        valid(false, "media.enabled", true); effective.media.enabled = true
    }
    if (effective.media.preferredPlayer !== null
            && (typeof effective.media.preferredPlayer !== "string" || effective.media.preferredPlayer.length > 256)) {
        valid(false, "media.preferredPlayer", null); effective.media.preferredPlayer = null
    }
    if (["collapse", "minimal"].indexOf(effective.media.emptyState) < 0) {
        valid(false, "media.emptyState", "collapse"); effective.media.emptyState = "collapse"
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
    for (const section of ["profile", "quickControls", "sliders", "media", "actions"]) {
        if (typeof cc.sections[section] !== "boolean") {
            valid(false, "controlCentre.sections." + section, defaults().controlCentre.sections[section])
            cc.sections[section] = defaults().controlCentre.sections[section]
        }
    }
    if (!Number.isInteger(cc.columns) || cc.columns < 1 || cc.columns > 16) {
        valid(false, "controlCentre.columns", 4); cc.columns = 4
    }
    if (!Number.isInteger(cc.actionColumns) || cc.actionColumns < 1 || cc.actionColumns > 16) {
        valid(false, "controlCentre.actionColumns", 6); cc.actionColumns = 6
    }
    const supportedByPresentation = {
        tile: ["wifi", "bluetooth", "power-saver", "airplane-mode", "battery", "settings", "vpn", "dnd", "caffeine"],
        slider: ["volume", "brightness"],
        action: ["vpn", "dnd", "caffeine", "lock", "hibernate", "shutdown"]
    }
    for (const group of ["controls", "sliders", "actions"]) {
        const keys = [], modules = []
        const presentation = group === "controls" ? "tile" : group === "sliders" ? "slider" : "action"
        if (!Array.isArray(cc[group])) { valid(false, "controlCentre." + group, []); cc[group] = defaults().controlCentre[group] }
        cc[group] = cc[group].filter(entry => {
            if (!object(entry) || typeof entry.key !== "string" || !entry.key.length
                || typeof entry.module !== "string" || typeof entry.enabled !== "boolean"
                || entry.presentation !== presentation || keys.indexOf(entry.key) >= 0
                || modules.indexOf(entry.module) >= 0) {
                errors.push("Invalid/duplicate controlCentre." + group + " entry"); return false
            }
            keys.push(entry.key); modules.push(entry.module)
            const supported = supportedByPresentation[presentation]
            if (supported.indexOf(entry.module) < 0) { warnings.push("Unavailable CC module: " + entry.module); return false }
            if (group === "controls" && controlAccentRoles.indexOf(entry.accent) < 0) {
                errors.push("controlCentre.controls." + entry.key + ".accent: invalid value")
                entry.accent = controlAccentDefaults[entry.module] || "lavender"
            }
            return true
        })
    }
    return {future: false, document: document, effective: effective, errors: errors, warnings: warnings}
}
