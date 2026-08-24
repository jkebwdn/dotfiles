# Dell Inspiron 7501

Dotfiles and configuration for my Dell Inspiron 7501 work laptop running Windows 11.

This setup uses **Komorebi** for tiling window management and **whkd** for keyboard shortcuts, with Komorebi's built-in status bar.

> This is a restricted work machine, so these configs are maintained and deployed manually rather than using GNU Stow or symlinks.

## Setup

* Windows 11
* Komorebi
* whkd
* Komorebi Bar
* PowerShell
* Scoop
* JetBrains Mono

## Configuration

### Komorebi

Repository files:

```text
Komorebi/
├── komorebi.json
└── komorebi.bar.json
```

Live configuration:

```text
C:\Users\<username>\komorebi.json
C:\Users\<username>\komorebi.bar.json
```

### whkd

Repository file:

```text
whkd/
└── whkdrc
```

Live configuration:

```text
C:\Users\<username>\.config\whkdrc
```

## Window Manager

Komorebi is configured with:

* BSP tiling
* 4 workspaces
* 6px workspace padding
* 6px container padding
* 4px window borders
* Cloak window hiding
* Insert behaviour when moving windows between monitors
* Application-specific floating rules

## Keybindings

Keyboard shortcuts are handled by **whkd**.

The configuration uses the **left Windows key (`LWin`)** as the main modifier, giving the setup similar navigation to my other tiling window-manager environments.

The `whkdrc` file contains the complete keybinding configuration.

## Bar

Komorebi Bar provides:

**Left**

* Date
* Time

**Centre**

* Workspaces 1–4

**Right**

* Network
* Battery

The bar uses **JetBrains Mono** and a Base16 theme.

## Theme

The desktop is based around the **Base16 Black Metal (Khold)** palette.

Primary accent:

```text
#A26862
```

Unfocused border:

```text
#262220
```

The muted red accent is used for focused Komorebi window borders and complements the custom Cobalt Energy wallpaper.

## Starting Komorebi

Start Komorebi, whkd and the bar together:

```powershell
komorebic start --whkd --bar
```

Reload the configuration after making changes:

```powershell
komorebic reload-configuration
```

## Restarting whkd

If the keybindings stop responding:

```powershell
Stop-Process -Name whkd -Force -ErrorAction SilentlyContinue
Start-Process whkd -WindowStyle Hidden
```

The whkd configuration should be detected at:

```text
C:\Users\<username>\.config\whkdrc
```

Check the Komorebi configuration and whkd path with:

```powershell
komorebic check
```

## Updating

Komorebi and whkd are installed through Scoop.

```powershell
scoop update
scoop update komorebi
scoop update whkd
```

Check installed versions with:

```powershell
komorebic --version
whkd --version
```

## Notes

This configuration is designed primarily for the laptop display.

The machine is occasionally used with a dual-monitor dock, but the current stable Komorebi configuration retains the four-workspace single-monitor layout rather than maintaining a separate multi-monitor configuration.

Configuration changes on this machine are copied back to this repository manually.
