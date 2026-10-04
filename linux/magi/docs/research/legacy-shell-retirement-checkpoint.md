# Legacy shell retirement — 2026-10-04

Status: live retirement, automated validation and operator interaction checks
passed; ready for operator review. No staging, commit or push. Baseline `a5cce6b` on `main`,
matching the local `origin/main` ref; no network refetch was needed or performed.
Scope: retire superseded shell infrastructure, with no MAGI feature or visual work.

## Audit and actual removal

| Component | Installed package found | Initial live state | Retirement |
| --- | --- | --- | --- |
| Waybar | `waybar 0.15.0-3` | No process; packaged service disabled/inactive; deployed `~/.config/waybar` Stow directory symlink | Unstowed before deleting repository package; pacman removal |
| SwayNC | `swaync-git r677.1043ef9-1` (provides swaync/client/notification-daemon) | No process; service masked/inactive; greeting service/timer linked/inactive, no enablement; deployed `~/.config/swaync` Stow directory symlink | Unstowed before package deletion; pacman removal; mask/greeting infrastructure retired |
| Noctalia | `noctalia 5.2.1-1` | No process/startup/service found; native `/usr/bin/noctalia`, not a Quickshell config; only local config `~/.config/noctalia/nerv.toml` | Pacman removal and local config removal; no tracked Noctalia Stow package existed |
| cliphist | `cliphist 1:0.7.0-2` | No recorder or wl-paste watcher; packaged service disabled/inactive; Hyprland watcher already removed | Pacman removal; old history preserved |

`pacman -Qi` reported Required By and Optional For **None** for all four.
Noctalia was installed from `extra/noctalia` on 2026-09-19 (5.1.0), then upgraded
to 5.2.1 on 2026-10-03. The authoritative local pacman log confirms the mechanism;
its relationship to earlier Noctalia v4 research does not imply a v4 install.
SwayNC was an unsigned locally built `-git` package, also managed by pacman.
No separate `swaync-git-debug` package remained installed.

The operator authenticated and ran exactly:

```sh
sudo pacman -R waybar swaync-git noctalia cliphist
```

`/var/log/pacman.log` records the transaction at **07:42:24 BST**, removing exactly
those four packages. No recursive flags, dependency removal, orphan purge or
package upgrade occurred. No legacy processes required termination.

Deployment cleanup used explicit-home-target `stow --delete` for Waybar/SwayNC
before deleting their packages. The SwayNC mask was deliberately retained until
package removal was independently confirmed. Then `stow --delete systemd`
removed its three deployed unit links, before deleting repository machinery and
running `systemctl --user daemon-reload`.

The entire `linux/t15g/systemd` package contained **only** two greeting definitions,
a relative `swaync.service` link, package-local `/dev/null` mask target and its
Stow ignore rule. No unrelated useful configuration was present, so the now-empty
package was retired entirely. Other user-systemd configuration remains intact.
Two obsolete SwayNC-only Hyprland layer rules were removed; no other Hyprland
setting changed. No explicit Hyprland reload or Quickshell restart was issued.

## Retained packages and data

- `wl-clipboard 1:2.3.0-1`: MAGI restores through `wl-copy`; hyprshot also requires
  it, with optional consumers including grimblast, hyprpicker, Neovim and Yazi.
  Both `/usr/bin/wl-copy` and `/usr/bin/wl-paste` remain and execute successfully.
- Quickshell 0.3.1-1, Hyprland 0.56.2-3, all shared libraries/backends and unrelated
  desktop packages remain installed. Hypridle, Hyprlock and Hyprpaper retain their
  existing responsibilities. No attempt was made to purge Noctalia's dependencies.
- Newly orphaned according to the before/after `pacman -Qdtq` difference:
  `gpsd`, `granite7`, `gtkmm3`, `libical`, `libmpdclient`, `libqalculate`, `playerctl`,
  `spdlog`. All remain installed. Being an orphan is not proof of no script usage.
  Existing pre-milestone orphans were also left alone.
- Old cliphist database remains at `~/.cache/cliphist/db`, size **417579008 bytes**,
  inode **53906103**, mtime **2026-10-03 22:01:56 BST**. Before/after size, inode,
  nanosecond mtime and ctime match. Database contents were never read, hashed,
  imported or deleted. No `~/.local/share/cliphist` directory was present.

## Bounded source evidence and reference classification

Inspected **2026-10-04**. Findings are locally verified facts, not screenshots or
inferences from reference-project designs. No external API change or reused
code/assets was introduced, so no new upstream API/license research was needed.

