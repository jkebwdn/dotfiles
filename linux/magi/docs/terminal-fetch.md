# Animated terminal fetch

`magi-fetch` is a terminal-native NERV-inspired wireframe composition.
The optional Bash hook presents it once per new interactive Ghostty terminal,
rotating until the first key. Plain `fastfetch` also animates until the first key; commands with
arguments such as `fastfetch --version` still invoke the original binary.
Settings schema remains 22. No supplied raster artwork is copied into the repo.

```sh
magi-fetch             # roughly two seconds at 20 FPS, then a static final frame
magi-fetch --until-key # rotate until first key, preserving it for the shell
magi-fetch --static    # one deterministic frame
magi-fetch --loop      # continuous rotation; Ctrl+C exits
magi-fetch --no-color  # monochrome
magi-fetch --ascii     # ASCII logo instead of Unicode braille/block glyphs
```

The static entry point is `linux/magi/.local/bin/magi-fetch`; it loads
`$XDG_CONFIG_HOME/quickshell/magi/services/magi_fetch.py`. Both are part of the
MAGI Stow package. Existing `$HOME/.local/bin` PATH setup exposes the command after
installation. Native previews can run the Python source directly before installation.
The operator approved Ghostty startup on 2026-10-29. The static hook runs before
ble.sh attaches, skips SSH/tmux/screen/non-TTY/dumb terminals, and uses an inherited
TTY marker to skip nested shells on the same terminal. No background renderer draws
over a live prompt. Missing commands safely skip startup.

## Rendering and data ownership

Twelve longitude curves and seven latitude rings are rotated geometrically about
the vertical axis, tilted slightly, and orthographically projected into a 35×15-cell
region. A 2×4 subcell braille raster gives smoother curves than the ASCII alternative.
Front lines use `teal`; rear lines use `muted`. The fixed, independently masked NERV
block wordmark uses `accent`, and MAGI SYSTEM uses `text`. No per-theme colour tables,
image assets, animation-frame downloads, random flicker or dependencies are required.

The renderer reads the selected theme from operator-local Settings and reuses MAGI's
canonical palette resolver. An identical published Ghostty palette snapshot is usable;
missing/stale generated state falls back to that resolver, not a separate palette.
Missing/malformed Settings use the registry default. Reads happen once per invocation;
this is not a live theme subscriber. Nothing writes Settings, generation pointers,
application configuration, journals, caches or tracked files.

Fastfetch runs once with its logo disabled. Its configured module list, formats and
ANSI key colours remain in charge. Cursor-based key alignment is resolved into spaces;
only SGR colour sequences are retained. The shorter of the artwork and information blocks is vertically centred against
the taller block. The animated redraw touches the left region only. The existing information is Host, CPU, GPU, Memory, Storage, OS, WM, Terminal,
Shell, Editor and colour dots. No module list is duplicated in the renderer.

Inspected 2026-10-29: installed Fastfetch 2.70.0 `--help logo`, `--help pipe`,
[logo options](https://github.com/fastfetch-cli/fastfetch/wiki/Logo-options) and
[2.70.0 shell detection](https://github.com/fastfetch-cli/fastfetch/blob/2.70.0/src/detection/terminalshell/terminalshell_linux.c).
The child-only `FFTS_IGNORE_PARENT=1` skips the Python wrapper during Fastfetch shell
detection. It preserves the actual shell/version rather than displaying the helper
name. No Fastfetch configuration file is changed.

## Terminal safety and fallbacks

Animation requires TTY input/output, a non-dumb terminal and room for the entire
composition. PTY dimensions take precedence over exported shell dimensions. There is no startup settling delay.
Narrow/short terminals show a compact static NERV heading above clipped
system information. Redirected output and `TERM=dumb` are static and escape-free.
`NO_COLOR` disables colours; non-truecolour terminals use their existing ANSI palette.
Fastfetch's own configured icons remain intact with `--ascii` when UTF-8 is available.

The renderer reserves normal scrollback rows, leaves system text stationary and ends
below the block. It never enters the alternate screen. Input echo
is temporarily suppressed during animation so typing cannot damage the reserved
region; input is never read or discarded. `--until-key` temporarily disables
canonical input buffering while retaining signal handling. The first available byte
ends animation; TCSANOW restores the original mode without flushing that byte.
Other animation modes stop on a queued complete line. The original terminal attributes are restored in
`finally`, together with colours and cursor visibility. Ctrl+C/termination/suspend
requests end cleanly. Resize stops further redraws and leaves normal terminal reflow
in charge; it does not clear the screen or erase previous shell output.

Animation uses one foreground Python process and one Fastfetch invocation, with no
per-frame subprocesses or filesystem reads. Measured geometry/frame generation was
about 7.0 ms CPU per frame on this host (roughly 0.3 CPU-seconds for a normal run).
Frame waits keep output below 20 FPS. This measurement excludes terminal rendering
and is not a guarantee for slower machines.

## Validation and acceptance

`tests/fetch/run.py` covers deterministic snapshots, frame bounds, fixed wordmark,
front/back roles, six representative palettes, safe control-sequence handling,
static/narrow/no-colour fallbacks, actual Fastfetch output and isolated PTY behavior.
PTY checks prove a single data fetch, left-region-only redraw, bounded duration,
SIGINT/SIGTERM/SIGQUIT/SIGHUP/suspend cleanup, resize exit, input preservation and
terminal-attribute restoration. Test runtime files and uncommitted preview captures remain under temporary roots.
Deterministic text snapshots are committed with the regression.

Full regression: 89 PASS, 0 FAIL, 4 environment limits. Revised geometry and
first-key behavior pass focused PTY coverage. Eleven focused tests cover stale shell dimensions; this regression fails against
the old sizing implementation. The initial tiling fallback was confirmed by the
operator to reflect insufficient space; the experimental settling delay was removed.
Native Ghostty review accepted the wider wordmark, centred information, startup,
first-key preservation and plain Fastfetch behavior on 2026-10-29. No startup delay
or automatic timeout remains for startup/plain `fastfetch`; manual `magi-fetch`
retains its bounded default. Fastfetch configuration and schema 22 are unchanged.

The four full-matrix limits were private D-Bus EPERM in Bluetooth and Notifications,
independent PNG decode/D-Bus EPERM in Clipboard, and independently confirmed
SOCK_SEQPACKET EPERM in the unchanged native lock transport tests. There were no
FAIL or UNKNOWN results. After the final refinements, all 11 fetch tests and the
application bootstrap suite passed; `git diff --check` passed. Protected Settings,
local artwork/configuration and symlink targets were verified before integration
and after native review.
