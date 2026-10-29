// MAGI's preference schema, not system or menu-session state.
// Shared stable catalogue data: validation and runtime rendering use one list.
function controlDefinitions() {
    return [
        {id:"wifi", label:"Wi-Fi", icon:"wifi", accent:"teal", detail:"wifi", presentations:["tile","detail"]},
        {id:"bluetooth", label:"Bluetooth", icon:"bluetooth", accent:"blue", detail:"bluetooth", presentations:["tile","detail"]},
        {id:"power-saver", label:"Low Power", icon:"power-saver", accent:"green", detail:"", presentations:["tile"]},
        {id:"airplane-mode", label:"Airplane", icon:"airplane-mode", accent:"lavender", detail:"", presentations:["tile"]},
        {id:"battery", label:"Battery status", icon:"battery", accent:"red", detail:"", presentations:["tile"]},
        {id:"settings", route:"settings", label:"Settings", icon:"settings", accent:"lavender", detail:"", presentations:["tile","action"]},
        {id:"volume", label:"Volume", icon:"volume", accent:"peach", detail:"", presentations:["slider"]},
        {id:"brightness", label:"Brightness", icon:"brightness", accent:"yellow", detail:"", presentations:["slider"]},
        {id:"vpn", label:"VPN", icon:"vpn", accent:"blue", detail:"", presentations:["tile","action"]},
        {id:"dnd", label:"Do Not Disturb", icon:"dnd", accent:"lavender", detail:"", presentations:["tile","action"]},
        {id:"caffeine", label:"Caffeine", icon:"caffeine", accent:"yellow", detail:"", presentations:["tile","action"]},
        {id:"lock", route:"system", label:"Lock", icon:"lock", accent:"blue", detail:"", presentations:["action"]},
        {id:"hibernate", route:"system", label:"Hibernate", icon:"hibernate", accent:"peach", detail:"", presentations:["action"], danger:true, confirmation:true},
        {id:"shutdown", route:"system", label:"Shutdown", icon:"shutdown", accent:"red", detail:"", presentations:["action"], danger:true, confirmation:true},
        {id:"reboot", label:"Reboot", icon:"reboot", accent:"red", presentations:["action"], route:"system", danger:true, confirmation:true},
        {id:"apps", label:"Applications", icon:"apps", accent:"lavender", presentations:["action"], route:"hub", mode:"apps"},
        {id:"notifications", label:"Notifications", icon:"notifications", accent:"lavender", presentations:["action"], route:"hub", mode:"notifications"},
        {id:"emoji", label:"Emoji", icon:"emoji", accent:"yellow", presentations:["action"], route:"hub", mode:"emoji"},
        {id:"clipboard", label:"Clipboard", icon:"clipboard", accent:"blue", presentations:["action"], route:"hub", mode:"clipboard"}
    ].map(d => {
        if (!d.presentations.includes("slider")) d.presentations = [...new Set(d.presentations.concat(["tile", "action"]))]
        return d
    })
}
const barIds = ["clock", "date", "workspaces", "volume", "wifi", "bluetooth", "battery", "notifications", "clipboard", "controlcentre", "tray"]
const radiusRoles = ["barPill", "surface", "controlTile", "slider", "action", "avatar", "albumArt", "hubSelector", "secondaryControl"]
const controlAccentRoles = ["red", "peach", "yellow", "green", "teal", "blue", "lavender"]
const controlAccentDefaults = {wifi: "teal", bluetooth: "blue", "power-saver": "green",
    "airplane-mode": "lavender", battery: "red", settings: "lavender", vpn: "blue",
    dnd: "lavender", caffeine: "yellow"}
