# dotfiles

My personal desktop and terminal configuration, organised by platform and machine.
Linux and macOS packages are managed with GNU Stow; the Windows configuration is
maintained manually. These are working machine configurations, with hardware and
personal preferences to review before reusing them.

## Systems

### Arch Linux — ThinkPad T15g

The [Linux setup](linux/README.md) uses **Arch Linux + Hyprland + MAGI**.
[MAGI](linux/magi/README.md) is my Quickshell shell: Bar, Control Centre, utility
Hub, Settings, Audio routing and per-application volume, Bluetooth pairing, System
Tray, Wallpaper Manager and a native secure lock. Its shared multi-monitor
architecture routes surfaces to the appropriate output.

Hypridle handles idle policy; Hyprpaper supplies wallpapers and Hyprmon manages
monitor profiles. The terminal workflow uses Ghostty, Neovim, Yazi, Thunar and btop;
Theme Orchestrator coordinates supported application palettes and appearance.

### macOS — Mac mini

The [Mac mini configuration](macos/mac-mini/) uses Yabai and skhd for tiling and
shortcuts, SketchyBar for the bar, and JankyBorders for window borders. Ghostty,
Neovim and Fastfetch have their own macOS packages.

### Windows — Dell Inspiron 7501

The [Windows configuration](Windows/Dell-Inspiron-7501/README.md) uses Komorebi,
Komorebi Bar and whkd on the work laptop. It is deployed by copying the relevant
files manually; the machine README records destinations and setup details.

## Repository layout

```text
dotfiles/
├── linux/
│   ├── magi/                 # MAGI shell, tests and documentation
│   └── t15g/                 # Hyprland and application Stow packages
├── macos/
│   └── mac-mini/             # macOS Stow packages
└── Windows/
    └── Dell-Inspiron-7501/   # Manually deployed Windows configuration
```

A Stow package mirrors its destination beneath the home directory. For example,
`linux/t15g/hypr/.config/hypr/` is linked as `~/.config/hypr/`.

## Setup and restoration

Install the platform's applications first, then clone this repository to
`~/dotfiles`. Review the machine-specific files with `nvim`, particularly monitor
layouts, paths and keybinds. Back up existing configuration before linking files.
This repository supplies configuration rather than a complete OS installer.

For the T15g application packages, preview the links before applying them:

```bash
cd ~/dotfiles/linux/t15g
stow --simulate --verbose --target="$HOME" hypr ghostty nvim yazi
stow --target="$HOME" hypr ghostty nvim yazi
```

Deploy MAGI from the Linux package directory:

```bash
cd ~/dotfiles/linux
stow --simulate --verbose --target="$HOME" magi
stow --target="$HOME" magi
```

MAGI's package-local ignore rules keep documentation, development fixtures and
agent files out of the deployment. See its
[installation instructions](linux/magi/README.md#installation-and-development)
for dependencies and session integration. Use the same Stow workflow from
`macos/mac-mini` for selected macOS packages. Use
`stow --delete --target="$HOME" PACKAGE` from the relevant package directory to
unlink a package before retiring it.

On Arch, start from a working Hyprland session and provision the backends listed
in MAGI's README. Hyprland starts MAGI at login. Native lock deployment and the managed Hypridle
service require their own setup; Stow alone does not install them. Keep separate
backups of local preferences and application data.

Detailed MAGI architecture and migration evidence live in its
[documentation index](linux/magi/docs/README.md).

## Source and runtime ownership

`~/dotfiles` is the persistent source of truth. Tracked files contain static
configuration and stable bootstrap hooks; generated themes, activation journals
and runtime state live outside Git in XDG stores. Normal theme switching leaves
tracked configuration unchanged. Live MAGI `settings.json` is operator-local,
untracked and exact-ignored; schema **22** defaults come from the Settings code.
See [generated-state ownership](linux/magi/docs/generated-state.md).

Development worktrees are ephemeral: after accepted work is merged/pushed and
synchronized, verify they contain no unique work, remove them and prune stale
registrations. Do not retain permanent `magi-phase*` checkouts. Stage exact paths
or hunks in MAGI workflows—never `git add .` or `git add -A`. See the
[closeout checklist](linux/magi/docs/phase-closeout.md).
