import QtQuick
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/settings/SettingsSchema.js" as Schema
ShellRoot {
    Services.NotificationModel { id: model; preferences: Schema.defaults().notifications }
    Services.NotificationBackend { owner: model }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({history:model.history.map(r=>({id:r.notificationId, data:r.data,
                read:r.read, live:r.notification !== null, restored:!!r.notification?.lastGeneration,
                reason:r.closeReason, remaining:r.remaining})),
                toasts:Array.from({length:model.toasts.count},(_,i)=>model.toasts.get(i).notificationId)})
        }
        function config(key: string, value: string): void {
            model.preferences = Object.assign({}, model.preferences, {[key]:JSON.parse(value)})
        }
        function fullscreen(value: bool): void { model.fullscreen = value }
        function centre(value: bool): void { model.centreOpen = value }
        function hover(id: int, value: bool): void { model.find(id).hovered = value }
        function dismiss(id: int): void { model.dismiss(id) }
        function clear(): void { model.clear() }
        function settingsReady(): bool { return Services.Settings.ready }
        function invoke(id: int, action: string): bool { return model.invoke(id, action) }
        function dndIntegration(value: bool): bool {
            // Exercise the real existing action against the isolated SettingsStore.
            Services.Notifications.serverActivated = true
            const accepted = Services.QuickActions.setDnd(value)
            return accepted && Services.QuickActions.dndActive === value
                && Services.Notifications.preferences.dnd === value
        }
    }
}
