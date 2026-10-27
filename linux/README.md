# Linux — Arch / ThinkPad T15g

The active desktop is **Arch Linux + Hyprland + Quickshell/MAGI**.
[MAGI](magi/README.md) supplies the Bar, Control Centre, Wi-Fi/Bluetooth surfaces,
first-party Notifications and Clipboard, the five-mode Hub, Calendar and Settings.
MAGI Apps is the launcher; Wallpaper management is embedded in Settings. Audio
provides output/input routing and grouped application volumes; Bluetooth supports
pairing, and System Tray hosts application icons and native menus.

Ghostty, Neovim, Yazi, Thunar, Starship, Fastfetch and btop form the surrounding
application stack. Theme Orchestrator lets supported applications opt in to MAGI's
semantic palette and application appearance. Hyprpaper supplies wallpapers; managed
Hypridle handles idle policy and the native MAGI lock owns locking, with Hyprmon for
monitor profiles and hyprpolkitagent for authentication prompts.

## Layout and Stow

- [`magi/`](magi/) is a Stow package plus its source, tests and documentation.
- [`t15g/`](t15g/) contains machine/application Stow packages.
- [`hyprland.lua`](t15g/hypr/.config/hypr/hyprland.lua) owns session startup,
  monitor configuration and shortcuts; review its hardware-specific values.

Install the applications first and back up existing configuration. Preview selected
packages before linking them into your home directory:

```bash
cd ~/dotfiles/linux/t15g
stow --simulate --verbose --target="$HOME" hypr ghostty nvim yazi
stow --target="$HOME" hypr ghostty nvim yazi
cd ~/dotfiles/linux
stow --simulate --verbose --target="$HOME" magi
stow --target="$HOME" magi
```

MAGI's ignore rules exclude development files from Stow. Its
[installation guide](magi/README.md#installation-and-development) lists runtime
backends. Hyprland starts MAGI at login; do not run a second notification daemon.

Tracked application configuration contains stable bootstrap hooks; generated theme
payloads and journals live outside Git. Theme switching must not rewrite tracked
source. Live MAGI settings.json is untracked/exact-ignored, with schema 22 defaults
in code. Keep local preferences, backups, managed assets and generated state
separately backed up. Native lock and managed Hypridle need separate provisioning;
Stow alone does not install those services. See [ownership](magi/docs/generated-state.md).

## Shortcuts and status

The [MAGI shortcut table](magi/README.md#shortcuts) records the ten current routes,
including Super+A for Audio, Super+T for the non-persisting inline Bar Tray toggle,
Super+Space for Apps and Super+S for Settings. Hub stays open across normal
application clicks and closes explicitly with Escape after child interactions.

Older shell references in research/checkpoints are historical; the current shell
is MAGI. See [current documentation](magi/docs/README.md) for ownership and limitations
and the [closeout policy](magi/docs/phase-closeout.md) for ephemeral worktrees and
exact-path staging. `~/dotfiles` remains the persistent source checkout.
