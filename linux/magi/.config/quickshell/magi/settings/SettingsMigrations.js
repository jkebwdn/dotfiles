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
    return doc
}
