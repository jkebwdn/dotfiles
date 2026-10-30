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
    if (doc.schemaVersion === 9) doc.schemaVersion = 10
    if (doc.schemaVersion === 10) {
        // Preserve the previous album-art action-role override on upgrade, while
        // making future album-art edits independent. Missing values follow Master.
        if (doc.appearance && doc.appearance.roundness && doc.appearance.roundness.roles) {
            const roles = doc.appearance.roundness.roles
            if (roles.albumArt === undefined) roles.albumArt = roles.action === undefined ? null : roles.action
        }
        doc.schemaVersion = 11
    }
    // New visual/retention fields are default-filled without rewriting v11 values.
    if (doc.schemaVersion === 11) doc.schemaVersion = 12
    if (doc.schemaVersion === 12) {
        if (doc.icons && typeof doc.icons === "object") {
            delete doc.icons.overrides
            delete doc.icons.modulePacks
        }
        doc.appearance = doc.appearance || {}
        if (doc.appearance.mediaProgressRole === undefined) doc.appearance.mediaProgressRole = "accent"
        if (doc.appearance.hubToggleRole === undefined) doc.appearance.hubToggleRole = "accent"
        doc.schemaVersion = 13
    }
    if (doc.schemaVersion === 13) doc.schemaVersion = 14
    if (doc.schemaVersion === 14) doc.schemaVersion = 15
    if (doc.schemaVersion === 15) {
        doc.appearance = doc.appearance || {}
        if (doc.appearance.hubSelectionRole === undefined)
            doc.appearance.hubSelectionRole = doc.appearance.hubToggleRole === undefined ? "accent" : doc.appearance.hubToggleRole
        doc.schemaVersion = 16
    }
    if (doc.schemaVersion === 16) doc.schemaVersion = 17
    if (doc.schemaVersion === 17) {
        doc.controlCentre = doc.controlCentre || {}
        const cc = doc.controlCentre, flags = cc.sections || {}
        if (cc.layout === undefined) {
            const map = {profile:"profile", controls:"quickControls", sliders:"sliders", actions:"actions", media:"media"}
            cc.layout = ["profile", "controls", "sliders", "actions", "media"].filter(id =>
                flags[map[id]] !== false && !(id === "media" && doc.media && doc.media.enabled === false))
        }
        delete cc.sections
        if (doc.media) delete doc.media.enabled
        doc.appearance = doc.appearance || {}
        const roundness = doc.appearance.roundness
        if (roundness && roundness.roles && roundness.roles.secondaryControl === undefined)
            roundness.roles.secondaryControl = roundness.roles.action === undefined ? null : roundness.roles.action
        doc.schemaVersion = 18
    }
    if (doc.schemaVersion === 18) {
        if (doc.applicationAppearance === undefined) doc.applicationAppearance = {managed: false, backgroundOpacity: 1.0, blurEnabled: true}
        doc.appearance = doc.appearance || {}
        if (doc.appearance.globalBlur === undefined) doc.appearance.globalBlur = {managed: false, size: 8}
        doc.schemaVersion = 19
    }
    if (doc.schemaVersion === 19) {
        if (doc.lockScreen === undefined) doc.lockScreen = {layoutVersion:1, preset:"centered", elements:{}}
        doc.schemaVersion = 20
    }
    if (doc.schemaVersion === 20) {
        if (doc.lockScreen && typeof doc.lockScreen === "object" && !doc.lockScreen.effects)
            doc.lockScreen.effects = {credential:"dots",avatar:"plain",weather:"standard",media:"compact",location:false,artwork:true,depth:false,blur:true,date:true,curated:false}
        doc.schemaVersion = 21
    }
    if (doc.schemaVersion === 21) doc.schemaVersion = 22
    // Retire the native-preview visibility preference; placement owns defaults.
    if (doc.schemaVersion === 22 && doc.bar && typeof doc.bar === "object")
        delete doc.bar.trayVisibility
    return doc
}
