function identifier(player) {
    return String(player && (player.dbusName || player.desktopEntry || player.identity) || "")
}
function suitable(player) {
    return !!player && (!!player.canControl || !!player.identity || !!player.trackTitle || !!player.trackArtist)
}
function choose(players, preferred, current) {
    const candidates = (players || []).filter(suitable).slice().sort((a, b) => identifier(a).localeCompare(identifier(b)))
    if (preferred) {
        const explicit = candidates.find(player => [player.dbusName, player.desktopEntry, player.identity].indexOf(preferred) >= 0)
        if (explicit) return explicit
    }
    const playing = candidates.filter(player => !!player.isPlaying)
    if (current && playing.indexOf(current) >= 0) return current
    if (playing.length) return playing[0]
    if (current && candidates.indexOf(current) >= 0) return current
    return candidates.length ? candidates[0] : null
}
