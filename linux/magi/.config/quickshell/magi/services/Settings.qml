pragma Singleton
import QtQuick
import Quickshell.Io
import "../settings" as Configuration

Configuration.SettingsStore {
    id: root
    path: Qt.resolvedUrl("../settings.json").toString().replace(/^file:\/\//, "")
    readonly property string palette: data.appearance.theme === "everforest-dark-hard"
        ? "everforest" : "catppuccin"
    readonly property var barLeftPlugins: data.bar.left
    readonly property var barCenterPlugins: data.bar.center
    readonly property var barRightPlugins: data.bar.right
    IpcHandler {
        target: "settings"
        function status(): string {
            return JSON.stringify({data: root.data, revision: root.revision,
                state: root.saveState, error: root.error, diagnostics: root.diagnostics})
        }
        function theme(id: string): bool { return root.setTheme(id) }
        function roundness(role: string, value: string): bool {
            if (value === "default") return root.setRoundness(role, role === "master" ? 1 : null)
            return root.setRoundness(role, Number(value))
        }
        function iconPack(id: string): bool { return root.setIconPack(id) }
        function placement(section: string, ids: string): bool {
            if (["left", "center", "right"].indexOf(section) < 0) return false
            try { return root.setValue("bar", section, JSON.parse(ids)) }
            catch (error) { return false }
        }
        function reset(section: string): bool {
            return section === "all" ? root.resetAll() : root.resetSection(section)
        }
        function persist(): bool { return root.persistCurrent() }
        function reload(): bool { return root.discardAndReload() }
    }
}
