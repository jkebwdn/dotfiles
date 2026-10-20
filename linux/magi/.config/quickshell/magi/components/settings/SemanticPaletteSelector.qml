import QtQuick
import "../../theme" as Theme
SettingsSelector {
    id: root
    property string role: "accent"
    signal roleSelected(string value)
    model: ["accent"].concat(Theme.ThemeRegistry.accentRoles)
    currentIndex: Math.max(0, model.indexOf(root.role))
    onActivated: index => root.roleSelected(model[index])
}
