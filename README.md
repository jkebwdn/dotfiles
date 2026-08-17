# dotfiles

Personal dotfiles and system configuration for my Linux, macOS, and Windows machines.

The repository is structured by operating system and machine, allowing each system to maintain its own configuration while keeping everything under a single version-controlled repository.

Configurations are managed using Stow.

** Systems **

# Linux

## T15G

Arch Linux workstation running Hyprland.

Current configuration includes:

- Hyprland
- Waybar
- Rofi
- Ghostty
- Neovim
- SwayNC
- Hyprmon
- MFTrunk
- systemd user services

# macOS

Planned.

# Windows

Planned.

Structure:

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
│       └── waybar/
├── macos/
└── windows/

Each package mirrors its destination relative to the home directory so it can be managed independently with Stow.

For example:

linux/t15g/hypr/.config/hypr/ is linked to ~/.config/hypr/

** GNU Stow **

Packages can be linked individually from the machine directory:

bash
cd ~/dotfiles/linux/t15g

stow hypr
stow waybar
stow rofi
stow ghostty

This keeps the live configuration in the expected locations while the actual files remain inside the Git repository.

# MFTrunk

MFTrunk is a custom terminal-based system control utility currently providing functionality for:

- Wi-Fi
- Bluetooth
- Audio
- Battery
- VPN
- Diagnostics
- Power controls

MFTrunk is being developed as a lightweight, terminal-native control centre for the system.

# Notes

This repository is a work in progress.

The current T15G configuration is the first system being migrated into the new structure. macOS and Windows configurations will be added as their setups are consolidated.
