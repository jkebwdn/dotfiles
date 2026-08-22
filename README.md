# dotfiles

Personal dotfiles and system configuration for my Linux, macOS, and Windows machines.

The repository is organised by operating system and machine, allowing each system to maintain its own configuration while keeping everything together in a single version-controlled repository.

Configurations are primarily managed using Stow.

---

## Systems

### Linux — ThinkPad T15g

Arch Linux workstation running Hyprland.

Current configuration includes:

- Hyprland
- Waybar
- Ghostty
- Neovim
- SwayNC
- Yazi
  - Yatline
  - Custom theme
- btop
- Hyprmon
- MFTrunk
- systemd user services

This is currently the most complete configuration in the repository.

### macOS

macOS configurations are maintained separately from Linux rather than attempting to keep identical configurations across platforms.

Current tooling includes:

- AeroSpace
- SketchyBar
- JankyBorders
- Ghostty
- Neovim

The setup follows the same general keyboard-driven workflow as the Linux environment while remaining native to macOS.

### Windows

Windows configuration is currently focused around a keyboard-driven tiling workflow using:

- Komorebi
- Komorebi Bar
- whkd

Further configuration will be migrated into the repository over time.

---

## Repository Structure

```text
dotfiles/
├── linux/
│   └── t15g/
│       ├── ghostty/
│       ├── hypr/
│       ├── hyprmon/
│       ├── mftrunk/
│       ├── nvim/
│       ├── rofi/
│       ├── swaync/
│       ├── systemd/
│       ├── waybar/
│       └── yazi/
├── macos/
└── windows/
```

Each package mirrors its destination relative to the home directory so it can be managed independently using GNU Stow.

For example:

```text
linux/t15g/hypr/.config/hypr/
```

is linked to:

```text
~/.config/hypr/
```

---

## GNU Stow

Packages can be linked individually from the relevant machine directory.

For example:

```bash
cd ~/dotfiles/linux/t15g

stow hypr
stow waybar
stow ghostty
stow yazi
```

This keeps configuration files inside the Git repository while exposing them at the locations expected by each application.

---

## MFTrunk

MFTrunk is a custom terminal-based system control utility developed for the Linux configuration.

It currently provides controls and information for:

- Wi-Fi
- Bluetooth
- Audio
- Battery
- VPN
- Diagnostics
- Power

The aim is to provide a lightweight, terminal-native control centre that integrates naturally with the rest of the desktop environment.

---

## Notes

This repository is continuously evolving as the configurations for each machine are refined and migrated.

The Linux T15g configuration is currently the most complete, with the macOS and Windows environments being progressively consolidated into the same repository structure.
