# MAGI

## Phase 12D — Control Centre visual editor (accepted and complete)

Control Centre has a first-class visual editor with ordered structural composition,
Primary/Secondary presentation assignment, inert production presenters and contextual
family/individual inspectors. Schema 18 migrates the previous visibility flags without
changing the initial appearance. The Phase12C drag board now accepts generic geometry
adapters; Bar regression remains covered. The implementation is integrated, schema 18 is saved, and native functionality and
the fitted left-preview/right-inspector layout are operator-accepted. Regression
and migration checks pass; Phase 12E remains separate.
[Architecture, migration, tests and review gallery](docs/design/phase12d-control-centre-visual-editor.md).

## Phase 12C — Bar visual builder (accepted and complete)

Bar has a first-class navigation entry and Layout / Colours & Look / Behaviour
modes sharing an inert production-presenter canvas. Family geometry and background
are shared; Wi-Fi/Bluetooth accents are individual. Schema 17 preserves prior
appearance. Native editor and production Bar review are operator-accepted; schema 17 is saved.
Phase 12D is accepted; the Phase 12C architecture and Bar editor remain intact.
[Ownership audit, implementation, tests and previews](docs/design/phase12c-bar-visual-builder.md).


## Phase 12B — theme library (natively accepted)

Eight canonical semantic palettes add Rosé Pine, Moon and Dawn, Nord and Tokyo
Night, Storm, Moon and Day (eight total; no invented Nord variants). Schema remains
16; existing selections and role names are preserved. Native review passed; Catppuccin Mocha was restored.
[Design, mappings, tests and gallery](docs/design/phase12b-theme-library.md).

## Phase 12A — visual configurator (accepted and complete)

Settings has larger navigation icons, independent Hub selection/toggle colours,
and Profile Header / Controls / Media Player groups around a safe live Control
Centre preview. Production presenters and section layout are reused; drag handles
reorder within each type through the existing auto-save contract. Schema 16
preserves the old Hub selected colour on migration. Native review and integration passed; local Settings migrated to schema 16
without unrelated value changes. [Architecture, tests, offline previews and review limits](docs/design/phase12a-control-centre-configurator.md).
Phase 12B and 12C are natively accepted; Phase 12D and deferred hardware acceptance remain separate.


## Phase 11A — fingerprint groundwork (accepted and complete)

Native test-only fingerprint state/packet/lifecycle models and synthetic enrollment
Settings previews are implemented. Production remains password-only, schema 15;
QML gains presentation text only. Direct fprintd broker selected for future
integration alongside the independent PAM password worker. Enrollment audit is
unknown due to denied D-Bus access; existing enrollment is protected. Some IPC
regressions are environment-blocked and reproduce on the accepted baseline; this
limitation is accepted for non-authoritative Phase 11A. The operator accepted
Security Settings and offline lock presentation; Phase 11B remains deferred.
[Design, evidence, previews, limitations and Phase 11B ledger](docs/design/phase11a-fingerprint-groundwork.md).


## Phase 10C.2A — accepted non-authoritative display framework

Displays adds a preview-only layout editor, versioned profiles, a read-only Hyprmon
importer, a non-executing Hyprland planner and file-backed synthetic transactions
with an independent timeout watchdog. Main Settings remains schema15. Hyprmon
remains production authority; no live monitor apply or startup migration exists.
See [audit, architecture, previews and deferred physical ledger](docs/design/phase10c2-display-manager.md).


## Phase 10C.1 — accepted and complete (2026-10-22)

Power & Idle is integrated with schema 15 and saved 300/600/0 policy. The
managed user service owns Hypridle and reads generated runtime configuration
outside Git. Default Apply, timed lock, DPMS wake, inhibitor refusal/recovery,
invalid ordering, manual lock and real suspend/resume passed the live gates.
First-character resume input and temporary suspend-listener activation passed. The original
canonical config is an emergency fallback only. The exact startup command passed an idempotent active-service check; a true
fresh login remains untested. The operator accepted finalization; protected local state is excluded.
See [ownership, acceptance evidence, rollback and remaining limits](docs/design/phase10c1-power-idle.md).
No MAGI Lock/PAM redesign, Hyprmon replacement or Phase 10C.2 work.

MAGI is a first-party Quickshell desktop shell layer for Hyprland, developed for
this repository's Arch Linux setup. It combines the status bar, system controls
and everyday desktop utilities with shared themes, icons and Settings.

Phase 10A Settings, Hub and icon architecture refinement is accepted; see the
[final contract and validation](docs/design/phase10a.md). Phase 10B adds optional
external bars, Top/Bottom placement, inset/offset and originating-output surfaces;
[implementation, execution-boundary exception and review checkpoint](docs/design/phase10b-bar-multimonitor.md).
Phase 10C.2 remains deferred.
The Phase 2E visual and behavioural overhaul is natively accepted. MAGI remains a
personal shell, not a packaged desktop distribution. The validated baseline is
Quickshell 0.3.1 and Hyprland 0.56.2. Phase 10B physical checks passed on
eDP-1 at scale 2 and HDMI-A-1 at scale 1.5; Phase 10B is accepted and complete.

