# MAGI

MAGI is a first-party Quickshell desktop shell layer for Hyprland, developed for
this repository's Arch Linux setup. It combines the status bar, system controls
and everyday desktop utilities with shared themes, icons and Settings. It is a
personal shell, not a packaged desktop distribution. The current integration
targets Quickshell 0.3.2 and Hyprland 0.56.2; Settings schema is **22**.

## The shell

- **Bar and Control Centre:** workspaces, time/date and status indicators; configurable
  tiles, sliders, actions, columns and ordering. Wi-Fi and Bluetooth have related
  detail surfaces, backed by the existing system services.
- **Audio:** output/input dropdowns and one volume slider per application group,
  backed by PipeWire with WirePlumber routing authority. Left-click Volume opens
  Audio, right-click toggles mute, and the wheel adjusts output volume. Slider
  icons toggle mute; MPRIS playback controls remain separate.
- **Bluetooth:** discovery, pair → trust → connect, reconnect/disconnect and Agent1
  PIN/passkey/confirmation prompts. Authenticated hardware acceptance remains deferred.
- **System Tray:** shared application-owned icons and native menus, with bounded
  overflow. Super+T toggles icons inline in the main-output Bar without saving the
  layout; if unplaced, they temporarily appear on the right. There are no Tray
  visibility modes or shortcut popup.
- **Native secure lock:** the native owner and isolated PAM worker authorize unlock;
  QML supplies presentation only, with configurable layout and display-only modules.
- **MAGI Hub:** Apps, Clipboard, Notifications, Emoji and Settings in one retained host.
- **Apps:** first-party XDG application discovery, search, list/grid views, hidden-app
  management and Ghostty terminal launches. Optional header artwork has shared masking
  and border controls. MAGI Apps replaces the retired Rofi launcher/fallback.
- **Notifications:** first-party notification-daemon ownership, toasts, history, actions
  and DND. History retention offers 2h, 6h, 24h or Until cleared; the default is 6h.
  Critical notifications are exempt from age pruning, while history remains bounded.
- **Clipboard:** searchable text, image and file-URI history, restoration, pins and
  deletion. History is session-only by default; disk persistence is opt-in. Sensitive
  hints are respected, but unmarked secrets cannot reliably be detected.
- **Emoji:** Unicode search, categories, recents and exact multi-codepoint copying.
- **Calendar:** a local month grid with Today, keyboard navigation, week-start,
  week-number and adjacent-day preferences; no external event providers yet.
- **Wallpaper:** the actual manager lives in Settings → Wallpaper, with libraries,
  thumbnails, favourites, recents, Random and shared/per-monitor selection over hyprpaper.
- **Profile and media:** configurable greetings, optional third line, weather, MPRIS
  metadata, artwork progress and playback controls. The media card remains present
  when nothing is playing.

## Hub and surface ownership

The five Hub modes share one retained host and preserve their independent service/model
state. The physically separate selector can sit above or below the content, at a
configurable vertical anchor. Different modes grow away from that stable anchor.
Settings is a Hub mode, not a separate normal application window.

Normal desktop/application clicks **keep Hub open**. Escape closes it after child
popups, dialogs or drags have had first refusal. Direct mode routes open or switch
Hub; same-mode toggle commands can close it. F6 reaches the selector.

Control Centre remains a separate status-cluster surface family; Calendar belongs to
the time/date family. Control Centre, Wi-Fi, Bluetooth, Audio and Calendar retain transient
outside-click dismissal. Fullscreen suppression retains an open Hub session.

## Shortcuts

The [T15g Hyprland configuration](../t15g/hypr/.config/hypr/hyprland.lua) provides:

| Shortcut | Destination |
| --- | --- |
| Super+Space | Hub → Apps |
| Super+N | Hub → Notifications |
| Super+C | Hub → Clipboard |
| Super+E | Hub → Emoji |
| Super+M | Control Centre |
| Super+W | Wi-Fi |
| Super+B | Bluetooth |
| Super+A | Audio toggle |
| Super+T | Inline Bar Tray toggle (runtime only) |
| Super+S | Hub → Settings |

See the canonical [keybinding and IPC reference](docs/keybindings.md) for routing.
Super+S opens/selects the existing Settings instance. Apps search accepts typing,
arrows and Enter; right-click hides an app, and Settings → Launcher restores it.
Emoji copies the selected sequence for normal pasting. There are no Rofi or MFTrunk
fallback bindings.

## Appearance and Settings

Settings has first-class **Appearance, Bar, Control Centre and Hub** pages.
Appearance owns global tokens; feature pages own their specific borders and styling.
Operator controls include semantic palette roles and roundness, expanded/card
borders, Settings navigation accent, shared Pill/Filled/Minimal switches, Hub placement, Bar arrangement,
Control Centre composition and icon/tile styling. Profile and Media have independent
text sizes/weights, artwork sizing/roundness and border-width controls.

