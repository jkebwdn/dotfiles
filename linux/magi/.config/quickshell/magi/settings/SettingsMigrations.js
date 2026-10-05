// Pure migrations. Keep source preferences and unknown keys; never write here.
function migrate(input) {
    const doc = JSON.parse(JSON.stringify(input))
    if (doc.schemaVersion === undefined || doc.schemaVersion === 0) {
        if (doc.appearance !== undefined || doc.bar !== undefined)
            throw new Error("Mixed legacy and versioned settings require explicit repair")
        const palette = doc.palette === undefined ? "catppuccin" : doc.palette
        doc.appearance = {theme: palette === "catppuccin" ? "catppuccin-mocha"
            : palette === "everforest" ? "everforest-dark-hard" : palette}
        doc.bar = {
            left: doc.barLeftPlugins === undefined ? ["clock", "date"] : doc.barLeftPlugins,
            center: doc.barCenterPlugins === undefined ? [] : doc.barCenterPlugins,
            right: doc.barRightPlugins === undefined
                ? ["volume", "wifi", "bluetooth", "battery", "controlcentre"] : doc.barRightPlugins
        }
        delete doc.palette
        delete doc.barLeftPlugins
        delete doc.barCenterPlugins
        delete doc.barRightPlugins
        doc.schemaVersion = 1
    }
    if (doc.schemaVersion === 1) {
        doc.profile = doc.profile || {displayName: "", subtitle: "", avatar: null}
        doc.media = doc.media || {enabled: true, preferredPlayer: null, emptyState: "collapse"}
        doc.controlCentre = doc.controlCentre || {}
        doc.controlCentre.sections = doc.controlCentre.sections || {
            profile: true, quickControls: true, sliders: true, media: true, actions: false
        }
        doc.schemaVersion = 2
    }
    if (doc.schemaVersion === 2) {
        doc.controlCentre = doc.controlCentre || {}
        doc.controlCentre.sections = doc.controlCentre.sections || {}
        doc.controlCentre.sections.actions = true
        doc.controlCentre.actionColumns = doc.controlCentre.actionColumns || 6
        const legacy = Array.isArray(doc.controlCentre.controls) ? doc.controlCentre.controls : []
        const legacyModules = legacy.map(entry => entry && entry.module).sort().join(",")
        // The v2 built-in lineup was often reordered while evaluating Settings.
        // Treat that same four-module set as the old default; genuinely different
        // lineups remain user-owned and are validated without guessing intent.
        if (legacyModules === "battery,bluetooth,volume,wifi"
                && legacy.every(entry => entry && entry.enabled === true && entry.presentation === "tile")) {
            doc.controlCentre.controls = [
                {key: "network", module: "wifi", enabled: true, presentation: "tile"},
                {key: "wireless", module: "bluetooth", enabled: true, presentation: "tile"},
                {key: "power-saver", module: "power-saver", enabled: true, presentation: "tile"},
                {key: "airplane-mode", module: "airplane-mode", enabled: true, presentation: "tile"}
            ]
        }
        doc.controlCentre.actions = Array.isArray(doc.controlCentre.actions) ? doc.controlCentre.actions : [
            {key: "vpn", module: "vpn", enabled: true, presentation: "action"},
            {key: "dnd", module: "dnd", enabled: true, presentation: "action"},
            {key: "caffeine", module: "caffeine", enabled: true, presentation: "action"},
            {key: "lock", module: "lock", enabled: true, presentation: "action"},
            {key: "hibernate", module: "hibernate", enabled: true, presentation: "action"},
            {key: "shutdown", module: "shutdown", enabled: true, presentation: "action"}
        ]
        doc.schemaVersion = 3
    }
    if (doc.schemaVersion === 3) {
        const accents = {wifi: "teal", bluetooth: "blue", "power-saver": "green",
            "airplane-mode": "lavender", battery: "red", settings: "lavender",
            vpn: "blue", dnd: "lavender", caffeine: "yellow"}
        doc.controlCentre = doc.controlCentre || {}
        if (Array.isArray(doc.controlCentre.controls)) {
            doc.controlCentre.controls = doc.controlCentre.controls.map(entry => {
                if (!entry || typeof entry !== "object" || entry.accent !== undefined)
                    return entry
                const next = Object.assign({}, entry)
                next.accent = accents[next.module] || "lavender"
                return next
            })
        }
        doc.schemaVersion = 4
    }
    if (doc.schemaVersion === 4) {
        // Add the new entry without disturbing existing placement/order/preferences.
        if (doc.bar && ["left", "center", "right"].every(k => Array.isArray(doc.bar[k]))
                && !["left", "center", "right"].some(k => doc.bar[k].indexOf("notifications") >= 0)) {
            const index = doc.bar.right.indexOf("controlcentre")
            doc.bar.right.splice(index < 0 ? doc.bar.right.length : index, 0, "notifications")
        }
        doc.schemaVersion = 5
    }
    if (doc.schemaVersion === 5) {
        // No clipboard data is migrated/imported; history persistence stays opt-in.
        doc.schemaVersion = 6
    }
    if (doc.schemaVersion === 6) doc.schemaVersion = 7
    if (doc.schemaVersion === 7) doc.schemaVersion = 8
    if (doc.schemaVersion === 8) doc.schemaVersion = 9
    return doc
}
