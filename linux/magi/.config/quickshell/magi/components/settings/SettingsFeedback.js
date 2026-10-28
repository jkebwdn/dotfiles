.pragma library
// Presentation only. Persistence and activation remain independent authorities.
function save(state) {
    return ({saved:"All changes saved", pending:"Saving…", conflict:"Settings changed elsewhere. Reload to continue.",
        error:"Could not save changes. Reload to recover.", invalid:"Some settings need attention. Review details.",
        readOnly:"Settings are from a newer version. Changes cannot be saved.", loading:"Loading settings…"})[state] || "Settings not ready"
}
function savedContext(state) { return state === "saved" ? "Your choice is saved. " : "" }
function activation(target) {
    if (!target.enabled) return ""
    if (target.error) return target.label + " could not update. Open application themes and retry."
    if (target.statusLabel === "Restart required") return "Restart " + target.label + " to apply."
    if (target.statusLabel === "Reload required") return "Reload " + target.label + " configuration to apply."
    if (/manual/i.test(target.result || "")) return target.label + " needs a manual step. Open application themes for details."
    return ""
}
function attention(targets, error, busy, state) {
    if (error) return savedContext(state) + "Application themes could not update. Open details to review and retry."
    const messages = targets.map(activation).filter(text => text.length > 0)
    if (messages.length) return savedContext(state) + messages.join(" ")
    return busy ? "Updating application themes…" : ""
}
function appearance(status, active, state) {
    if (!active) return "Application appearance is not active in this session."
    if (status === "error") return savedContext(state) + "Could not apply appearance. See Details below."
    if (["reload-required", "reload_required"].includes(status)) return "Reload Ghostty configuration to finish applying appearance."
    if (status === "reload_requested") return "Ghostty reload requested."
    if (status === "next_launch") return "Applies when Ghostty next launches."
    return ""
}
