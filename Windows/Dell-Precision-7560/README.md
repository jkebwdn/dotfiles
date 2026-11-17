# Dell Precision 7560 — Black Metal Rice

Windows 11 Business / PowerShell 7 / Komorebi

## Components

- Komorebi — BSP tiling window manager
- komorebi-bar — status bar
- whkd — keyboard shortcuts
- Flow Launcher — application launcher (Alt+Space)
- Starship — PowerShell prompt
- Fastfetch — terminal system information
- Windows Terminal — Black Metal colour scheme
- StartAllBack — Windows shell customisation

## Package management

Scoop is used for the user-installed tools.

Installed applications include:

- git
- 7zip
- komorebi
- whkd
- starship
- fastfetch
- flow-launcher

JetBrains Mono Nerd Font is used in Windows Terminal.

## Configuration

Live configuration files are located under:

    ~/.config/

Repository copies are maintained under:

    ~/dotfiles/Windows/Dell-Precision-7560/

GNU Stow is not used because this managed Windows installation
does not permit unprivileged symbolic link creation.

## Synchronisation

From PowerShell 7:

    rice-save
    rice-status
    rice-restore -WhatIf

To restore configuration files:

    rice-restore

Restoration backs up existing files under:

    ~/dotfiles-backups/Dell-Precision-7560/

Review repository changes before committing or pushing.

## Komorebi

The configuration uses four workspaces.

Application-specific rules are fetched separately using:

    komorebic fetch-asc

Place the resulting applications.json under:

    ~/.config/komorebi/applications.json

The repository stores a portable application-rules path.
The restore script resolves it for the current user.

## PowerShell

The main profile is:

    ~/.config/powershell/profile.ps1

The PowerShell 7 profile loader must dot-source this file.

Example loader:

    . "$HOME\.config\powershell\profile.ps1"

The loader location depends on the user's Documents folder.

## Startup

The Windows Startup folder contains a shortcut named:

    Black Metal Rice.lnk

It launches PowerShell 7 with:

    -NoLogo -NoProfile -File "<HOME>\.config\powershell\start-rice.ps1"

Flow Launcher manages its own startup.

## Flow Launcher

The custom theme is:

    Black Metal Khold.xaml

The theme is restored to both:

    ~/.config/flow-launcher/
    ~/scoop/persist/flow-launcher/UserData/Themes/

Search history, plugin data and application settings are not
included in this repository.

## Windows Terminal

PowerShell 7 is the default profile.

The terminal uses JetBrains Mono Nerd Font and the Black Metal
colour palette.

Windows Terminal settings are included in WindowsTerminal/settings.json.

## Notes

This is a corporate-managed laptop.

No security controls, execution policies or administrator
permissions are modified by the configuration scripts.

Machine-specific settings and potentially sensitive application
data should be reviewed before publishing.
