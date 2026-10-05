// Pure model functions: no window, singleton, clipboard or Settings dependencies.
function normalize(value) {
    return String(value || "").normalize("NFKD").replace(/[\u0300-\u036f]/g, "")
        .toLowerCase().replace(/[-_:&]+/g, " ").replace(/\s+/g, " ").trim()
}
function prepare(document) {
    if (!document || !document.unicodeVersion || !Array.isArray(document.entries) || !document.entries.length)
        throw new Error("Invalid emoji dataset")
    const seen = new Set(), sequences = new Set()
    return document.entries.map((entry, order) => {
        if (!entry.id || !entry.emoji || !entry.name || !entry.group || !entry.subgroup || seen.has(entry.id)
                || sequences.has(entry.emoji)
                || !/^[0-9A-F]+(?:-[0-9A-F]+)*$/.test(entry.id)
                || String.fromCodePoint(...entry.id.split("-").map(p => parseInt(p, 16))) !== entry.emoji)
            throw new Error("Invalid or duplicate emoji entry")
        seen.add(entry.id); sequences.add(entry.emoji)
        return Object.assign({}, entry, {order: order, nameText: normalize(entry.name),
            metadataText: normalize(entry.group + " " + entry.subgroup)})
    })
}
function categories(entries) { return Array.from(new Set(entries.map(e => e.group))) }
function fieldScore(field, token) {
    if (field === token) return 100
    if (field.indexOf(token) === 0) return 80
    const at = field.indexOf(token)
    return at < 0 ? 0 : field[at - 1] === " " ? 65 : 45
}
function rank(entries, query, category, recents) {
    const normalized = normalize(query), tokens = normalized.split(" ").filter(Boolean)
    if (!tokens.length) {
        if (category === "Recently Used") {
            const byId = new Map(entries.map(e => [e.id, e]))
            return (recents || []).map(id => byId.get(id)).filter(Boolean)
        }
        return entries.filter(e => !category || category === "All" || e.group === category)
    }
    // Search deliberately spans every category. Unicode order breaks score ties.
    return entries.map(entry => {
        let score = entry.nameText === normalized ? 1000 : 0
        for (const token of tokens) {
            const match = Math.max(fieldScore(entry.nameText, token), fieldScore(entry.metadataText, token) * 0.25,
                entry.emoji === token ? 100 : 0)
            if (!match) return {entry:entry, score:-1}
            score += match
        }
        return {entry:entry, score:score}
    }).filter(row => row.score >= 0).sort((a,b) => b.score - a.score || a.entry.order - b.entry.order).map(row => row.entry)
}
function sequenceAt(results, index) {
    return Number.isInteger(index) && index >= 0 && index < results.length ? results[index].emoji : ""
}
function promote(recents, id, limit) { return [id].concat(recents.filter(value => value !== id)).slice(0, limit) }
