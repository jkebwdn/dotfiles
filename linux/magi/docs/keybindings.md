# MAGI keybindings and IPC

> Current source inventory. Phase15 changes no keybindings.

Canonical source: `linux/t15g/hypr/.config/hypr/hyprland.lua`.
Reviewed 2026-10-27; source bindings below have distinct key combinations.
Hyprland Lua callbacks may appear as numeric `_lua` dispatch IDs in `hyprctl binds`;
a numeric callback is not proof of a conflicting command. Live confirmation is
separate from source inspection.

| Shortcut | IPC after `quickshell ipc -c magi call` | Result |
| --- | --- | --- |
| Super+Space | `hub toggle apps` | Application Hub |
| Super+N | `hub toggle notifications` | Notification Hub |
| Super+C | `hub toggle clipboard` | Clipboard Hub |
| Super+E | `hub toggle emoji` | Emoji Hub |
| Super+M | `magi toggle controlcentre` | Control Centre |
| Super+W | `magi toggle wifi` | Wi-Fi |
| Super+B | `magi toggle bluetooth` | Bluetooth |
| Super+A | `magi toggle audio` | Audio |
| Super+T | `magi toggle tray` | Temporary inline Bar tray toggle, no popup/save |
| Super+S | `hub open settings` | Settings (open, not toggle) |

Super+Q closes the active application through Hyprland; Super+V remains its floating
window toggle. Neither should be reassigned to a MAGI utility.

## IPC ownership

| Target | Actions / caller | Routing |
| --- | --- | --- |
| `magi` | open, toggle, close, status; Bar/shortcuts | Focused enabled output then main; Tray main-only |
| `hub` | open(mode), toggle(mode), close, status | Focused enabled output for shortcuts; originating output for UI |
| `settingsWindow` | Settings host compatibility and preview route | Hub Settings owner |
| `settings` | status, theme, roundness, iconPack, controlAccent, placement, reset, persist, reload | Preference commands; no output owner |
| `launcher`, `emoji`, `clipboard`, `notifications` | Feature open/toggle/close/status wrappers; notification activation | Delegate to current Hub/service owners |
| `hubWindow` | Host diagnostics / test inspection | Current Hub output |
| `wallpaper` | open/close/toggle/refresh/restore/status | Wallpaper workflow / topology service |
| `systemTheme` | Theme orchestration commands/status | Global publication owner |

The feature wrappers remain used by existing tests/integrations. No route is removed
merely because the main shortcuts now use `hub` or `magi`. Runtime status can contain
user data; do not publish raw status snapshots in documentation.
