// Pure presentation policy. Wire timeout is milliseconds in Quickshell 0.3.1.
function timeout(sender, urgency, fallback) {
    if (sender === 0 || urgency === 2 && sender < 0) return 0
    return sender > 0 ? sender : fallback
}
function canToast(settings, urgency, fullscreen, centreOpen) {
    return settings.enabled && settings.toastsEnabled && !fullscreen && !centreOpen
        && (!settings.dnd || urgency === 2 && settings.criticalBypassDnd)
}
function isFullscreen(client, monitor) {
    if (!client || !monitor || client.monitor !== monitor.id || client.fullscreen !== 2) return false
    const workspace = client.workspace ? client.workspace.id : 0
    return workspace !== 0 && (workspace === monitor.activeWorkspace?.id
        || workspace === monitor.specialWorkspace?.id)
}
function text(value, limit) { return typeof value === "string" ? value.slice(0, limit) : "" }
function snapshot(n) {
    return {id: n.id, appName: text(n.appName, 256), appIcon: text(n.appIcon, 2048),
        summary: text(n.summary, 1024), body: text(n.body, 8192),
        urgency: n.urgency, timeout: n.expireTimeout,
        desktopEntry: text(n.desktopEntry, 256), image: text(n.image, 2048),
        transient: n.transient, resident: n.resident,
        actions: Array.from(n.actions).slice(0, 16).map(a => ({identifier: a.identifier, text: text(a.text, 128)}))}
}
