# MAGI

MAGI is a first-party Quickshell desktop shell for my Arch Linux + Hyprland setup.
It brings the bar, system controls, Settings, notifications and clipboard history
into one interface with shared themes and icons.

## Current status

MAGI is actively developed and tailored to the ThinkPad T15g configuration in
this dotfiles repository. It is a working personal shell, rather than a packaged
general-purpose desktop distribution.

The verified runtime is Quickshell 0.3.1 with Hyprland 0.56.2. Current runtime
validation covers the laptop's scale-2 display; multi-output and fractional-scale
behaviour still need broader testing. Hyprlock remains the current lock screen.

## Features

- A 48px bar/status surface with workspaces, time/date and system indicators.
- Shared status-surface architecture: status controls and their expanded views
  use one persistent surface, with animated expansion and detail navigation.
- Control Centre with configurable primary tiles, secondary actions, sliders,
  ordering and columns; available actions reflect the machine's backends.
- A separate Settings application for appearance, profile, bar, Control Centre,
  icons, notifications and clipboard preferences.
- Semantic themes/palettes, configurable visual roles and a custom icon system
  with bundled packs, overrides and fallback icons.
- First-party notification ownership, toasts, history, Notification Centre and DND.
- A first-party Clipboard Manager with text, image and file-URI support.
- MPRIS media information and playback controls, with optional profile/media regions.
- Wi-Fi scanning/connection/password entry, Bluetooth status/device controls,
  PipeWire volume, brightness and battery integration.
- Fullscreen-aware notification and Clipboard behaviour.

## Clipboard

Open Clipboard Manager with `SUPER+SHIFT+V`. It supports text, PNG/JPEG images and
file-URI lists, with search, restoration, pins, deletion and bounded history.
Supported HTML offers can be stored as plain text.

History is session-only by default, including pinned entries. Disk persistence
is an explicit Settings opt-in. Initial clipboard contents are skipped, and offers
marked sensitive are rejected before reading; unmarked sensitive content cannot
be reliably identified. Clipboard restoration requires `wl-copy` from wl-clipboard.
See the [Clipboard design](docs/design/clipboard-manager.md) for privacy limits.

## Notifications

MAGI owns `org.freedesktop.Notifications` and provides its own toast, history and
DND stack. `SUPER+N` opens Notification Centre. Notification history is currently
kept in memory; notifications and their presentation follow MAGI's settings and
fullscreen state.

## Configuration and Settings

Right-click the Control Centre bar trigger to open Settings, or use:

```bash
quickshell ipc -c magi call settingsWindow open
```

Choose themes, visual settings, icon packs/overrides, profile details and bar
placement there. Control Centre composition is configurable: enable and reorder
controls, choose primary and secondary column counts, and configure optional
sections. It is not tied to a fixed button count.

Settings are saved to a local `settings.json` beside the shell configuration.
Keep local preferences and managed assets backed up separately when restoring a
machine. The [architecture](docs/architecture.md) documents configuration ownership
and the underlying module structure.

## Installation and development

MAGI lives in `linux/magi` inside the dotfiles repository. Its deployable shell is
under `.config/quickshell/magi/`, linked to `~/.config/quickshell/magi/` with GNU Stow.

For the current Arch setup, provide:

- Hyprland, Quickshell and GNU Stow.
- NetworkManager, BlueZ, PipeWire/WirePlumber and UPower for system integrations.
- Python, python-gobject and gdk-pixbuf2 for the clipboard/settings helpers and
  image previews; wl-clipboard for clipboard restoration; brightnessctl for brightness.
- A C compiler (`base-devel`), Wayland and wayland-protocols for the clipboard
  capture helper's build on first use. The required ext-data-control protocol
  must be supported by the compositor.

Hypridle, Hyprlock, Hyprpaper and hyprpolkitagent retain their roles in the
surrounding Hyprland session. The repository's T15g startup also uses Hyprmon.
Review the [Hyprland configuration](../t15g/hypr/.config/hypr/hyprland.lua) for
machine-specific startup, monitor, keybind and window rules.

From a checkout at `~/dotfiles`, preview the ordinary Stow deployment first.
The package-local `.stow-local-ignore` keeps project documentation, development
fixtures and agent/tool metadata in the repository; runtime configuration still deploys.

```bash
cd ~/dotfiles/linux
stow --simulate --verbose --target="$HOME" magi
stow --target="$HOME" magi
```

The T15g Hyprland configuration starts `quickshell -c magi` at login. For an
existing session, launch that command only after checking that another MAGI
instance or competing notification daemon is not running. There is no public
one-command installer; dependencies and the surrounding session are provisioned
separately.

Development fixtures and focused checks live in [tests](tests/) and
[experiments](experiments/). Use the relevant design/checkpoint notes for their
scope and invocation. Development should preserve the working shell's geometry,
focus and system integrations.

## Repository and documentation

- [Documentation index](docs/README.md): current status and dated implementation records.
- [Architecture](docs/architecture.md): surface, service and module ownership.
- [Decisions](docs/decisions.md): architectural choices and debugging history.
- [Design](docs/design/): specifications, interaction contracts and annotations.
- [Research](docs/research/): source investigations and validation/checkpoint evidence.
- [AGENTS.md](AGENTS.md): project instructions for Codex and other coding agents.

Earlier research/checkpoints describe the systems present at the time. Current
retirement state is recorded in the
[Legacy Shell Retirement checkpoint](docs/research/legacy-shell-retirement-checkpoint.md).

## Roadmap

- First-party Emoji Picker.
- Calendar/date surface opened from the bar's time/date.
- A wider Control Centre action catalogue.
- A first-party MAGI lock screen, replacing Hyprlock only after a separate security review.
- Whole-shell Settings, visual and composition refinement.

These are future milestones. Hyprlock remains required today.

## Screenshots

No representative tracked screenshots are included yet. Planned views:

- Desktop and bar/status surface.
- Control Centre and a detail view.
- Settings, Notification Centre and Clipboard Manager.

Screenshots will be added after a separately reviewed capture/presentation pass.
