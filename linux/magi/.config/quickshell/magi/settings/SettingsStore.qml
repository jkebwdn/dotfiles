import QtQuick
import Quickshell
import Quickshell.Io
import "SettingsSchema.js" as Schema
import "SettingsMigrations.js" as Migrations

// Reusable only for isolated tests; production owns exactly one via Settings.qml.
Scope {
    id: root
    required property string path
    readonly property var data: state.effective
    readonly property int revision: state.revision
    readonly property bool ready: state.ready
    readonly property string saveState: state.status
    readonly property string error: state.error
    readonly property var diagnostics: state.errors.concat(state.warnings)
    readonly property bool dirty: state.dirty

    QtObject {
        id: state
        property var document: Schema.defaults()
        property var effective: Schema.defaults()
        property var baseline: null
        property var errors: []
        property var warnings: []
        property bool ready: false
        property bool dirty: false
        property bool future: false
        property bool parseInvalid: false
        property int revision: 0
        property string status: "loading"
        property string error: ""
        property var request: null
        property string response: ""
        property bool readPending: false
    }

    function publish(result) {
        state.document = result.document
        state.effective = result.effective
        state.errors = result.errors
        state.warnings = result.warnings
        state.future = result.future
        state.revision++
    }
    function acceptText(text) {
        if (state.dirty && text !== state.baseline) {
            state.status = "conflict"
            state.error = "External settings changed while edits were pending"
            return
        }
        if (state.ready && text === state.baseline) return
        try {
            const raw = text === null ? Schema.defaults() : Migrations.migrate(JSON.parse(text))
            publish(Schema.analyze(raw))
            state.parseInvalid = false
            state.baseline = text
            state.status = state.future ? "readOnly" : state.errors.length ? "invalid" : "saved"
            state.error = state.future ? "Settings schema is newer than this MAGI version" : ""
        } catch (exception) {
            state.baseline = text
            state.parseInvalid = true
            state.errors = [String(exception)]
            state.status = "invalid"
            state.error = String(exception)
        }
    }
    function reload() {
        if (worker.running || state.request) { state.readPending = true; return }
        start({op: "read", path: path})
    }
    function discardAndReload() {
        if (state.request || worker.running) return false
        state.dirty = false
        state.ready = false
        reload()
        return true
    }
    function start(request) {
        state.request = request
        state.response = ""
        worker.exec(["python3", Qt.resolvedUrl("persist.py").toString().replace(/^file:\/\//, "")])
    }
    function save() {
        if (!state.ready || state.future || state.errors.length || !state.dirty
                || state.status === "conflict") return false
        if (worker.running || state.request) { saveTimer.restart(); return false }
        state.status = "pending"
        start({op: "write", path: path, expected: state.baseline,
            text: JSON.stringify(state.document, null, 2) + "\n", revision: state.revision})
        return true
    }
    function commit(document, repairMalformed) {
        if (!ready || state.future || state.status === "conflict"
                || (state.parseInvalid && !repairMalformed)) return false
        try {
            const result = Schema.analyze(document)
            if (result.errors.length || result.future) { state.error = result.errors.join("; "); return false }
            publish(result)
            state.parseInvalid = false
            state.dirty = true
            state.status = "pending"
            state.error = ""
            saveTimer.restart()
            return true
        } catch (exception) { state.error = String(exception); return false }
    }
    function setValue(section, key, value) {
        if (["appearance", "icons", "bar", "controlCentre", "profile", "media"].indexOf(section) < 0) return false
        const next = Schema.clone(state.document)
        // Fill missing defaults, but retain unknown fields and diagnosed raw values.
        if (next[section] === undefined) next[section] = Schema.defaults()[section]
        if (!Schema.object(next[section]) || ["__proto__", "constructor", "prototype"].indexOf(key) >= 0) return false
        next[section][key] = value
        return commit(next)
    }
    function setVisual(key, value) {
        if (!Object.prototype.hasOwnProperty.call(Schema.defaults().appearance.visual, key)) return false
        const visual = Schema.clone(data.appearance.visual)
        visual[key] = value
        return setValue("appearance", "visual", visual)
    }
    function setTheme(id) { return setValue("appearance", "theme", id) }
    function setIconPack(id) { return setValue("icons", "pack", id) }
    function setIconOverride(role, assetId, moduleId, colorMode) {
        const icons = Schema.clone(data.icons)
        const target = moduleId ? (icons.overrides.modules[moduleId] || {}) : icons.overrides.global
        if (assetId === null) delete target[role]
        else target[role] = {source: "user", assetId: assetId,
            colorMode: colorMode === "fixed" ? "fixed" : "semantic"}
        if (moduleId) icons.overrides.modules[moduleId] = target
        return setValue("icons", "overrides", icons.overrides)
    }
    function setRoundness(role, value) {
        const roundness = Schema.clone(data.appearance.roundness)
        if (role === "master") roundness.master = value
        else if (Schema.radiusRoles.indexOf(role) >= 0) roundness.roles[role] = value
        else return false
        return setValue("appearance", "roundness", roundness)
    }
    // Structural edits are atomic snapshots; presentation owners choose safe timing.
    function placeBar(id, section) {
        const next = Schema.clone(state.document)
        next.bar = Schema.clone(data.bar)
        for (const key of ["left", "center", "right"]) next.bar[key] = next.bar[key].filter(value => value !== id)
        if (section !== "hidden") {
            if (["left", "center", "right"].indexOf(section) < 0) return false
            next.bar[section].push(id)
        }
        return commit(next)
    }
    function moveBar(section, index, delta) {
        const values = Schema.clone(data.bar[section])
        const to = index + delta
        if (to < 0 || to >= values.length) return false
        const value = values.splice(index, 1)[0]; values.splice(to, 0, value)
        return setValue("bar", section, values)
    }
    function setControlEntries(entries) { return setEntries("controls", entries) }
    function setEntries(group, entries) {
        if (["controls", "sliders", "actions"].indexOf(group) < 0) return false
        return setValue("controlCentre", group, entries)
    }
    function setControlSection(section, enabled) {
        if (["profile", "quickControls", "sliders", "media", "actions"].indexOf(section) < 0) return false
        const sections = Schema.clone(data.controlCentre.sections)
        sections[section] = enabled
        return setValue("controlCentre", "sections", sections)
    }
    function editEntry(group, key, field, value) {
        if (["controls", "sliders", "actions"].indexOf(group) < 0) return false
        const entries = Schema.clone(data.controlCentre[group])
        const entry = entries.find(e => e.key === key)
        if (!entry || ["module", "enabled", "accent"].indexOf(field) < 0) return false
        entry[field] = value
        return setEntries(group, entries)
    }
    function moveEntry(group, key, delta) {
        if (["controls", "sliders", "actions"].indexOf(group) < 0) return false
        const entries = Schema.clone(data.controlCentre[group])
        const index = entries.findIndex(e => e.key === key), to = index + delta
        if (index < 0 || to < 0 || to >= entries.length) return false
        const entry = entries.splice(index, 1)[0]; entries.splice(to, 0, entry)
        return setEntries(group, entries)
    }
    function addEntry(group, module) {
        if (["controls", "sliders", "actions"].indexOf(group) < 0) return false
        const entries = Schema.clone(data.controlCentre[group])
        if (entries.some(e => e.module === module)) return false
        const presentation = group === "controls" ? "tile" : group === "sliders" ? "slider" : "action"
        const entry = {key: module + "-" + Date.now(), module: module, enabled: true,
            presentation: presentation}
        if (group === "controls") entry.accent = Schema.controlAccentDefaults[module] || "lavender"
        entries.push(entry)
        return setEntries(group, entries)
    }
    function removeEntry(group, key) {
        if (["controls", "sliders", "actions"].indexOf(group) < 0) return false
        return setEntries(group, data.controlCentre[group].filter(e => e.key !== key))
    }
    function editControl(key, field, value) { return editEntry("controls", key, field, value) }
    function setControlModule(key, module) {
        const entries = Schema.clone(data.controlCentre.controls)
        const entry = entries.find(e => e.key === key)
        if (!entry) return false
        entry.module = module
        entry.accent = Schema.controlAccentDefaults[module] || "lavender"
        return setControlEntries(entries)
    }
    function moveControl(key, delta) { return moveEntry("controls", key, delta) }
    function addControl(module) { return addEntry("controls", module) }
    function removeControl(key) { return removeEntry("controls", key) }
    function resetSection(section) {
        if (["appearance", "icons", "bar", "controlCentre", "profile", "media"].indexOf(section) < 0) return false
        const next = Schema.clone(state.document)
        next[section] = Schema.defaults()[section]
        return commit(next)
    }
    function resetAll() {
        const next = Schema.clone(state.document)
        Object.assign(next, Schema.defaults())
        return commit(next, true)
    }
    // Explicit migration/save, not an automatic startup rewrite.
    function persistCurrent() { return commit(Schema.clone(state.document)) }

    Component.onCompleted: reload()
    Timer { id: saveTimer; interval: 250; onTriggered: root.save() }
    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: root.reload()
    }
    Process {
        id: worker
        stdinEnabled: true
        onStarted: write(JSON.stringify(state.request) + "\n")
        stdout: StdioCollector { onStreamFinished: state.response = text }
        onExited: {
            const request = state.request
            state.request = null
            try {
                const result = JSON.parse(state.response)
                if (!result.ok) {
                    state.status = result.conflict ? "conflict" : "error"
                    state.error = result.error
                } else if (request.op === "read") {
                    root.acceptText(result.text)
                } else {
                    state.baseline = result.text
                    state.dirty = state.revision !== request.revision
                    state.status = state.dirty ? "pending" : "saved"
                    state.error = ""
                    if (state.dirty) saveTimer.restart()
                }
            } catch (exception) {
                state.status = "error"
                state.error = "Settings I/O failed: " + String(exception)
            }
            state.ready = true
            if (state.readPending) {
                state.readPending = false
                Qt.callLater(root.reload)
            }
        }
    }
}
