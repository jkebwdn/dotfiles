# Terminal visuals integration

Audited 2026-10-29 against production `7e050c9`. Settings schema remains 22.

## Installed application audit and decision

| Application | Verified support | Integration decision |
| --- | --- | --- |
| CAVA 1.0.0, `/usr/bin/cava` | `[color]` theme files, six-stop gradients, default terminal background, `-p` custom config. Missing selected theme is fatal. `live-config` watches the main config, not its theme file. `c`/SIGUSR2 reload colours; no automatic safe application API. | Guarded Bash launch hook composes existing non-colour config with a generated colour payload into an anonymous Linux memfd. Next launch, no signals/restart. |
| ascii-splash 0.6.1, `splash` | Five fixed themes; CLI `--theme`; no custom palette or external config reload. Conf stores `.splashrc.json` under `$XDG_CONFIG_HOME/ascii-splash-nodejs`. | Guarded Bash launch hook adds a supported built-in theme argument. Explicit CLI themes and shared presets win. Next launch, approximate mapping only. |

Sources: [CAVA 1.0.0 config.c](https://github.com/karlstav/cava/blob/1.0.0/config.c)
(`load_config`, `get_themeFile`, `load_colors`) and
[cava.c](https://github.com/karlstav/cava/blob/1.0.0/cava.c) (`config_changed`, reload loop);
installed `/usr/share/doc/cava/README.md`.
[ascii-splash upstream](https://github.com/reowens/ascii-splash), installed 0.6.1
`dist/config/{themes,ConfigLoader,validateConfig}.js`, `dist/main.js`, and
`dist/patterns/{LavaLamp,Plasma,Smoke,Aquarium}Pattern.js` were authoritative for this
installation. Both installed packages declare MIT licensing (CAVA’s installed
`/usr/share/licenses/cava/LICENSE`; ascii-splash package metadata). No upstream
implementation is copied.
Future versions need compatibility review, not assumed custom-palette support.

The current CAVA config has only section headers and commented/default options.
The splash config contains animation, pattern, quality and FPS choices. Both files
remain byte-for-byte unchanged. No input method, source, audio routing, FPS, smoothing,
pattern or quality value is written by MAGI.

A static `theme = 'magi'` was rejected: it would make fresh/disabled CAVA startup fail
without its generated file. A watcher/signal process was rejected: it adds another
runtime lifecycle for a terminal visualizer. The launch snapshot is intentionally
stable for that process, including CAVA's manual colour reload. Config edits and new
MAGI palettes apply at the next launch. There is no claim of live activation.

## Colour and ownership contract

CAVA bottom-to-top: `teal → accent → green → warning → peach → red`, six validated
semantic hex values. Foreground uses accent; background remains `default`. This is a
MAGI semantic gradient, not a literal upstream application-theme port. No theme IDs
or pattern IDs are special-cased.

Splash uses accent hue distance to representative ocean, matrix, starlight and fire
hues; saturation below 0.12 selects monochrome. Mapping is deterministic and has no
MAGI theme-name conditions. The five built-ins cannot reproduce all 26 palettes.
Lavalamp, plasma and smoke consume the theme API; aquarium owns its scene colours
and does not become an exact MAGI palette through this integration.

The tracked `.bashrc` sources `services/terminal_visuals.sh` if present. Its canonical
functions invoke `terminal_visuals.py`; `command cava` / `command splash` bypass them.
Existing shells need to source that hook or open a new shell. CAVA explicit arguments
retain native behavior; splash explicit theme/share/play/watch commands are untouched.
No app is installed automatically. Existing unthemed launches work without generated
state, and malformed payloads fall back locally with a short warning.

Theme Orchestrator owns `cava/current/colors.ini` and `ascii-splash/current/theme.json`
under its existing XDG data store. All renders/validators still run before publication.
Absent optional executables are skipped without blocking available targets; published
state is retained for recovery. Reinstallation resumes on the next apply. Enrollment
requires the exact canonical source hook; disable preserves it and detaches the current
pointer, making future launches use the user's own colours. Running processes remain
unchanged. The anonymous CAVA config disappears when its process exits.

## Validation / acceptance

`tests/theme-orchestrator/visuals.py` covers all 26 palettes, native CAVA parsing,
installed splash theme validation, behavior preservation, absent apps/config/payloads,
foreign bootstrap rejection, malformed payload fallback, publication round-trips and
disable/re-enable. Existing all-adapter fixtures include the new canonical hook.

Full canonical regression: **88 PASS, 0 FAIL, 0 UNKNOWN, 4 documented environment
limits** (private D-Bus Bluetooth/Notifications, clipboard PNG transport and native
lock SOCK_SEQPACKET). Diff/links/Bash syntax checks pass.

Native review accepted on 2026-10-29 after relaunching between theme changes:
CAVA visibly changes, and ascii-splash selects the nearest built-in (including Ocean),
whose own colours remain intact. The operator also observed apparent live CAVA colour
changes. The integration retains its conservative next-launch contract: its memfd
snapshot is fixed, while Ghostty's background/default terminal colours can update
live. No live gradient reload or signalling is claimed. An isolated real-CAVA PTY
check produced 24 distinct RGB foreground escapes through the generated snapshot.

The native check passed with the original Catppuccin Mocha restored, byte-identical
Settings and application configs, an empty index, no new theme/Hyprland errors, and
only the nine intended production-source changes. No theme operation dirtied other
tracked source. Both targets published the restored palette with next-launch status.
