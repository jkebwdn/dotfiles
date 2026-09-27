pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    readonly property var registry: readRegistry(source.text())
    readonly property var themes: registry.themes
    readonly property var ids: themes.map(theme => theme.id)
    function readRegistry(text) {
        const document = JSON.parse(text)
        if (document.formatVersion !== 1) throw new Error("Unsupported palette registry")
        const required = ["background", "surface", "elevated", "overlay", "text", "subtext",
            "muted", "inactive", "border", "rim", "accent", "blue", "lavender", "green",
            "yellow", "peach", "red", "teal", "success", "warning", "danger", "focus",
            "sliderFill", "sliderTrack", "sliderRim", "onAccent", "onBlue", "onLavender",
            "onGreen", "onYellow", "onPeach", "onRed", "onTeal"]
        const seen = []
        document.themes = document.themes.filter(theme => {
            const valid = typeof theme.id === "string" && seen.indexOf(theme.id) < 0
                && typeof theme.dark === "boolean" && theme.roles
                && required.every(role => /^#[0-9a-fA-F]{6}$/.test(theme.roles[role]))
            if (!valid) console.warn("Ignoring invalid palette definition: " + theme.id)
            else seen.push(theme.id)
            return valid
        })
        if (!document.themes.some(theme => theme.id === "catppuccin-mocha"))
            throw new Error("Bundled Mocha palette is missing or invalid")
        return document
    }
    function resolve(id) {
        return themes.find(theme => theme.id === id)
            || themes.find(theme => theme.id === "catppuccin-mocha")
    }
    FileView {
        id: source
        path: Qt.resolvedUrl("palettes/registry.json")
        blockLoading: true
    }
}
