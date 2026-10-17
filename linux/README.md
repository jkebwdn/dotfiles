# Linux — Arch / ThinkPad T15g

The active desktop is **Arch Linux + Hyprland + Quickshell/MAGI**.
[MAGI](magi/README.md) supplies the Bar, Control Centre, Wi-Fi/Bluetooth surfaces,
first-party Notifications and Clipboard, the five-mode Hub, Calendar and Settings.
MAGI Apps is the launcher; Wallpaper management is embedded in Settings.

Ghostty, Neovim, Yazi, Thunar, Starship, Fastfetch and btop form the surrounding
application stack. Theme Orchestrator lets supported applications opt in to MAGI's
semantic palette. Hyprpaper supplies wallpapers; Hypridle and Hyprlock handle idle
and locking, with Hyprmon for monitor profiles and hyprpolkitagent for authentication.

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

Keep local MAGI preferences/backups, managed assets, Theme Orchestrator enrollment
and generated output separately backed up. Application integration hooks and the
operator's Hypridle/Hyprlock configuration may be local rather than committed.
Do not overwrite those files when restoring this checkout.

## Shortcuts and status

The [MAGI shortcut table](magi/README.md#shortcuts) records all eight current routes,
including Super+Space for Apps and Super+S for Settings. Hub stays open across normal
application clicks and closes explicitly with Escape after child interactions.

Phase 2E is natively accepted. Rofi and MFTrunk are retired, not required fallbacks.
Older shell references in research/checkpoints are historical; the current shell
is MAGI. See [accepted documentation](magi/docs/README.md) for ownership and limitations.