Settings can pin the **real production Control Centre** while navigating pages and
adjusting values live. Profile, Calendar, Notifications, Clipboard, Launcher, Emoji,
Wallpaper retain their own settings. Theme and Icon Pack share Appearance;
Status icon size belongs to Bar. Audio has the same border enable/colour/width
and shared surface-roundness controls as Wi-Fi/Bluetooth. Schema **22** defaults
are authoritative; live `settings.json` is operator-local, untracked and
exact-ignored. Back up local preferences, backups and managed assets separately.

### Profile and weather

Profile supports an exact configured display name, time-of-day greeting, independent
line typography and an optional third line. Compact greetings read `Afternoon, jkebwdn`;
Friendly preserves `Good Afternoon jkebwdn`.

Weather is **opt-in**, using an explicitly saved location in Settings → Profile.
MAGI's first-party service uses Open-Meteo, supports Metric/Imperial, caches recent
successful information and reports unavailable states honestly. It does not use
silent IP or system geolocation.

### Theme Orchestrator

The [theme library](docs/themes.md) includes Catppuccin, Everforest, Rosé Pine, Nord,
Tokyo Night, Gruvbox Dark/Light, Kanagawa Wave/Dragon, Dracula, One Dark/Light and
Ayu Mirage. MAGI is the canonical semantic palette source. Application themes can opt in to
follow it: Hyprland, Ghostty, GTK/Thunar, Zen Browser, Yazi/yatline, Neovim, Starship,
Fastfetch through terminal ANSI, and btop. Generated output lives separately from
human/Stow-owned dotfiles. Tracked static bootstrap hooks consume optional generated
payloads; normal enable/apply/switch/disable operations leave source bytes unchanged.
Generated generations, activation state and journals belong in XDG stores, not Git.
See [generated-state ownership](docs/generated-state.md). Application appearance
controls affect backgrounds, preserving text and icon opacity.

Zen's CSS integration is generated; its workspace-native base colour still needs
manual selection. Qt and hyprtoolkit application integration remain deferred.
Wallpaper-derived palettes are not implemented.

## Design and architecture

Each enabled bar reserves **48 + edgeOffset logical px**, with a 48px strip. Floating utilities add no reservation.
Compact Bar objects expand into related surfaces using shared status-surface ownership;
Hub retains its own utility host. Semantic palettes, roundness, motion and shared artwork
masking provide consistent presentation without hard-coded per-theme styling.

First-party services own Notifications, Clipboard, Apps and other utility state.
System integrations continue to use NetworkManager, BlueZ, PipeWire and MPRIS rather
than replacing those backends. Output-local Bars share service models; Bar clicks
open surfaces on their originating output, while shortcuts use the focused enabled
output then fall back to main. Tray is main-output-only. See the
[current architecture](docs/architecture/current-system.md).

## Installation and development

MAGI's deployable package is `.config/quickshell/magi/`, linked to
`~/.config/quickshell/magi/` with GNU Stow. From `~/dotfiles`:

```bash
cd ~/dotfiles/linux
stow --simulate --verbose --target="$HOME" magi
stow --target="$HOME" magi
```

Package-local ignore rules keep docs, tests, experiments and agent metadata out of
deployment. Install the applications separately; there is no one-command OS installer.
The current Arch setup uses:

- Hyprland, Quickshell and GNU Stow.
- NetworkManager, BlueZ, PipeWire/WirePlumber and UPower for system integrations.
- Python, python-gobject and gdk-pixbuf2 for helpers and image previews;
  wl-clipboard for restoration, brightnessctl for brightness, Ghostty for terminal apps.
- A C compiler (`base-devel`), Wayland and wayland-protocols for the clipboard capture
  helper's first-use build; the compositor must support ext-data-control.
- Hyprpaper for wallpapers, managed Hypridle for idle policy, native MAGI lock for
  locking, and hyprpolkitagent for authentication prompts. T15g also uses Hyprmon.
  Native lock needs its separate package/PAM deployment; see the
  [security and deployment boundaries](docs/security.md).

Review machine-specific monitor, startup and keybind configuration before deployment.
Hyprland starts `quickshell -c magi` at login. In an existing session, check for another
MAGI instance or competing notification daemon before starting it manually. Restore
operator-local state and provision native services separately. See the [Linux guide](../README.md).

## Documentation and development

`~/dotfiles` is the persistent source of truth. Use ephemeral worktrees when needed;
remove completed worktrees after merge/push and synchronization, once unique work
and protected state have been checked. Stage exact paths/hunks only—never
`git add .` or `git add -A`.

- [Documentation index](docs/README.md) — canonical guides and historical phase evidence.
- [Current architecture](docs/architecture/current-system.md) and [generated state](docs/generated-state.md).
- [Testing](docs/testing.md) — focused checks and `python3 linux/magi/tests/run-all.py`
  from the repository root.
- [Development closeout](docs/phase-closeout.md) and [contributor guidance](AGENTS.md).
- [Current roadmap](docs/current-roadmap.md) — reliability, hardware acceptance and
  evidenced daily-use polish. TTY login is accepted; Greeter is not active work.

Historical design/acceptance records remain in the documentation index. Displays
production completion, fingerprint, physical multi-monitor Tray acceptance and
optional Bluetooth audio auto-switch remain deferred; they are not implied by the
current shell capabilities.
