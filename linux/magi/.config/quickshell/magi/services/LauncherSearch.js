// Pure ranking shared by both presentations. No executable/query interpretation.
function normalize(value) {
    return String(value || "").normalize("NFKD").replace(/[\u0300-\u036f]/g, "").toLowerCase().trim()
}
function fieldScore(field, token) {
    if (field === token) return 100
    if (field.indexOf(token) === 0) return 80
    const at = field.indexOf(token)
    if (at >= 0) return /[\s._-]/.test(field[at - 1]) ? 65 : 45
    return 0
}
function rank(apps, query, history, hiddenIds) {
    const tokens = normalize(query).split(/\s+/).filter(Boolean)
    const hidden = new Set(hiddenIds || [])
    const seen = new Set()
    return apps.filter(app => {
        if (!app.id || !app.name || hidden.has(app.id) || seen.has(app.id)) return false
        seen.add(app.id); return true
    }).map(app => {
        const name = normalize(app.name), generic = normalize(app.genericName)
        const keywords = normalize((app.keywords || []).join(" "))
        let score = 0
        for (const token of tokens) {
            const match = Math.max(fieldScore(name, token), fieldScore(generic, token) * 0.7,
                fieldScore(keywords, token) * 0.6)
            if (!match) return {app: app, score: -1}
            score += match
        }
        // Small session-only frequency bonus cannot outrank a better match tier.
        score += Math.min(9, (history[app.id] || 0) * 2)
        return {app: app, score: score}
    }).filter(row => row.score >= 0).sort((a, b) => b.score - a.score
        || a.app.name.localeCompare(b.app.name) || a.app.id.localeCompare(b.app.id))
        .map(row => row.app)
}