function defaults() {
    return {schemaVersion: 22,
        lockScreen: {layoutVersion:1, preset:"centered", elements:{}, effects:{credential:"dots",avatar:"plain",weather:"standard",media:"compact",location:false,artwork:true,depth:false}},
        applicationAppearance: {managed: false, backgroundOpacity: 1.0, blurEnabled: true},
        appearance: {globalBlur: {managed: false, size: 8}, controlCentreBackgroundRole: "surface", mediaProgressRole: "accent", hubToggleRole: "accent", hubSelectionRole: "accent", navigationAccent: "accent", toggleStyle: "pill", theme: "catppuccin-mocha", roundness: {master: 1,
            roles: {barPill: null, surface: null, controlTile: null, slider: null, action: null, avatar: null, albumArt: null, hubSelector: null, secondaryControl: null}},
            surfaceBorders: {role:"border", width:1, controlcentre:false, wifi:false, bluetooth:false, volume:false, hubContent:true, hubSelector:true},
            notificationBorders: {role:"border", width:1, toasts:true, history:true, clipboard:true},
            profileBackground: {enabled:false, role:"elevated"},
            visual: {profileGreetingWeight: 700, profileWeatherWeight: 400, profileThirdLineWeight: 400,
                mediaTitleSize: 13, mediaArtistSize: 11, mediaTitleWeight: 700, mediaArtistWeight: 400, mediaProgressBorderWidth: 2,
                profileGreetingSize: 16, profileWeatherSize: 12, profileThirdLineSize: 11,
                profileControlsGap: 20, controlsSlidersGap: 20, slidersActionsGap: 20, actionsMediaGap: 20, mediaSectionGap: 20,
                primaryIconSize: 32, primaryContainerSize: 68, secondaryIconSize: 32, secondaryContainerSize: 38, secondaryBackgroundOpacity: .18, secondaryBorderWidth: 0, secondaryBorder: "border",
                avatarSize: 76, mediaArtworkSize: 80, statusIconSize: 18, tileBackgroundShade: 0.28, tileBorderShade: 0.48,
                tileBorderWidth: 4, controlOn: "text",
                controlOff: "background", controlOffOpacity: 0.28, controlOffShade: 0,
                secondaryOn: "text", secondaryOff: "overlay", secondaryOffShade: 0,
                secondaryOffOpacity: 0.6,
                sliderTrack: "elevated", sliderFill: "overlay", sliderBorder: "lavender",
                sliderBorderWidth: 2, avatarBorderWidth: 2}},
        powerIdle: {lockAfter: 300, displayOffAfter: 600, suspendAfter: 0},
        icons: {pack: "magi-default"},
        weather: {enabled: false, location: "", units: "metric"},
        profile: {greetingStyle: "compact", displayName: "", subtitle: "", subtitleMode: "greeting", avatar: null},
        hub: {selectorPosition:"below", verticalPosition:2/3},
        media: {controlsVisibility:"active", preferredPlayer: null, emptyState: "collapse"},
        calendar: {firstDay: "locale", showWeekNumbers: false, showAdjacentDays: true,
            density: "comfortable", timeFormat: "24h", dateFormat: "numeric"},
        wallpaper: {enabled: true, directories: ["~/Pictures/wallpapers"], thumbnailSize: 220},
        emoji: {enabled: true, gridColumns: 8, emojiSize: 28, showCategories: true,
            recentLimit: 24, recents: [], closeOnSelect: true},
        launcher: {enabled: true, hiddenIds: [], layout: "list", panelWidth: 420, gridWidth: 720,
            rowHeight: 56, iconSize: 32, visibleRows: 6, gridColumns: 5,
            showLabels: true, showSubtitles: true, showIcons: true,
            position: "center", headerEnabled: false, headerImage: "",
            headerPosition: "top", headerFit: "cover", headerRadius: 12, headerBorderWidth: 1, headerBorderRole: "border"},
        clipboard: {enabled: true, historyLimit: 100, persistHistory: false,
            includeImages: true, includeFiles: true},
        notifications: {retentionHours:6, enabled: true, toastsEnabled: true, dnd: false,
            fallbackTimeout: 5000, maxVisible: 3, historyLimit: 100,
            showBody: true, criticalBypassDnd: true},
        bar: {visual: {host: {enabled:false, role:"surface", opacity:1},
            statusPills: {enabled:true, role:"surface", opacity:1},
            workspacePills: {roundness:null}},
            modules: {wifi: {accentRole:"accent"}, bluetooth: {accentRole:"accent"}}, position: "top", horizontalInset: 0, edgeOffset: 0, externalDisplays: false, left: ["clock", "date"], center: ["workspaces"],
            right: ["volume", "wifi", "bluetooth", "battery", "controlcentre"]},
        controlCentre: {columns: 4, actionColumns: 6, layout: ["profile", "controls", "sliders", "actions", "media"], controls: [
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
    if (input.schemaVersion > 22) return {future: true, document: clone(input), effective: defaults(), errors: [], warnings: []}
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
    const layout = effective.lockScreen
    const compact = layout.layoutVersion === 1 && layout.preset === "centered"
        && object(layout.elements) && Object.keys(layout.elements).length === 0
    let layoutValid = compact
    if (!compact && layout.layoutVersion === 1 && ["screen","composition"].includes(layout.space)
        && ["centered","editorial","corner","split","minimal","custom"].includes(layout.preset)
        && object(layout.elements) && Object.keys(layout.elements).every(id => ["time","identity","authentication","weather","media"].includes(id))) {
        const seen = []
        layoutValid = ["time","identity","authentication","weather","media"].every(id => {
            if (["weather","media"].includes(id) && layout.elements[id] === undefined) return true
            const e = layout.elements[id]
            if (!object(e) || !["top-left","top-center","top-right","center-left","center","center-right","bottom-left","bottom-center","bottom-right"].includes(e.anchor)
                || !["left","center","right"].includes(e.alignment) || typeof e.visible !== "boolean"
                || !Number.isInteger(e.z) || e.z < -2 || e.z > 2 || seen.includes(e.z)) return false
            seen.push(e.z)
            return ["offsetX","offsetY","size"].every(k => typeof e[k] === "number" && isFinite(e[k]))
                && Math.abs(e.offsetX) <= 1 && Math.abs(e.offsetY) <= 1 && e.size >= .75 && e.size <= 1.25
                && (id !== "authentication" || (e.visible && e.z === 2 && e.size >= 1))
        })
    }
    if (!layoutValid) { errors.push("lockScreen: invalid layout; using Centered"); effective.lockScreen = defaults().lockScreen }
    const fx = effective.lockScreen.effects
    for (const [key,choices] of Object.entries({credential:["dots","line","segments","ring","minimal"],avatar:["plain","ring","glow","frame"],weather:["compact","standard","minimal"],media:["compact","artwork","minimal"]})) {
        if (!choices.includes(fx[key])) { errors.push("lockScreen.effects."+key+": invalid value"); fx[key]=defaults().lockScreen.effects[key] }
    }
    for (const key of ["location","artwork","depth"]) if (typeof fx[key] !== "boolean") {errors.push("lockScreen.effects."+key+": invalid value");fx[key]=defaults().lockScreen.effects[key]}
    const applicationPolicy = effective.applicationAppearance
    for (const key of ["managed", "blurEnabled", "backgroundOpacity"]) {
        const value = applicationPolicy[key]
        const good = key !== "backgroundOpacity" ? typeof value === "boolean"
            : typeof value === "number" && isFinite(value) && value >= .5 && value <= 1
        if (!good) { errors.push("applicationAppearance." + key + ": invalid value"); applicationPolicy[key] = defaults().applicationAppearance[key] }
    }
    const globalBlur = effective.appearance.globalBlur
    if (typeof globalBlur.managed !== "boolean") { errors.push("appearance.globalBlur.managed: invalid value"); globalBlur.managed = false }
    if (!Number.isInteger(globalBlur.size) || globalBlur.size < 1 || globalBlur.size > 40) { errors.push("appearance.globalBlur.size: invalid value"); globalBlur.size = 8 }
    const durations = [0,60,120,300,600,900,1800,3600]
    const suspendDurations = [0,300,600,900,1800,3600,7200]
    for (const key of ["lockAfter", "displayOffAfter", "suspendAfter"]) {
        const value = effective.powerIdle[key]
        if (!Number.isInteger(value) || !(key === "suspendAfter" ? suspendDurations : durations).includes(value)) {
            errors.push("powerIdle." + key + ": choose a supported duration")
            effective.powerIdle[key] = defaults().powerIdle[key]
        }
    }
    const enabledTimers = [effective.powerIdle.lockAfter, effective.powerIdle.displayOffAfter, effective.powerIdle.suspendAfter].filter(v => v > 0)
    if (enabledTimers.some((v,i) => i > 0 && v < enabledTimers[i-1]))
        errors.push("Enabled timers must run in order: lock, display off, then suspend.")
    // Retired fields are never part of effective runtime configuration.
    delete effective.icons.overrides
    delete effective.icons.modulePacks
    const a = effective.appearance
    if (typeof a.theme !== "string" || !a.theme.length) { valid(false, "appearance.theme", ""); a.theme = "catppuccin-mocha" }

    const semanticRoles = ["background","surface","elevated","overlay","text","subtext","muted","accent","blue","lavender","green","yellow","peach","red","teal","border"]
    for (const family of ["host", "statusPills"]) {
        const style = effective.bar.visual[family], fallback = defaults().bar.visual[family]
        for (const key of ["enabled", "role", "opacity"]) {
            const value = style[key]
            const good = key === "enabled" ? typeof value === "boolean"
                : key === "role" ? semanticRoles.includes(value)
                : typeof value === "number" && isFinite(value) && value >= 0 && value <= 1
            if (!good) { errors.push("bar.visual." + family + "." + key + ": invalid value"); style[key] = fallback[key] }
        }
    }
    const workspaceRadius = effective.bar.visual.workspacePills.roundness
    if (workspaceRadius !== null && !(typeof workspaceRadius === "number" && isFinite(workspaceRadius) && workspaceRadius >= 0 && workspaceRadius <= 2)) {
        errors.push("bar.visual.workspacePills.roundness: invalid value")
        effective.bar.visual.workspacePills.roundness = null
    }
    for (const id of ["wifi", "bluetooth"]) {
        if (!semanticRoles.includes(effective.bar.modules[id].accentRole)) {
            errors.push("bar.modules." + id + ".accentRole: invalid value")
            effective.bar.modules[id].accentRole = "accent"
        }
    }
    // Optional item overrides: absent/null keeps the accepted family/foreground.
    // Keep the sparse module map; old documents and appearance resolve unchanged.
    for (const id of barIds.filter(id => id !== "workspaces")) {
        const style = effective.bar.modules[id]
        if (style === undefined) continue
        if (!object(style)) { errors.push("bar.modules." + id + ": expected object"); delete effective.bar.modules[id]; continue }
        const keys = id === "battery" ? ["foregroundRole", "backgroundRole", "percentageBackgroundRole", "percentageForegroundRole"] : ["foregroundRole", "backgroundRole"]
        for (const key of keys) if (style[key] !== undefined && style[key] !== null && !semanticRoles.includes(style[key])) {
            errors.push("bar.modules." + id + "." + key + ": invalid role")
            delete style[key]
        }
        const shadeKeys = ["foregroundShade", "foregroundOffShade", "backgroundShade"]
            .concat(id === "battery" ? ["percentageBackgroundShade", "percentageForegroundShade"] : [])
        for (const key of shadeKeys) if (style[key] !== undefined && style[key] !== null
            && !(typeof style[key] === "number" && isFinite(style[key]) && style[key] >= -1 && style[key] <= 1)) {
            errors.push("bar.modules." + id + "." + key + ": invalid shade")
            delete style[key]
        }
        if (id === "battery" && style.showPercentage !== undefined && typeof style.showPercentage !== "boolean") {
            errors.push("bar.modules.battery.showPercentage: expected boolean"); delete style.showPercentage
        }
    }
    // Optional expanded-header presentation; schema-22 documents remain sparse.
    if (a.statusRowRole !== undefined && a.statusRowRole !== null && !semanticRoles.includes(a.statusRowRole)) {
        errors.push("appearance.statusRowRole: invalid role")
        delete a.statusRowRole
    }
    if (a.statusRowShade !== undefined && a.statusRowShade !== null
        && !(typeof a.statusRowShade === "number" && isFinite(a.statusRowShade) && a.statusRowShade >= -1 && a.statusRowShade <= 1)) {
        errors.push("appearance.statusRowShade: invalid shade")
        delete a.statusRowShade
    }
    if (!semanticRoles.includes(a.controlCentreBackgroundRole)) {
        errors.push("appearance.controlCentreBackgroundRole: invalid role")
        a.controlCentreBackgroundRole = "surface"
    }
    for (const key of ["mediaProgressRole", "hubToggleRole", "hubSelectionRole"]) {
        if (["accent", "blue", "lavender", "green", "yellow", "peach", "red", "teal"].indexOf(a[key]) < 0) {
            warnings.push("appearance." + key + ": using accent")
            a[key] = "accent"
        }
    }
    for (const key of ["navigationAccent", "toggleStyle"]) {
        const values = key === "navigationAccent" ? semanticRoles : ["pill", "filled", "minimal"]
        if (values.indexOf(a[key]) < 0) { valid(false, "appearance." + key, null); a[key] = defaults().appearance[key] }
    }
    if (["compact", "friendly"].indexOf(effective.profile.greetingStyle) < 0) {
        valid(false, "profile.greetingStyle", null); effective.profile.greetingStyle = "compact"
    }
    for (const key of Object.keys(defaults().weather)) {
        const value = effective.weather[key]
        const good = key === "enabled" ? typeof value === "boolean" : key === "units"
            ? ["metric", "imperial"].indexOf(value) >= 0
            : typeof value === "string" && value.length <= 160 && !/[\x00-\x1f]/.test(value)
        if (!good) { valid(false, "weather." + key, null); effective.weather[key] = defaults().weather[key] }
    }
    for (const group of ["surfaceBorders", "notificationBorders", "profileBackground"]) {
        const fallback = defaults().appearance[group]
        for (const key of Object.keys(fallback)) {
            const value = a[group][key]
            const good = key === "role" ? semanticRoles.indexOf(value) >= 0
                : key === "width" ? typeof value === "number" && isFinite(value) && value >= 0 && value <= 5
                : typeof value === "boolean"
            if (!good) { valid(false, "appearance." + group + "." + key, null); a[group][key] = fallback[key] }
        }
    }
    if (["above","below"].indexOf(effective.hub.selectorPosition) < 0) {
        valid(false,"hub.selectorPosition",null); effective.hub.selectorPosition = "below"
    }
    const position = effective.hub.verticalPosition
    if (typeof position !== "number" || !isFinite(position) || position < .1 || position > .9) {
        valid(false,"hub.verticalPosition",null); effective.hub.verticalPosition = 2/3
    }
    if (["always","active","playing","hidden"].indexOf(effective.media.controlsVisibility) < 0) {
        valid(false,"media.controlsVisibility",null); effective.media.controlsVisibility = "active"
    }
    const visualDefaults = defaults().appearance.visual
    const integerVisual = ["mediaTitleSize", "mediaArtistSize", "profileGreetingSize", "profileWeatherSize", "profileThirdLineSize",
        "profileControlsGap", "controlsSlidersGap", "slidersActionsGap", "actionsMediaGap", "mediaSectionGap"]
    const numberRanges = {mediaTitleSize:[10,24], mediaArtistSize:[10,20], mediaProgressBorderWidth:[0,5], profileGreetingSize: [12, 24], profileWeatherSize: [10, 20], profileThirdLineSize: [10, 20],
        profileControlsGap: [0, 48], controlsSlidersGap: [0, 48], slidersActionsGap: [0, 48], actionsMediaGap: [0, 48], mediaSectionGap: [0, 48], primaryIconSize: [16, 48], primaryContainerSize: [60, 96],
        secondaryIconSize: [16, 36], secondaryContainerSize:[32,72], secondaryBackgroundOpacity:[0,1], secondaryBorderWidth:[0,6], avatarSize: [48, 112], mediaArtworkSize: [48, 112], statusIconSize: [16, 28], tileBackgroundShade: [-1, 1],
        tileBorderShade: [-1, 1], tileBorderWidth: [0, 6],
        controlOffOpacity: [0, 1], controlOffShade: [-1, 1], secondaryOffShade: [-1, 1],
        secondaryOffOpacity: [0, 1], sliderBorderWidth: [0, 5], avatarBorderWidth: [0, 5]}
    for (const key of Object.keys(visualDefaults)) {
        const value = a.visual[key], range = numberRanges[key]
        const good = key.endsWith("Weight") ? [400,700].indexOf(value) >= 0 : range ? (integerVisual.indexOf(key) < 0 || Number.isInteger(value)) && typeof value === "number" && isFinite(value) && value >= range[0] && value <= range[1]
            : ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "accent",
                "blue", "lavender", "green", "yellow", "peach", "red", "teal", "border"].indexOf(value) >= 0
        if (!good) { valid(false, "appearance.visual." + key, null); a.visual[key] = visualDefaults[key] }
    }
    const notificationDefaults = defaults().notifications
    const notificationRanges = {fallbackTimeout: [1000, 30000], maxVisible: [1, 4], historyLimit: [10, 500]}
    for (const key of Object.keys(notificationDefaults)) {
        const value = effective.notifications[key], range = notificationRanges[key]
        if (key === "retentionHours" ? [0,2,6,24].indexOf(value) < 0 : range ? !Number.isInteger(value) || value < range[0] || value > range[1]
                : typeof value !== "boolean") {
            valid(false, "notifications." + key, null)
            effective.notifications[key] = notificationDefaults[key]
        }
    }
    const calendarDefaults = defaults().calendar
    const calendarEnums = {firstDay:["locale","monday","sunday"], density:["compact","comfortable"],
        timeFormat:["24h","12h","locale"], dateFormat:["numeric","iso","locale"]}
    for (const key of Object.keys(calendarDefaults)) {
        const value = effective.calendar[key], values = calendarEnums[key]
        if (values ? values.indexOf(value) < 0 : typeof value !== "boolean") {
            valid(false, "calendar." + key, null); effective.calendar[key] = calendarDefaults[key]
        }
    }
    const wallpaperDefaults = defaults().wallpaper
    for (const key of Object.keys(wallpaperDefaults)) {
        const value = effective.wallpaper[key]
        const good = key === "enabled" ? typeof value === "boolean"
            : key === "thumbnailSize" ? Number.isInteger(value) && value >= 160 && value <= 320
            : Array.isArray(value) && value.length <= 16 && value.every(p => typeof p === "string"
                && p.length > 0 && p.length <= 4096 && (p[0] === "/" || p.startsWith("~/"))
                && !/[\u0000-\u001f\u007f]/.test(p))
                && new Set(value).size === value.length
        if (!good) { valid(false, "wallpaper." + key, null); effective.wallpaper[key] = wallpaperDefaults[key] }
    }
    const emojiDefaults = defaults().emoji
    const emojiRanges = {gridColumns:[4,12], emojiSize:[20,48], recentLimit:[0,60]}
    for (const key of Object.keys(emojiDefaults)) {
        const value = effective.emoji[key], range = emojiRanges[key]
        const good = key === "recents" ? Array.isArray(value) && value.length <= 60
            && value.every(id => typeof id === "string" && id.length <= 160 && /^[0-9A-F]{4,6}(?:-[0-9A-F]{4,6})*$/.test(id))
            && new Set(value).size === value.length
            : range ? Number.isInteger(value) && value >= range[0] && value <= range[1] : typeof value === "boolean"
        if (!good) { valid(false, "emoji." + key, null); effective.emoji[key] = emojiDefaults[key] }
    }
    effective.emoji.recents = effective.emoji.recents.slice(0, effective.emoji.recentLimit)
    const launcherDefaults = defaults().launcher
    const launcherRanges = {panelWidth:[320,800], gridWidth:[420,1200], rowHeight:[40,96],
        iconSize:[20,64], visibleRows:[3,12], gridColumns:[3,8], headerRadius:[0,75], headerBorderWidth:[0,8]}
    const launcherEnums = {layout:["list","grid"], position:["center","top"], headerPosition:["top","bottom"], headerFit:["cover","contain"], headerBorderRole:["border","rim","accent","subtext"]}
    for (const key of Object.keys(launcherDefaults)) {
        const value = effective.launcher[key], range = launcherRanges[key], values = launcherEnums[key]
        const good = key === "hiddenIds" ? Array.isArray(value) && value.every(id =>
            typeof id === "string" && id.length > 8 && id.length <= 1024
            && id.endsWith(".desktop") && !/[\/\\\u0000-\u001f\u007f]/.test(id))
            && new Set(value).size === value.length
            : range ? Number.isInteger(value) && value >= range[0] && value <= range[1]
            : values ? values.indexOf(value) >= 0
            : key === "headerImage"
                ? typeof value === "string" && value.length <= 4096 && (value === "" || value[0] === "/")
                : typeof value === "boolean"
        if (!good) { valid(false, "launcher." + key, null); effective.launcher[key] = launcherDefaults[key] }
    }
    // Always leave a way to identify applications.
    if (!effective.launcher.showIcons && !effective.launcher.showLabels) {
        valid(false, "launcher.showLabels", null); effective.launcher.showLabels = true
    }
    const clipboardDefaults = defaults().clipboard
    for (const key of Object.keys(clipboardDefaults)) {
        const value = effective.clipboard[key]
        if (key === "historyLimit" ? !Number.isInteger(value) || value < 10 || value > 200
                : typeof value !== "boolean") {
            valid(false, "clipboard." + key, null)
            effective.clipboard[key] = clipboardDefaults[key]
        }
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
        valid(false, "icons.pack", ""); effective.icons.pack = "magi-default"
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

    if (effective.media.preferredPlayer !== null
            && (typeof effective.media.preferredPlayer !== "string" || effective.media.preferredPlayer.length > 256)) {
        valid(false, "media.preferredPlayer", null); effective.media.preferredPlayer = null
    }
    if (["collapse", "minimal"].indexOf(effective.media.emptyState) < 0) {
        valid(false, "media.emptyState", "collapse"); effective.media.emptyState = "collapse"
    }
    for (const [key, maximum] of [["horizontalInset", 64], ["edgeOffset", 32]]) {
        if (!Number.isInteger(effective.bar[key]) || effective.bar[key] < 0 || effective.bar[key] > maximum) {
            valid(false, "bar." + key, 0); effective.bar[key] = 0
        }
    }
    if (!["top", "bottom"].includes(effective.bar.position)) {
        valid(false, "bar.position", "top"); effective.bar.position = "top"
    }
    if (typeof effective.bar.externalDisplays !== "boolean") {
        valid(false, "bar.externalDisplays", false); effective.bar.externalDisplays = false
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
    // Compatibility input is read once. The v18 document has one structural authority.
    if (input.schemaVersion < 18 && input.controlCentre && !input.controlCentre.layout) {
        const legacy = input.controlCentre.sections || {}
        const names = {controls:"quickControls", actions:"actions", profile:"profile", sliders:"sliders", media:"media"}
        cc.layout = defaults().controlCentre.layout.filter(id => legacy[names[id]] !== false && !(id === "media" && input.media && input.media.enabled === false))
    }
    const sectionIds = ["profile", "controls", "sliders", "actions", "media"]
    if (!Array.isArray(cc.layout) || cc.layout.some(id => !sectionIds.includes(id)) || new Set(cc.layout).size !== cc.layout.length) {
        errors.push("controlCentre.layout: invalid or duplicate section")
        cc.layout = defaults().controlCentre.layout
    }
    delete cc.sections
    delete effective.media.enabled
    if (!Number.isInteger(cc.columns) || cc.columns < 1 || cc.columns > 16) {
        valid(false, "controlCentre.columns", 4); cc.columns = 4
    }
    if (!Number.isInteger(cc.actionColumns) || cc.actionColumns < 1 || cc.actionColumns > 16) {
        valid(false, "controlCentre.actionColumns", 6); cc.actionColumns = 6
    }
    const catalogue = controlDefinitions()
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
            const supported = catalogue.filter(d => d.presentations.indexOf(presentation) >= 0).map(d => d.id)
            if (supported.indexOf(entry.module) < 0) { warnings.push("Unavailable CC module: " + entry.module); return false }
            if ((group === "controls" || (group === "actions" && entry.accent !== undefined && entry.accent !== null)) && controlAccentRoles.indexOf(entry.accent) < 0) {
                errors.push("controlCentre.controls." + entry.key + ".accent: invalid value")
                entry.accent = controlAccentDefaults[entry.module] || "lavender"
            }
            return true
        })
    }
    return {future: false, document: document, effective: effective, errors: errors, warnings: warnings}
}