| Source URL / local evidence | Version / relevant source | What it demonstrates and relevance | Compatibility / remaining test |
| --- | --- | --- | --- |
| `file:///var/lib/pacman/local/`, `file:///var/log/pacman.log` | Package versions above; `pacman -Qi/-Ql/-Qdtq` | Ownership, dependencies, install provenance and exact removal; use pacman rather than guessing an install mechanism | Shared dependencies retained; no general orphan investigation |
| [Baseline Hyprland source](https://github.com/jkebwdn/dotfiles/blob/a5cce6b/linux/t15g/hypr/.config/hypr/hyprland.lua) (inspected locally) | `hl.on("hyprland.start")`, notification/Clipboard keybinds, two SwayNC layer rules | Only MAGI starts as shell; obsolete rules were the sole remaining live Hyprland legacy reference | Installed Hyprland 0.56.2; Lua parse and live configerrors pass; fresh login not tested |
| [Baseline systemd package](https://github.com/jkebwdn/dotfiles/tree/a5cce6b/linux/t15g/systemd) (inspected locally), `file:///home/jkebwdn/.config/systemd/user/` | Greeting ExecStart, relative mask and `/dev/null` target | Package is exclusively SwayNC rollback machinery; simulated Stow deletion identified exactly three deployed links | Manager reload; legacy units not-found/inactive and no broken user links |
| [Baseline shell](https://github.com/jkebwdn/dotfiles/blob/a5cce6b/linux/magi/.config/quickshell/magi/shell.qml), Clipboard/Notifications services and Bar IPC (inspected locally) | ShellRoot activation; Clipboard.restore/backend `wl-copy`; status/open/toggle IPC | First-party ownership/capture is independent of retired packages; `wl-clipboard` remains needed | Quickshell 0.3.1 unchanged; current process validated; no post-removal restart claimed |
| `file:///home/jkebwdn/.config/noctalia/nerv.toml`, `pacman -Ql noctalia` | Noctalia 5.2.1 config/native binary | One local shell config, no separate Quickshell deployment or start route | Removed only this setup's local Noctalia config; shared dependencies retained |

Bounded searches covered the tracked repository, live Hyprland and user-systemd
configuration, local scripts/application entries, login shell files, system user
units, D-Bus activation files and `/etc/xdg/autostart`. Missing optional directories
were treated as absent, not as search matches. Final runtime/config searches find
no active legacy startup/activation route.

Classification:

1. **Current documentation updated:** root README, MAGI README/research index,
   architecture, current notification design, Quickshell reference and a new
   dated decision. They describe Arch + Hyprland + MAGI and supersede the rollback.
2. **Obsolete runtime removed:** Waybar and SwayNC Stow packages/scripts/styles,
   SwayNC-only systemd package and layer rules, local Noctalia config, packaged
   legacy services/D-Bus activation files/binaries through pacman.
3. **Historical evidence retained:** existing research/checkpoints, earlier dated
   README/decision entries and reference-project design investigations still
   mention SwayNC, Waybar, Noctalia or cliphist where accurate at that time.
   `AGENTS.md` Noctalia research priority remains an instruction, not a runtime
   dependency. Existing historical checkpoint files were not rewritten.

## Documentation changes

Root README removes legacy components/tree/Stow examples and SwayNC rollback
instructions; lists MAGI's bar, Control Centre, Settings, notifications/toasts/
history/DND and Clipboard; documents explicit Stow home targets and a bounded
fresh-install procedure. MAGI README and research index now point here; current
architecture/API/design wording removes the installed-mask assumption.
The existing MAGI README future-work location lists Emoji Picker, date/Calendar
panel, security-reviewed MAGI lock screen, broader CC actions and the later
Settings/visual/composition pass. These remain future milestones. Hyprlock is
neither modified nor removed.

## Runtime validation

Verified on the existing eDP-1 scale-2 session after package retirement:

- MAGI PID **143717**, instance **5w23m8kcmt**, remains running. Startup log shows
  successful launch/config load; installed Quickshell still executes. No restart
  was requested or performed, so a new post-removal cold start/login is **not**
  claimed. Existing automatic notification/Clipboard activation source unchanged.
- Exactly one intended main top-layer surface, **1920×1080 at (0,0)**. A deliberate
  notification adds its normal `magi-toasts` surface; it is not a second main layer.
- MAGI IPC reservation **48**, compositor reservation **[0,48,0,0]**, unchanged.
- Control Centre IPC open reaches active `controlcentre`, phase 3, interactive=true;
  close returns to idle with no catcher/focus retention.
- Clipboard IPC toggles open/closed; native desktop client is floating **540×660**,
  class `org.quickshell`, title `MAGI Clipboard`. Ready/monitoring true, error empty,
  persistence false. No clipboard payload was read/replaced by agent validation.
- Notification name's Unix PID is **143717**. Harmless Notify returns ID **27**;
  history increases 9→10 and toast count 0→1; it later expires normally.
- All four legacy packages absent; no legacy process or wl-paste recorder. Legacy
  service definitions including both greeting units are **not-found/inactive**;
  no remaining unit-file listing, D-Bus or active-config startup reference.
- User-systemd failed units **0**; broken user-unit symlinks **0**.
- Hyprland configerrors empty; `luac -p` passes for cleaned configuration.
- Production `log.log` is INFO-only, **0 warning/error lines**; no new reload was
  caused by this cleanup. `git diff --check` passes.

Operator confirmed: all requested interaction tests passed, a newly copied harmless
text sample appears in Clipboard, and the retirement notification reached MAGI.
The operator chose when to replace their clipboard; the agent did not inspect it.

## Initial retirement Git allowlist and unrelated dirt (23 paths)

Intended paths, relative to `/home/jkebwdn/dotfiles` (no broad staging):

```text
README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/notifications-toasts.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/README.md
linux/magi/docs/research/legacy-shell-retirement-checkpoint.md
linux/t15g/hypr/.config/hypr/hyprland.lua
linux/t15g/swaync/.config/swaync/config.json
linux/t15g/swaync/.config/swaync/scripts/swaync-greeting.sh
linux/t15g/swaync/.config/swaync/scripts/toggle-bluetooth.sh
linux/t15g/swaync/.config/swaync/scripts/toggle-wifi.sh
linux/t15g/swaync/.config/swaync/style.css
linux/t15g/systemd/.config/systemd/user/swaync-greeting.service
linux/t15g/systemd/.config/systemd/user/swaync-greeting.timer
linux/t15g/systemd/.config/systemd/user/swaync.service
linux/t15g/systemd/.stow-local-ignore
linux/t15g/systemd/mask-targets/swaync.service
linux/t15g/waybar/.config/waybar/config.jsonc
linux/t15g/waybar/.config/waybar/scripts/powermenu.sh
linux/t15g/waybar/.config/waybar/scripts/swaync-bell.sh
linux/t15g/waybar/.config/waybar/style.css
```

The whole SwayNC package deletion intentionally supersedes the pre-existing dirty
`config.json` greeting (August17 → October03/weather text). Its diff was inspected
before deletion; it is not staged/preserved or represented as newly authored work.

Unrelated paths left untouched, verified by before/after SHA-256:

```text
linux/t15g/hypr/.config/hypr/hypridle.conf
linux/t15g/hypr/.config/hypr/hyprlock.conf
urface architecture"
```

These remain untracked exactly as at task start. The Git index remains empty.
Final reconciliation passed: exactly 23 intended paths plus those three unrelated
untracked paths, no unexpected changes and no staged changes.

## Deferred / operator checkpoint

No dependency purge, old cliphist history deletion, lock migration, subsystem or
visual work. A fresh-login/cold-start regression remains separate from this live
session validation and would require an approved restart (which also clears
session-only Clipboard history). Temporary audit scripts/results are in `/tmp`,
outside the Git allowlist. Stopped at the validated Arch + Hyprland + MAGI checkpoint for operator review.


## Post-retirement system / rice hygiene audit — 2026-10-04

Bounded extension requested by the operator; accepted retirement edits preserved.
No commit/push or MAGI QML change. Sources inspected locally on 2026-10-04:
`file:///var/lib/pacman/local/`, `file:///var/log/pacman.log`, targeted
`file:///home/jkebwdn/.bash_history`, current dotfiles at baseline `a5cce6b` plus
retirement edits, live user/system service state and identifiable rice directories.
No external API research or code/asset reuse. Findings below are verified within
this scope; absence of a reference cannot rule out undocumented manual use.

### Stray quoted file: identified accidental captured diff

Exact literal pathname in JSON notation:

```json
"/home/jkebwdn/dotfiles/urface architecture\""
```

Filename bytes, hexadecimal: `7572666163652061726368697465637475726522`.
There is one literal trailing double quote, with no newline or hidden prefix.
Regular file, UTF-8 Unicode text with terminal escape sequences, **25958 bytes**,
mode **0644 / -rw-r--r--**, owner/group **jkebwdn (1000)**, inode **3277177**.
Birth **2026-09-25 17:55:44.214828437 BST**; modification and change both
**2026-09-25 17:55:44.215828437 BST**. It contains 374 lines of a single diff of
`linux/magi/docs/research/architecture-experiment.md`, with 1065 ANSI escapes.

After stripping only ANSI colour sequences, the entire contents match exactly
`git show --format= --no-color 4fdd23f -- linux/magi/docs/research/architecture-experiment.md`.
That commit, “magi: validate combined bar surface architecture”, is dated
**2026-09-25 17:57:36 BST**, about two minutes after the file was created. It changes
experiment/runtime evidence, not private application data. The filename has no
history in `git log --all -- <literal name>`. Targeted phrase search finds existing
MAGI surface documentation and only two relevant saved shell-history commit
commands (lines234 and255); no malformed creation command is retained.

**Verified:** redundant coloured output of an already committed documentation diff.
**Inference:** likely malformed pasted command/redirection; its exact creator
command cannot be established. This is clearly accidental junk rather than a
unique document. Removed under the operator's explicit instruction after verifying
its hash and full diff match. It was untracked, so deletion adds no Git diff path.
The original retirement section above records its earlier preservation; this
appendix supersedes that state deliberately.

### Package/debug inventory and candidates

Inspected `pacman -Qqe` (explicit packages), `-Qqen` (explicit native subset,
**108** packages), `-Qm` (**27** foreign/AUR packages), `-Qdtq` (**23** pre-hygiene
orphans), and installed names ending exactly in `-debug`. Full inventories are
saved in `/tmp/magi-hygiene-baseline.json`; unrelated applications were not judged.

**No SwayNC package/debug package remains installed.** The pacman log explicitly
records `swaync-git-debug r677.1043ef9-1` removal on
**2026-06-07 10:58:52 BST**, months before this retirement. Neither `swaync`,
`swaync-git`, `swaynotificationcenter` nor a SwayNC debug variant is installed.
Remaining debug packages: `csakura-debug 2.1.0-1`, `matugen-bin-debug 4.2.0-1`,
`yay-debug 13.0.1-1`. Their respective parent packages are installed at matching
versions. None is an unambiguous missing-parent leftover; all retained.
`debugedit` is a build tool, not a `*-debug` split package.

All eight newly orphaned packages were installed **as dependencies**, with
**Required By=None and Optional For=None** now. No direct reference was found in
active Linux dotfiles, MAGI source, local scripts, user services or shell startup;
no observable process mapping contains their candidate libraries. GPS service
and socket are disabled. Installed-package metadata and initial-install pacman
transactions corroborate their former consumers; these are stronger evidence
than orphan status alone.

| Candidate / installed version | Former consumer / independent-purpose evidence | Classification and recommendation |
| --- | --- | --- |
| gpsd 3.27.5-1 | Waybar dependency; installed in original Waybar transaction; no GPS process/startup/caller found | Safe to remove now with operator/sudo approval |
| granite7 7.8.1-1 | SwayNC dependency; no remaining consumer found | Safe to remove now with operator/sudo approval |
| gtkmm3 3.24.11-1 | Waybar dependency; no remaining consumer found | Safe to remove now with operator/sudo approval |
| libical 4.0.5-1 | Noctalia dependency; first installed with Noctalia 2026-09-19 | Safe to remove now with operator/sudo approval |
| libmpdclient 2.27-1 | Waybar dependency; no MPD client integration found | Safe to remove now with operator/sudo approval |
| libqalculate 5.12.0-1 | Noctalia dependency, but first installed 2026-02-05; Qalculate state predates Noctalia, purpose uncertain | Probably obsolete but operator decision required; retain |
| playerctl 2.4.1-5 | Waybar dependency; no keybind/script/history-token caller. MAGI Media.qml imports Quickshell.Services.Mpris and MediaController invokes native player methods directly | Safe to remove now with operator/sudo approval; not a MAGI MPRIS dependency |
| spdlog 1.17.0-2 | Waybar dependency; no remaining consumer found | Safe to remove now with operator/sudo approval |
| hyprpanel-bin 0.3.1-1 | Explicit old panel install, no live/config/startup integration found | Probably obsolete but operator decision required; retain |
| aylurs-gtk-shell-git 3.1.2.r0.gbbee2f1-2 | Explicit GTK shell install, no live/config/startup integration found | Probably obsolete but operator decision required; retain its Astal/GJS dependencies too |
| awww 0.12.1-1 | Explicit wallpaper tool install, no current integration; Hyprpaper is active | Probably obsolete but operator decision required; retain |
| matugen-bin 4.2.0-1 and matching debug | Explicit palette tool install, no current template/caller found; independent manual use possible | Probably obsolete but operator decision required; retain both |
| network-manager-applet | No process, but package supplies XDG nm-applet autostart and independently useful network GUI | Uncertain independent purpose; retain |
| Rofi, pamixer, Hyprmon | SUPER+SPACE launcher, audio keybinds, Hyprland startup/running monitor tool | Keep — actively used |
| Hyprlock, Hypridle, Hyprpaper, Quickshell/MAGI, wl-clipboard, Stow | Protected tools and current session requirements | Keep — required/protected |

Candidate table was presented before additional removal. Smallest recommended
explicit package transaction, requested from the operator:

```sh
sudo pacman -R gpsd granite7 gtkmm3 libical libmpdclient playerctl spdlog
```

Operator approved and completed this exact seven-package transaction, independently
verified in pacman's log at **2026-10-04 08:01:55–08:01:56 BST**. The earlier
misspelled attempt (`libmpdcclient`) produced no transaction; the corrected command
removed exactly the seven requested packages. No recursive flags or general orphan cleanup.
No speculative package removals are authorised by absence of reverse dependencies.

### Startup, directories and repository hygiene

Enabled user units comprise hyprpolkitagent, PipeWire/Pulse/WirePlumber,
xdg-user-dirs and standard sockets. Failed user units: **0**. Remaining user links
resolve to installed services; no stale rice unit or activation path found.
Hyprland startup runs hyprpolkitagent, Hyprpaper, Hypridle, Hyprmon and MAGI;
Rofi/pamixer/brightness and screenshot keybinds remain valid. Shell startup uses
start-hyprland and installed blesh. `~/.config/autostart` and
`~/.local/share/systemd/user` are absent; relevant `/etc/xdg/autostart` Exec routes
point to installed accessibility, nm-applet and xdg-user-dirs tools. Unrelated
application services untouched.

| Location | Inventory (payload contents not inspected) | Classification / action |
| --- | --- | --- |
| ~/.cache/noctalia | 3 files, 144631 bytes: log and two thumbnails | Operator approved deletion; exact three-file inventory verified and removed |
| ~/.local/state/noctalia | 224 files, 1709487 bytes; notification history/assets, settings/state and community/plugin sources | User data/history requiring explicit operator decision; preserved |
| ~/.local/share/qalculate | 3 exchange-rate files, 7976 bytes | Possible independent calculator state; preserved |
| ~/.local/state/qalculate | Empty qalc.history file (0 bytes) | State requiring operator decision; preserved |
| ~/.cache/cliphist/db | 417579008 bytes (about 398.2 MiB); original metadata preserved | Private history; do not delete. May be deliberately erased later by operator |
| ~/.cache/yay | Old rice package build entries including SwayNC, Waybar-git, HyprPanel, Walker/Elephant, Astal, Matugen | Package-manager build/source cache; retained, no broad cache purge |
| ~/.config/qt5ct, ~/.config/qt6ct, ~/.config/pavucontrol.ini | Two 32-byte Qt configs and 138-byte audio-GUI config; matching packages absent, no active reference found | Probable stale configuration; preserved for operator choice |
| MAGI/Quickshell, Hyprland, Rofi and other active config/cache | Current session resources | Still actively used; preserved |

No Waybar/SwayNC/Noctalia active config/startup route remains. No tracked dead
Stow package, broken repository symlink, broken home/config dotfile link or empty
T15g Stow package found. No tracked `.pyc`, `.qslog`, `.log`, `.o`, package archive,
`__pycache__`, `node_modules` or `.cache` artifact found in the repository.
The Rofi theme references a historically named `WofiHeader-rofi.png` asset, used by
current Rofi; its name does not establish a live Wofi dependency. Existing historical
research/checkpoints and prior retirement findings remain intact. No architecture
rewrite or unrelated README/config alteration was needed for this appendix.

### Hygiene completion and validation

Completed approved cleanup:

- Removed exactly `gpsd`, `granite7`, `gtkmm3`, `libical`, `libmpdclient`, `playerctl`
  and `spdlog`, through the operator-authenticated explicit pacman transaction.
- Removed the verified accidental untracked captured-diff file and approved
  Noctalia cache only. All 224 Noctalia state files retain identical size/mtime/inode
  metadata across cache deletion; notification history/settings/plugin sources stay.
- Retained libqalculate, HyprPanel, AGS/Astal/GJS, awww, Matugen and all three
  installed debug packages; operator choice remains necessary for these candidates.
- Newly orphaned by this second transaction: **atkmm, fmt, libgee, pangomm,
  pps-tools**. Retained without recursive removal or another dependency audit.
  Current orphan total is 21. No unapproved package removal or general cache purge.

Post-package-removal live validation passes: MAGI PID 143717 remains running;
Control Centre reaches phase 3/interactive and closes cleanly; Clipboard toggles as
its normal 540×660 desktop client, backend ready/monitoring with no error. Native
capture helper remains running. Notification D-Bus owner is still 143717; another
harmless notification enters history and produces a toast. Main layer remains one
1920×1080 surface with exact 48px reservation; Hyprland errors empty; user failed
units 0, broken user links 0, logs contain no warnings/errors; wl-copy/wl-paste remain.
The final cache-only deletion cannot remove any MAGI source/dependency. No new
clipboard sample was inserted by the agent: the operator's previously passed live
capture test remains recorded, and this pass verifies backend/helper health.
No shell restart/fresh-login test was performed.

Final `git diff --check` and exact path reconciliation pass. Prior tracked retirement
diff remains byte-for-byte unchanged; this hygiene extension edits only this
already-allowlisted untracked checkpoint and removes the untracked junk file.
No new dangling repository or deployed dotfile symlinks. Hypridle/Hyprlock hashes
and original cliphist database inode/size/nanosecond mtime/ctime remain unchanged.
No staged changes, commit or push. Stop for operator review.
The exact **23-path retirement Git allowlist remains unchanged**: this appendix
modifies its existing checkpoint only. The now-deleted stray file was untracked;
remaining unrelated dirt is exactly Hypridle and Hyprlock, both untouched.


## Final narrowly scoped retirement cleanup — 2026-10-04

Operator explicitly approved HyprPanel, Matugen and awww retirement, and removal
of genuinely unused dependencies after rechecking consumers. This section
supersedes the preceding appendix's retained-candidate status for these packages
and libqalculate. AGS is explicitly protected from removal in this final pass.
Sources inspected locally on 2026-10-04: installed pacman database, `pactree -r`,
pacman log, current active dotfiles/MAGI source and live process/service state.
The repository baseline remains `a5cce6b` plus the accepted retirement work.

### Final dependency and usage checks

| Exact installed package | Version | Install reason | Verified current use / removal classification |
| --- | --- | --- | --- |
| atkmm | 2.28.5-2 | Dependency | Still in pacman -Qdt; no reverse/optional dependent, script/service or observable loaded-library use; safe to remove |
| fmt | 12.2.0-1 | Dependency | Still in pacman -Qdt; no reverse/optional dependent or loaded-library use. Neovim's local fmt function is a name collision, not a package caller; safe to remove |
| libgee | 0.20.8-1 | Dependency | Still in pacman -Qdt; no reverse/optional dependent or current user-level use; safe to remove |
| pangomm | 2.46.5-1 | Dependency | Still in pacman -Qdt; no reverse/optional dependent or current user-level use; safe to remove |
| pps-tools | 1.0.3-2 | Dependency | Still in pacman -Qdt; former gpsd support, no current script/service use; safe to remove |
| hyprpanel-bin | 0.3.1-1 | Explicit | No process, startup, service/autostart or active repository/script reference; operator-approved retirement |
| matugen-bin | 4.2.0-1 | Explicit | No process, template/caller/startup or active repository reference; operator-approved retirement |
| matugen-bin-debug | 4.2.0-1 | Dependency | Split debug companion of the approved Matugen removal; no dependent package; retire with parent |
| awww | 0.12.1-1 | Explicit | No process/startup/caller; current wallpaper uses protected Hyprpaper; operator-approved retirement |
| libqalculate | 5.12.0-1 | Dependency | No required/optional dependent, current calculator/launcher/shell/MAGI consumer or observable loaded-library use; residual from old rice/Noctalia; safe to remove while preserving state |

For each package, `pacman -Qi` reports **Required By=None, Optional For=None**.
All ten `pactree -r` outputs contain only the queried package itself.
`pacman -Dk` reports **No database errors have been found**. The explicit
`pacman -R --print --print-format '%n %v'` target preview contains exactly these
ten packages. The preview is not a replacement for normal transaction-time
pacman dependency protection: the real operation uses plain `-R`, and must stop
if pacman reports a remaining installed dependent.

Current MAGI/Hyprland/local script/config/service searches find no package caller;
MAGI MPRIS stays on Quickshell's native API. A bounded readable process-map scan
finds none of the candidate libraries loaded. These findings do not purport to
inspect every inaccessible process or undocumented manual command.

The approved explicit transaction is:

```sh
sudo pacman -R atkmm fmt libgee pangomm pps-tools hyprpanel-bin matugen-bin matugen-bin-debug awww libqalculate
```

Operator confirmed completion; pacman log independently records exactly these ten
removals at **2026-10-04 08:26:35 BST**. No `-Rns`, `-Rdd`, recursive expansion
or other dependency-bypass operation is used.

AGS: **aylurs-gtk-shell-git 3.1.2.r0.gbbee2f1-2**, explicitly installed, no process
or current startup/repository integration found. Retain AGS and its installed
Astal/GJS/npm dependencies; no approved package requires removing it.

A final directory check finds one HyprPanel-only config,
`~/.config/hyprpanel/config.json` (3716 bytes), containing static panel/audio/D-Bus
preferences and no history/plugin files. It is safe to retire with its package.
No dedicated Matugen/awww config/cache/state directory was found in the inspected
XDG roots. Package-manager source/build caches remain outside this deletion.
Qalculate exchange-rate files and empty history, and Noctalia notification/settings/
plugin state remain preserved regardless of package removal.

### Final result

Operator-authenticated transaction removed all ten exact packages listed above,
with normal pacman dependency protection and no further package removal.
`~/.config/hyprpanel/config.json` and its now-empty directory were removed after
verifying the sole file's saved hash and absence of the package. No ambiguous data
or package-manager build cache was deleted. No other dedicated approved-tool
config/cache was found.

AGS remains installed at **3.1.2.r0.gbbee2f1-2** and inactive, with its dependencies
retained. Qalculate and Noctalia state files retain their original size, inode and
nanosecond mtime; preserved cliphist database inode/size/mtime/ctime also match.
Hyprlock, Hypridle, Hyprpaper, Quickshell, wl-clipboard and Stow remain protected.

`pacman -Qdtq` now reports **16** orphans. The two newly created ones are
**cairomm** and **glibmm**; both remain installed. No recursive follow-up purge.

Post-removal bounded validation passed:

- MAGI PID 143717 remains running with one 1920×1080 main layer and exact 48px
  reservation; compositor reports `[0,48,0,0]`.
- Control Centre opens interactive in phase 3, then closes cleanly.
- Clipboard toggles as its 540×660 floating desktop window; backend ready and
  monitoring true, error empty. No clipboard payload was read/replaced by agent.
- Notification D-Bus ownership remains MAGI PID 143717; harmless test notification
  (uint32 35,) increases history and produces a toast.
- Hyprland config errors empty; failed user units 0; broken user links 0;
  production warnings/errors 0. wl-copy/wl-paste remain executable.
- No new dangling repository/deployed dotfile symlinks; `git diff --check` passes.
- Prior tracked retirement diff unchanged; only this already-allowlisted checkpoint
  was extended. Exact **23-path Git allowlist remains unchanged**, alongside the
  two unrelated untracked Hypridle/Hyprlock files whose hashes still match.

No staged changes, restart, commit or push. Stop at the validated retirement
checkpoint for operator review. Fresh-login validation remains unclaimed.



## Final tiny cleanup / AGS-only audit — 2026-10-04

Scope limited to cairomm, glibmm and AGS; accepted retirement work preserved.
Inspected local pacman metadata and reverse dependency trees, active MAGI/T15g
source, Hyprland/startup/keybinds, user-systemd/XDG autostart and readable process
library maps on 2026-10-04. Source evidence: `file:///var/lib/pacman/local/`,
`file:///var/log/pacman.log`, current dotfiles at `a5cce6b` plus retirement changes,
and the existing Media/shell/startup components. No new API or feature changes.

| Candidate | Verified findings | Recommendation |
| --- | --- | --- |
| cairomm 1.14.6-1 | Dependency install; still in pacman -Qdt; Required By=None, Optional For=None; pactree -r returns only itself; no current code/script/service reference or observable library mapping | Safe to remove as residual C++ Cairo binding from retired GTKmm stack |
| glibmm 2.66.10-1 | Dependency install; still in pacman -Qdt; Required By=None, Optional For=None; pactree -r returns only itself; no current code/script/service reference or observable library mapping | Safe to remove as residual C++ GLib binding from retired GTKmm stack |
| aylurs-gtk-shell-git 3.1.2.r0.gbbee2f1-2 | Explicit install; Required By=None, Optional For=None; no AGS/GJS process, startup/keybind/service/autostart or active repository integration | Appears to be an unused legacy shell experiment superseded by current MAGI operation; retain pending separate explicit approval |

The two libraries are C++ wrappers, not the protected Cairo/GLib libraries used
by installed applications. Normal pacman dependency protection remains mandatory.
Explicit target preview contains exactly cairomm and glibmm. Operator requested
transaction:

```sh
sudo pacman -R cairomm glibmm
```

Operator confirmed completion; local pacman log records exactly glibmm and cairomm
removed at **2026-10-04 08:43:22 BST**. No recursive flags or dependency bypass.

AGS configuration/data inventory: no AGS/Aylur/Astal-specific user directory found
at the top level of `~/.config`, `~/.local/share`, `~/.local/state` or `~/.cache`.
`~/.cache/yay/aylurs-gtk-shell-git` is an AUR package build/source cache, not an
active shell configuration or notification/clipboard history store; retained.
No AGS files, package or dependencies were removed. These facts support an unused
legacy-experiment classification, not a claim that arbitrary external personal
projects cannot invoke AGS manually.

Post-removal `pacman -Qdtq` reports **15** orphans; the only newly created orphan
is **libsigc++**, retained without further investigation/removal as instructed.
AGS remains installed/inactive and its AUR cache remains untouched. Recommendation:
AGS can be considered for a separately approved retirement because no current
integration or user configuration was found; do not remove it automatically.

Existing bounded runtime validation passed again: Control Centre opens/interacts/
closes, Clipboard backend ready/monitoring with no error and floating-window toggles
work, harmless notification reaches MAGI history/toast with D-Bus ownership PID 143717,
one 1920×1080 main layer and exact 48px reservation, Hyprland config errors empty,
failed user units 0, broken user links 0, production warnings/errors 0 and executable
wl-copy/wl-paste retained. No clipboard payload read/replaced or restart performed.

Accepted tracked retirement diff remains unchanged. Preserved Qalculate/Noctalia
state metadata and cliphist history/protected-file checks pass. No new dangling
dotfile links; final `git diff --check` passes; exact 23-path allowlist unchanged with
only the unrelated untracked Hypridle/Hyprlock files outside it. No staged changes,
commit or push. Stop for operator review; no further cleanup undertaken.


## Final libsigc++ / AGS retirement — 2026-10-04

Operator approved this final two-package pass; no broader cleanup. Rechecked local
pacman metadata/reverse trees, active MAGI/Hyprland/scripts and startup/service/
autostart routes plus readable process maps. `libsigc++ 2.12.2-1` remains in
`pacman -Qdt`, installed as a dependency, with Required By=None and Optional For=None;
`pactree -r` returns only itself. No current reference or observable loaded-library
use found. Safe residual of the retired GTKmm/cairomm/glibmm stack.

`aylurs-gtk-shell-git 3.1.2.r0.gbbee2f1-2` has no required/optional dependent,
AGS/GJS process, active repository/keybind/startup/service/autostart route or user
AGS config/data in the checked XDG roots. This reconfirms obsolete shell-experiment
status, now approved for retirement. Exact normal target preview contains only:

```sh
sudo pacman -R libsigc++ aylurs-gtk-shell-git
```

No recursive flags or dependency bypass. Operator confirmed completion; local pacman
log records removal of exactly AGS and libsigc++ at **2026-10-04 09:14:13 BST**.

AGS-specific cache `~/.cache/yay/aylurs-gtk-shell-git` contains 81 files,
13191067 logical bytes: clean tracked PKGBUILD/.SRCINFO/LICENSE metadata,
two package archives and the bare `ags` source clone with official origin
`https://github.com/Aylur/ags.git`. Parent git status has only those expected
untracked build/source entries; source is a bare repository, not a modified worktree.
No symlinks/user config/personal data found. Only this cache is approved for deletion
after package removal; other yay caches remain untouched.

Confirmed successful retirement of both packages with normal pacman protection.
Deleted only the AGS-specific AUR cache after rechecking its complete 81-file
size/mtime manifest and confirming no symlinks or unexpected files. Other yay
caches and all user histories remain untouched.

Post-removal `pacman -Qdtq` reports **19** orphans. Newly orphaned packages are
reported only; all remain installed:

| New orphan | Classification | Action |
| --- | --- | --- |
| libastal-git | Identifiable AGS desktop-shell library in this setup | Retain; no recursive cleanup |
| libastal-4-git | Identifiable AGS GTK4 desktop-shell library in this setup | Retain; no recursive cleanup |
| gjs | General GNOME JavaScript runtime; independent use uncertain | Retain |
| gobject-introspection | General GObject development/introspection tooling; independent use uncertain | Retain; do not conflate this with MAGI's required PyGObject runtime |
| blueprint-compiler | General GTK4 UI compiler, formerly used/optional in the retired shell stack; independent use uncertain | Retain |

Existing bounded validation passes again after package/cache removal: Control
Centre phase 3/interactive open and clean close; Clipboard backend ready/monitoring
and floating-window toggle with empty error; harmless notification reaches MAGI
history/toast, D-Bus owner PID 143717; exactly one 1920×1080 main layer and 48px
reservation `[0,48,0,0]`; Hyprland config errors empty; failed user units 0; broken
user links 0; production warnings/errors 0; wl-copy/wl-paste executable. No new
clipboard payload inserted by agent, no restart/fresh-login validation claimed.

Final reconciliation passes: accepted tracked retirement diff unchanged; exact
23-path Git allowlist unchanged plus only unrelated untracked Hypridle/Hyprlock;
no new dangling repository/deployed dotfile links; protected-file hashes and
preserved Qalculate/Noctalia/cliphist metadata unchanged; `git diff --check` clean.
No staged changes, commit or push. Stop for operator review without another
cleanup round.


## Final AGS dependency-tail pass — 2026-10-04

Scope restricted to the five operator-named packages. Verified locally using
`pacman -Qdt/-Qi`, required/optional reverse metadata, `pactree -r`, current
MAGI/Hyprland/dotfiles/local scripts/startup/services/autostart searches, targeted
saved-history token counts and readable process executable/library maps.
No current direct user/application use found. Sources: local pacman database/log,
current dotfiles `a5cce6b` plus accepted retirement changes, and MAGI's
`services/clipboard_backend.py::image_preview`. Inspected 2026-10-04.

| Exact package/version | Dependency evidence and provenance | Classification |
| --- | --- | --- |
| libastal-git r853.5baeb66-1 | Dependency install; still orphaned; no required/optional reverse dependent; first installed 2025-10-16 during AGS setup | Unused AGS shell library; safe to remove |
| libastal-4-git r853.5baeb66-1 | Same reverse/use checks; first installed 2025-10-16 during AGS setup | Unused AGS GTK4 shell library; safe to remove |
| gjs 2:1.88.1-1 | Dependency install; orphaned with no required/optional dependent, executable process, repository/startup caller or targeted saved-history use; installed 2025-10-16 alongside AGS dependencies | No current JavaScript shell/tool consumer; safe to remove |
| gobject-introspection 1.86.0-2 | Dependency install; orphaned with no required/optional dependent; no scanner/compiler caller or executable process; installed 2025-10-16 alongside AGS dependencies | Unused development scanners/tools, distinct from retained runtime; safe to remove |
| blueprint-compiler 0.22.2-1 | Dependency install; orphaned with no required/optional dependent; no current UI source/script caller or compiler process; initially installed 2025-10-19 with retired SwayNC tooling, formerly optional for AGS | No current build/user role found; safe to remove |

All five reverse trees contain only the package itself. No observable Astal/GJS
library mapping found. The initial broad command-substring process search matched
the audit shell itself; an exact executable/script-name check confirms zero actual
candidate processes. No unrelated shell history was printed. General-purpose tool
classification follows these direct-use checks, not orphan status alone.

`pacman -Dk` reports no database errors and the normal `-R --print` target preview
contains exactly these five. Approved explicit transaction:

```sh
sudo pacman -R libastal-git libastal-4-git gjs gobject-introspection blueprint-compiler
```

Operator confirmed completion; pacman log independently records removal of exactly
these five packages at **2026-10-04 09:26:26 BST**. No recursive/dependency-bypass flags.

MAGI image previews require PyGObject/GdkPixbuf. `python-gobject 3.56.3-1` depends
on **gobject-introspection-runtime**, not the removed development scanners package.
The retained runtime package remains required by python-gobject. A synthetic
one-pixel GdkPixbuf creation passes before removal, without clipboard access;
repeat this runtime check after removal. No feature/architecture change.

Completed the exact five-package transaction. No further package or config/cache
removal occurred in this pass. Final `pacman -Qdtq` reports **18** remaining orphans:

```text
cmake
csakura-debug
electron39
ffmpeg4.4
go
gtk-layer-shell
hyprland-protocols-git
hyprwayland-scanner
js140
lib32-libcap
libastal-io-git
libliftoff
meson
opencl-headers
python-mako
python-pkg_resources
svt-hevc
yay-debug
```

Four are newly orphaned by this transaction; all remain installed:

| New orphan | Relationship to retired stack | Action |
| --- | --- | --- |
| libastal-io-git | Direct remaining Astal I/O library fragment | Retain within this five-package boundary; no recursive removal |
| gtk-layer-shell | Shared GTK3 layer-shell library formerly required by Astal | Retain; no new usage audit/removal |
| js140 | General JavaScript engine formerly required by GJS | Retain; no new usage audit/removal |
| python-mako | General Python templating dependency formerly required by introspection tools | Retain; no new usage audit/removal |

MAGI/runtime validation passes after removal:

- MAGI PID 143717 running; Control Centre opens interactive/phase 3 and closes.
- Clipboard backend PID 166067 and native capture helper PID 166080 running;
  ready/monitoring true, error empty; floating window toggle passes.
- Harmless notification enters MAGI history/toast; notification D-Bus owner 143717.
- One 1920×1080 main layer, exact 48px IPC/compositor reservation `[0,48,0,0]`.
- Hyprland config errors empty; failed user units 0; broken user-unit links 0;
  production Quickshell warnings/errors 0; wl-copy/wl-paste retained/executable.
- Post-removal synthetic GdkPixbuf test passes with retained python-gobject 3.56.3-1,
  gobject-introspection-runtime 1.86.0-2, libgirepository 1.86.0-2 and gdk-pixbuf2 2.44.7-1.
  Development-tool retirement does not remove MAGI image-preview runtime.
- No clipboard payload read/replaced by agent and no shell restart performed.

Final reconciliation confirms exact **23-path intended Git allowlist unchanged**;
only the unrelated untracked Hypridle/Hyprlock local files remain outside it, with
unchanged hashes. Accepted tracked retirement diff remains byte-for-byte unchanged.
Preserved Noctalia/Qalculate state file metadata and cliphist database metadata match
their baselines. No new dangling repository/deployed dotfile links. Final
`git diff --check` passes; nothing staged, committed or pushed.

This is the final package-cleanup pass. Stop for operator review; do not recurse
into another orphan-cleanup round.


## Final classified residuals and operator transaction — 2026-10-04

Operator cancelled the blanket 18-package orphan removal at confirmation. Pacman
log records that attempted command but **no ALPM transaction** for it. The screenshot
and live log agree: the only subsequent successful transaction was normal
`pacman -R libastal-io-git js140 gtk-layer-shell`, completed **09:33:50 BST**.
Removed exactly libastal-io-git r840.71b008e-1, js140 140.17.0-1 and
GTK3 gtk-layer-shell 0.10.1-1. No broad orphan removal occurred.

Final three-group classification from local metadata/history/current references:

| Group | Packages | Final action |
| --- | --- | --- |
| Remove now — clear retired runtime leftovers | libastal-io-git, js140, gtk-layer-shell | Operator removed exactly these three using normal dependency protection |
| Keep explicitly — useful development/build tooling | cmake, go, meson, hyprwayland-scanner, hyprland-protocols-git, opencl-headers, python-mako | All confirmed installed; no install-reason changes made. Explicit retention is the recommendation, not a performed pacman -D operation |
| Needs operator decision | csakura-debug, yay-debug, electron39, ffmpeg4.4, svt-hevc, lib32-libcap, libliftoff, python-pkg_resources | All retained; no further research/removal |

The exact current orphan list is the **15 retained packages** in groups 2/3 above.
No new orphan was created by this three-package transaction. Orphan status alone
must not trigger removal of the retained build/system/application tooling.

Post-transaction established MAGI validation passes again: production running,
Control Centre interactive open/close, Clipboard backend/helper alive and ready/
monitoring with no error, notification ownership/history/toast, one 1920×1080 main
layer, exact 48px reservation, no Hyprland config errors, failed user units or
production warnings/errors; wl-copy/wl-paste executable. No shell restart or agent
clipboard payload replacement. No further package/cache removal.

Final Git/data reconciliation passes: exact 23-path allowlist unchanged; only the
unrelated untracked Hypridle/Hyprlock local files outside it, hashes unchanged;
accepted tracked retirement diff unchanged; preserved Noctalia/Qalculate state and
cliphist database metadata unchanged; no dangling repository/deployed dotfile links;
`git diff --check` clean; nothing staged/committed/pushed. Stop for operator review.


## Repository presentation / documentation pass — 2026-10-04

Documentation-only extension of the accepted retirement; no package, runtime,
QML, Settings or feature changes. Root README is a concise platform/machine overview
centred on Arch Linux + Hyprland + MAGI, with Mac mini and Windows machine links,
actual case-sensitive layout, Stow workflow and basic setup/restoration guidance.
Detailed MAGI content now lives in the new `linux/magi/README.md` GitHub landing page.

The MAGI README covers current status and verified versions, implemented features,
Clipboard privacy/session persistence, first-party notifications, configurable
Settings/Control Centre ordering and columns, dependencies/deployment/development,
relative documentation links, the short future roadmap and structured screenshot
slots. No representative tracked bitmap screenshots were found; none fabricated
or copied from temporary operator screenshots. AGENTS.md remains agent instructions
and is unchanged.

Current docs index now links to the project README. Current architecture retirement
wording includes the subsequent AGS/HyprPanel/Matugen/awww retirements and retained
Hyprpaper. Dated research/checkpoints remain historical; no old source evidence was
rewritten. Windows is actually `Windows/`, not `windows/`; root links/tree corrected.

Source checks: actual current Settings pages/column controls, Clipboard and media
services, notification ShellRoot ownership, and T15g/platform configuration were
inspected locally. No new Quickshell API implementation/research was necessary.
Plain `stow magi` simulation proposes deploying ancillary docs/tests/agent files;
the documented explicit-ignore command simulation makes no such links. This is a
command-documentation fix only: no Stow/live filesystem deployment was changed.

### Presentation-pass intended Git allowlist (24 paths; superseded below)

This supersedes the earlier 23-path checkpoint lists by adding `linux/magi/README.md`.
All paths are relative to the repository root:

```text
README.md
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/notifications-toasts.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/README.md
linux/magi/docs/research/legacy-shell-retirement-checkpoint.md
linux/t15g/hypr/.config/hypr/hyprland.lua
linux/t15g/swaync/.config/swaync/config.json
linux/t15g/swaync/.config/swaync/scripts/swaync-greeting.sh
linux/t15g/swaync/.config/swaync/scripts/toggle-bluetooth.sh
linux/t15g/swaync/.config/swaync/scripts/toggle-wifi.sh
linux/t15g/swaync/.config/swaync/style.css
linux/t15g/systemd/.config/systemd/user/swaync-greeting.service
linux/t15g/systemd/.config/systemd/user/swaync-greeting.timer
linux/t15g/systemd/.config/systemd/user/swaync.service
linux/t15g/systemd/.stow-local-ignore
linux/t15g/systemd/mask-targets/swaync.service
linux/t15g/waybar/.config/waybar/config.jsonc
linux/t15g/waybar/.config/waybar/scripts/powermenu.sh
linux/t15g/waybar/.config/waybar/scripts/swaync-bell.sh
linux/t15g/waybar/.config/waybar/style.css
```

Only unrelated local files excluded:

```text
linux/t15g/hypr/.config/hypr/hypridle.conf
linux/t15g/hypr/.config/hypr/hyprlock.conf
```

Final checks passed: Markdown fences balanced and **103 relative local links/anchors
across 9 documentation files** resolve, including both new/refreshed landing pages.
Filtered Stow simulation proposes no ancillary project links. `git diff --check`
passes. Exact reconciliation is **24 intended paths plus only the two excluded
Hypridle/Hyprlock files**. AGENTS.md and MAGI QML/configuration are unchanged;
preserved data and unrelated-file hashes remain unchanged. No runtime restart or
package operation was performed during this presentation pass.
Nothing staged, committed or pushed; stop for operator review.


## Final pre-commit Stow packaging fix — 2026-10-04

Added package-local `linux/magi/.stow-local-ignore`; the package now supports
ordinary `stow --target="$HOME" magi` from `~/dotfiles/linux` without caller-side
ignore flags. Runtime `.config/quickshell/magi` remains deployable. The root-anchored
rules exclude only inspected project material: README.md, AGENTS.md, docs, tests,
experiments, and repository/local agent-tool metadata (.git/.agents/.aws/.codex).
They do not filter similarly named resources inside runtime configuration.

Verified native semantics against installed GNU Stow **2.4.1**, inspecting
`file:///usr/share/perl5/vendor_perl/Stow.pm` on 2026-10-04:
`ignore`, `get_ignore_regexps_from_fh` and `compile_ignore_regexps` demonstrate
package-root path matching and automatic exclusion of `.stow-local-ignore` itself.
The local list replaces Stow defaults, so inspected top-level metadata exclusions
are explicit. No runtime item is included in these patterns.

Root and MAGI README deployment instructions now use ordinary commands; the prior
filtered workaround is superseded. No actual Stow deployment, live link change,
package operation, QML/Settings/feature change or shell restart occurred.

Validation passed:

1. `stow --simulate --verbose --dir ~/dotfiles/linux --target ~ magi` succeeds and
   proposes no changes against the already-correct live deployment.
2. The same ordinary simulation against a temporary target with `.config/quickshell`
   directories proposes exactly one runtime link: `.config/quickshell/magi`.
   README/AGENTS/docs/tests/experiments/tool metadata/ignore file are not proposed.
3. Existing `~/.config/quickshell/magi` symlink retains its literal target and
   resolves to the repository runtime directory; shell.qml remains accessible.
4. Markdown/local-link checks pass: 103 links/anchors across 9 documentation files.
   `git diff --check` passes; no staged changes.

### Final exact intended Git allowlist (25 paths)

This supersedes earlier 23/24-path snapshots, adding the MAGI project README and
package-local ignore file. Paths relative to the repository root:

```text
README.md
linux/magi/.stow-local-ignore
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/notifications-toasts.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/README.md
linux/magi/docs/research/legacy-shell-retirement-checkpoint.md
linux/t15g/hypr/.config/hypr/hyprland.lua
linux/t15g/swaync/.config/swaync/config.json
linux/t15g/swaync/.config/swaync/scripts/swaync-greeting.sh
linux/t15g/swaync/.config/swaync/scripts/toggle-bluetooth.sh
linux/t15g/swaync/.config/swaync/scripts/toggle-wifi.sh
linux/t15g/swaync/.config/swaync/style.css
linux/t15g/systemd/.config/systemd/user/swaync-greeting.service
linux/t15g/systemd/.config/systemd/user/swaync-greeting.timer
linux/t15g/systemd/.config/systemd/user/swaync.service
linux/t15g/systemd/.stow-local-ignore
linux/t15g/systemd/mask-targets/swaync.service
linux/t15g/waybar/.config/waybar/config.jsonc
linux/t15g/waybar/.config/waybar/scripts/powermenu.sh
linux/t15g/waybar/.config/waybar/scripts/swaync-bell.sh
linux/t15g/waybar/.config/waybar/style.css
```

Exact working-tree reconciliation passed: these 25 paths plus only the unrelated
untracked Hypridle/Hyprlock files below, whose hashes remain unchanged:

```text
linux/t15g/hypr/.config/hypr/hypridle.conf
linux/t15g/hypr/.config/hypr/hyprlock.conf
```

Preserved Qalculate/Noctalia state and cliphist history remain unchanged. AGENTS.md
and MAGI QML/configuration are unchanged. Nothing staged, committed or pushed.
Final pre-commit change complete; stop for operator review.