## The shell

- **Bar and Control Centre:** workspaces, time/date and status indicators; configurable
  tiles, sliders, actions, columns and ordering. Wi-Fi and Bluetooth have related
  detail surfaces, backed by the existing system services.
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
the time/date family. Control Centre, Wi-Fi, Bluetooth and Calendar retain transient
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
| Super+S | Hub → Settings |

Super+S opens/selects the existing Settings instance. Apps search accepts typing,
arrows and Enter; right-click hides an app, and Settings → Launcher restores it.
Emoji copies the selected sequence for normal pasting. There are no Rofi or MFTrunk
fallback bindings.

## Appearance and Settings

Appearance groups **Theme, Surfaces, Bar, Control Centre and Hub** without duplicating
pages. Operator controls include semantic palette roles and roundness, expanded/card
borders, navigation accent, Pill/Filled/Minimal switches, Hub placement, Bar arrangement,
Control Centre composition and icon/tile styling. Profile and Media have independent
text sizes/weights, artwork sizing/roundness and border-width controls.

Settings can pin the **real production Control Centre** while navigating pages and
adjusting values live. Profile, Calendar, Notifications, Clipboard, Launcher, Emoji,
Wallpaper retain their own settings. Theme and Icon Pack share Appearance → Theme;
Status icon size belongs to Bar. Schema 13 retires individual icon overrides and adds
semantic media-progress/Hub-toggle roles;
local `settings.json`, backups and managed assets should be backed up separately.

### Profile and weather

Profile supports an exact configured display name, time-of-day greeting, independent
line typography and an optional third line. Compact greetings read `Afternoon, jkebwdn`;
Friendly preserves `Good Afternoon jkebwdn`.

Weather is **opt-in**, using an explicitly saved location in Settings → Profile.
MAGI's first-party service uses Open-Meteo, supports Metric/Imperial, caches recent
successful information and reports unavailable states honestly. It does not use
silent IP or system geolocation.

### Theme Orchestrator

MAGI is the canonical semantic palette source. Application themes can opt in to
follow it: Hyprland, Ghostty, GTK/Thunar, Zen Browser, Yazi/yatline, Neovim, Starship,
Fastfetch through terminal ANSI, and btop. Generated output lives separately from
human/Stow-owned dotfiles, with reviewed integration hooks and ownership safeguards.

Zen's CSS integration is generated; its workspace-native base colour still needs
manual selection. Qt, hyprtoolkit and Hyprlock integration remain deferred.
Wallpaper-derived palettes are not implemented.

## Design and architecture

Each enabled bar reserves **48 + edgeOffset logical px**, with a 48px strip. Floating utilities add no reservation.
Compact Bar objects expand into related surfaces using shared status-surface ownership;
Hub retains its own utility host. Semantic palettes, roundness, motion and shared artwork
masking provide consistent presentation without hard-coded per-theme styling.

First-party services own Notifications, Clipboard, Apps and other utility state.
System integrations continue to use NetworkManager, BlueZ, PipeWire and MPRIS rather
than replacing those backends. See [architecture](docs/architecture.md) and the
[accepted Phase 2E checkpoint](docs/design/runtime-phase2e-finalization.md).

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
- Hyprpaper for wallpapers, with Hypridle, Hyprlock and hyprpolkitagent handling their
  existing session roles. T15g startup also uses Hyprmon.

Review machine-specific monitor, startup and keybind configuration before deployment.
Hyprland starts `quickshell -c magi` at login. In an existing session, check for another
MAGI instance or competing notification daemon before starting it manually. Restore
operator-local idle/lock configuration separately. See the [Linux guide](../README.md).

## Documentation and future work

- [Documentation index](docs/README.md) — current architecture and accepted checkpoints.
- [Architecture](docs/architecture.md) and [decisions](docs/decisions.md).
- [Theme Orchestrator](docs/design/theme-orchestrator.md) and [Clipboard privacy](docs/design/clipboard-manager.md).
- [Tests](tests/) and [research](docs/research/README.md) — focused validation and dated evidence.

Future work includes stabilisation/daily use, Fraud O.G Linux icons, a MAGI lock screen
and greeter/login, Theme Orchestrator v2 with wallpaper intelligence and scheduling,
Calendar providers, and broader multi-monitor/automation support. These are not current
features; Hyprlock remains the lock screen today.

No representative tracked screenshots are available yet. A future documentation capture
pass will refresh visuals; runtime screenshots are not bundled with this milestone.
