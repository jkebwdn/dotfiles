# Phase 12H — Theme / Application Activation & Polish

## Final native acceptance — 2026-10-24

**Operator explicitly accepted Phase 12H.** This final record supersedes the
historical pending/review notes retained below. Final inventory is **33 paths:
21 added, 12 modified, 0 deleted**. Settings schema remains **19**.

- Ghostty's existing owner `:1.40`, UID 1000, PID 2449, executable `/usr/bin/ghostty`
  was verified before activation. The parameterless `org.gtk.Actions.Activate`
  `reload-config` call uses the unique owner, verified action shape and
  `NO_AUTO_START`; no keystrokes, signals, focus changes or app restarts.
- Frappé → Nord → Rosé Pine Dawn → Frappé: operator confirmed both ordinary
  Ghostty windows updated automatically, preserving background transparency,
  compositor blur and opaque foreground. Generated output kept the semantic
  palette, 50% background opacity, opaque deliberate cells and 20px GTK blur CSS.
- Normal-owner/independent-process test passed: ordinary windows updated, while
  `--gtk-single-instance=false` retained its prior colours. Runtime correctly
  reported one covered process and one independent process requiring manual
  reload. Machine status stays **Reload requested**, never inferred visual success.
- Plain btop now loads MAGI without command flags. The original absolute generated
  path silently fell back to stock because it was outside btop's scanned theme
  directories. Corrected enrollment installs one owned link in `btop/themes` and
  selects that path. Only the theme selection changed; `theme_background = false`
  remains. Operator accepted the improved palette/readability. Existing btop must
  exit/relaunch after a theme change, exactly as **Applies next launch** states.
- Zen retained its original PID and was never restarted; its status is Restart
  required. Thunar was absent at preflight; no live file-operation test is claimed.
  Its next-process-launch/no-command policy passed fake-executor tests. GTK4 full
  palette support remains deferred. No Neovim/Yazi/btop session commands were sent.
- Starship remains naturally next-prompt in enrolled shells; Fastfetch remains
  next-invocation/terminal ANSI. No separate detailed native Fastfetch assertion
  is claimed. Hyprland border-colour activation reported Applied; no blur/opacity
  ownership was added. MAGI stayed reactive.
- The approved MAGI config reload retained shell instance/PID, settings, artifact
  generations and activation receipts; startup did not replay app actions. A
  subsequent native theme change again activated ordinary Ghostty successfully.
- Final Settings match the pre-integration snapshot: Catppuccin Frappé, shared
  background opacity 50%, blur on, global blur customization 12 (captured baseline
  8). No whole-client-opacity/pass-count command exists in the activation path.
- Safe explicit Retry remains viable after timeout/failure. Persistent receipts
  prevent automatic retry storms; fake tests prove explicit retry executes again
  and clears the failure. No live failure injection occurred.

Final regressions: **24 Phase 12H**, **15 Theme Orchestrator**, **26 Phase 12G
application**, **11 global-blur** tests passed, plus Phase 12G schema-18 operator
fixture migration/lifecycle/presentation; Settings persistence/presentation/
Appearance; Phase 12F; runtime visuals; production Phase 12H status/debounce test;
six btop palette fixtures and contrast checks; `git diff --check`.
Expected offscreen IPC/window-mask/unset-Hyprland warnings are recorded separately
from failures. Native Qt Wayland text-input warnings occurred during focus changes;
there was no new QML load failure. No tests were weakened.

All 14 protected entries, including settings.json and the Yazi flavour link, match
the fresh pre-integration snapshot. The btop enrollment repair is outside Git and
journaled by the existing owner. No runtime status, generated output, bytecode or
protected operator configuration belongs in the Phase 12H commit. Native diagnostic
processes are operator-closed normally; no termination was issued by MAGI/Codex.

No later roadmap phase is started.

---

## Approved implementation — isolated review candidate, 2026-10-24

The operator accepted next-process-launch GTK/Thunar semantics and **rejected a
cross-application store rewrite**. This section supersedes the historical audit
stop below. The audit evidence is retained, including the former proposal that was
not selected. Production baseline remains `d4f22babf3f87e03154a8ee98a1590763694d2b5`
(`HEAD...origin/main = 0 0`). Schema **19** is unchanged.

### Publication and activation contract

`theme_activation.ThemeActivationCoordinator` coordinates the existing Theme
Orchestrator under its process lock. Adapters still render files; Theme Orchestrator
remains the sole publisher, including Ghostty appearance and its blur stylesheet.
The store's format, ownership checks, per-target pointers and retention policy stay
intact. No live application/configuration was changed in this pass.

1. Resolve palette and application-appearance policy. Render and validate every
   selected, enrolled target before publishing any target. Validate JSON, TOML,
   Lua, generated btop grammar, GTK CSS with the corresponding GTK parser, bounded
   Zen alias CSS and Ghostty config with its isolated native validation command.
   A generation/validation/ownership error publishes nothing and activates nothing.
2. Publish through the existing atomic per-target generation pointer. Verify owned
   manifest/content readback. Commit publication metadata before runtime actions.
   This is **not globally filesystem-atomic** across application locations.
3. On publication failure, block activation. Attempt compensating restoration only
   where both the previous and newly switched artifacts are intact, MAGI-owned
   generations. Reuse the store's existing publish operation. Do not delete initial
   output or overwrite user-modified artifacts to manufacture rollback. Record
   `restored`, `unchanged`, `retained-or-conflicted` or `restore-failed` per attempted
   target; return `publication_error`. A journal failure also blocks activation.
4. Only after complete publication, dispatch safe runtime actions. Activation
   failure is local: preserve valid files, continue other targets and report
   `activation_error`, with individual outcomes. No desktop-wide rollback.

Explicit enrollment/removal retains its established reviewed, single-target hook
transaction. Application-appearance changes retain 12G's Ghostty/blur transaction;
Ghostty activation starts only after that transaction succeeds. Neither path adds
another writer. Global blur amount remains entirely outside theme activation.

### Adapter v2 and statuses

Each adapter retains `render()` and gains `validate()` plus a central immutable
capability: activation kind, automatic safety, human detail and readback boundary.
`theme_activation/capabilities.py` is the single activation vocabulary; QML consumes
status labels rather than deriving capabilities itself. The executor is injectable;
routine tests never contact a user's apps. No signal fallback or restart operation
is implemented.

| Target | Final activation classification | Boundary |
|---|---|---|
| MAGI | Live | Reactive internal palette, no shell reload |
| Hyprland | Applied after existing safe command | Border colours only; command acceptance, not visual proof |
| Ghostty | Safe reload / **Reload requested** | Verified existing GApplication owner; no loaded-generation readback |
| Zen | Restart required when running; next launch when absent | No restart; keep manual workspace-colour guidance and website-content boundary |
| GTK3 / Thunar | Applies next launch | Next **process**, not another window in an existing Thunar process; no refresh or file-operation interruption |
| GTK4 | Partial/deferred palette coverage | GTK3 adapter detail explicitly disclaims full GTK4 parity |
| Neovim | Applies next launch | No arbitrary socket/RPC discovery |
| Yazi / yatline | Applies next launch | No verified safe external session-theme reload adopted; existing flavour symlink retained |
| btop | Applies next launch | No external keyboard/reload automation; manual theme reselection remains possible |
| Starship | Live at next prompt | Shell must already use the enrolled `STARSHIP_CONFIG` path |
| Fastfetch | Applies next launch/invocation | ANSI follows terminal palette; no persistent process to refresh |

Qt/hyprtoolkit remain unsupported/deferred. An absent Ghostty is a healthy next-launch
result and is never started. Independent Ghostty processes not represented by the
verified application owner remain untouched and receive manual-reload guidance.
Zen process discovery accounts for this host's launcher executing
`/opt/zen-browser-bin/zen-bin`; it does not identify windows by title.

### Exact Ghostty invocation and compatibility

Installed Ghostty **1.3.1-2** registers parameterless `reload-config` in its GTK
application action map. Its app-level reload updates the terminals belonging to
that process. Single-instance windows share that process; independently started
processes are not assumed covered. Source:
[Ghostty v1.3.1 application.zig](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/apprt/gtk/class/application.zig),
`startupActionMap`, `Action.reloadConfig`, signal registration; inspected 2026-10-24.
SIGUSR2 is supported upstream but deliberately unused here; no broad process signal.

The executor uses Gio D-Bus calls, not keyboard injection or a CLI that might start
Ghostty:

- Discover an existing owner of `com.mitchellh.ghostty` through the bus daemon.
- Check its UID and PID against current-user `/proc/<pid>/exe` identities for the
  installed Ghostty ELF; recheck ownership immediately before dispatch.
- Address that **unique owner**, object `/com/mitchellh/ghostty`, interface
  `org.gtk.Actions`, method `Describe`, input `(s)` `reload-config`, reply
  `((bgav))`. Require an enabled, parameterless action.
- Invoke `Activate`, input `(sava{sv})` with `('reload-config', [], {})`, reply `()`.
  Every call uses `G_DBUS_CALL_FLAGS_NO_AUTO_START` and a 3000 ms timeout.
- Success means action dispatch accepted, hence **Reload requested**, not a claim
  that pixels or every independent process have been verified. No automatic retry
  loop; the existing explicit Retry action may retry safely.

The wire signature is verified against
[GLib GActionGroup exporter](https://github.com/GNOME/glib/blob/2.86.0/gio/gactiongroupexporter.c)
(`org.gtk.Actions`, `Describe`, `Activate`) and exercised by fake transport tests.
[NO_AUTO_START](https://docs.gtk.org/gio/flags.DBusCallFlags.html) prevents starting
an absent app. Installed GLib is **2.90.1-1**. Read-only inspection of its
`/usr/lib/libgio-2.0.so.0` embedded `org.gtk.Actions` introspection XML confirms
`Describe` output `(bgav)` and `Activate` input `s`, `av`, `a{sv}` on this exact
host binary. Its exact upstream source URL was not retrievable. Runtime `Describe`
remains an explicit compatibility gate, with failure reported rather than guessed dispatch. The public
GDBusActionGroup facility documents remote application actions; the direct wire
call is used here to retain unique-owner/no-auto-start checks. No upstream code was
copied. Native action delivery remains the controlled next gate, not a claimed test.

### Generations, coalescing and startup

A stable digest binds palette, appearance policy and candidate artifact digests.
Runtime status lives in `$XDG_STATE_HOME/magi/theme-activation/status.json`, outside
Settings/Git. Target outcomes carry generation identity; completion rejects an old
generation. Target/action/content receipts deduplicate repeated generations across
worker and MAGI restarts. Dispatch intent is saved **before** execution: an interrupted
pending action is not blindly replayed. Current files without receipts also do not
trigger startup reloads; report conservative next-launch status instead.

External theme changes settle for **450 ms**. The production QML test requests
A → B → C during that interval and observes exactly one apply request for C. An
already-started synchronous transaction is serialized by the existing lock, not
forcibly cancelled. A later queued generation runs after it; old-theme success and
failure responses cannot replace current UI state. Appearance uses its existing
450 ms debounce and now rejects stale policy/theme responses too. Identical output
(including blur-only participation changes) does not cause duplicate Ghostty reloads.

### btop semantic polish

Adapter version 2 retains the operator's `theme_background = false` setting and
never adds opaque terminal-background policy. It maps text/title to `text`, dim
text to `muted`, selection to `accent`/`onAccent`, dividers to `border`, CPU box to
`blue`, memory to `lavender`, network to `teal`. Temperature and CPU pressure progress
toward `warning`/`danger`; used memory does likewise. Download is consistently teal,
upload peach, so direction does not change colour meaning as rates increase. Process
intensity uses blue/lavender/focus. This uses canonical roles, not a new palette.

Six exact generated fixtures cover Mocha, Everforest Dark Hard, Rosé Pine, Nord,
Tokyo Night Moon and Rosé Pine Dawn. Tests require deterministic rendering, correct
semantic keys, distinct traffic directions and at least **4.5:1** contrast for normal
and selected text. Fixtures are generated configs, not claims of native btop capture.

### Settings and review captures

No new page or preference. **Appearance → Application themes** retains its compact
collapsed enrollment summary, with expanded next-launch/restart counts and human
per-target status. No process IDs, generation hashes or command strings are shown.
Errors remain local with the existing safe Retry disclosure. Zen's manual workspace
colour guidance remains intact. The Transparency page consumes Ghostty's coordinator
status while retaining its separate background/blur capability information.

Production-component offscreen captures in [the gallery](previews/phase12h/README.md)
cover normal Appearance, healthy, mixed, failure, compact and Rosé Pine Dawn. They
use a fake backend, not native application activation. Qt software rendering limits
are the same as existing Settings previews.

### Verification and next native gate

Offline checks: 23 coordinator/dispatcher/semantic tests; 15 Theme Orchestrator
lifecycle tests; full Phase 12G (26 application tests, 11 global-blur tests, schema,
lifecycle and presentation); Settings persistence/schema, presentation and appearance;
Phase 12F; runtime visuals; the new production-service debounce/presentation test.
All passed with the retained schema-18 operator fixture. Running the 12G migration
script without that fixture fails its expected-version assertion because the tracked
settings seed is schema 5; no test was weakened. Expected offscreen IPC/window-mask and unset-Hyprland warnings remain;
no new QML failure. `git diff --check` must be clean at review handoff.

No live action, config publication, integration, stage, commit or push occurred.
Protected-state comparison and the exact candidate inventory accompany the handoff.

Proposed controlled gate after review:

1. Snapshot existing generated output/status and retain schema-19 settings. Verify one
   shell and no pending save. Integrate only an explicit reviewed allowlist later.
2. With two windows of the normal Ghostty application, change theme and confirm both
   reload without focus/keyboard injection or session loss. Check background alpha,
   20px GTK blur request, opaque foreground and intentional coloured cells.
3. Test Ghostty absent without launching it; optionally use a separate independent
   instance to confirm honest partial/manual status rather than signalling it.
4. Verify Zen remains open with Restart required; manually restart only with operator
   approval. Verify existing Thunar/file operations remain untouched and a genuinely
   new process receives the generated theme. Do not force process exits.
5. Test A/B/C selection, same theme, MAGI restart, safe retry and theme/appearance
   composition. Confirm no global-blur or whole-client-opacity changes.
6. Inspect btop six-theme mapping, particularly Dawn; no opaque terminal background.

Native acceptance is pending; this implementation stops for operator review.

---

## Historical architecture audit stop — superseded by accepted decisions

Baseline verified: `d4f22babf3f87e03154a8ee98a1590763694d2b5`,
`magi: add application transparency and blur`; HEAD/origin/main **0 0**.
Isolated worktree: `/home/jkebwdn/magi-phase12h`. Settings schema remains **19**.
Main checkout and live generated application output were read only. No app reload,
signal, D-Bus activation action, keyboard injection, shell reload, staging or commit.

**Stop condition 75 is reached:** safe external refresh of the current GTK3/Thunar
integration has not been established. In addition, existing Theme Orchestrator
publication deliberately permits independent target failure. Implementing strict
all-target atomic publication requires an explicit store/transaction migration,
not merely adding reload hooks. Production code is unchanged at this review gate.

### Decisions requested

1. Accept **Applies next process launch / restart required for existing process**
   for GTK/Thunar. Do not promise that a new window in the same Thunar process reloads
   CSS. Do not terminate Thunar or toggle global theme names as a refresh trick.
2. Approve redesign of publication from independent target pointers to a shared
   transaction generation, with a controlled compatibility migration. Retain one
   writer and explicit ownership checks. All candidates must validate before any
   activation. A sequence of individual renames with rollback is not globally atomic
   to external readers; do not advertise it as such.

The requested full implementation, btop polish and UI changes are held for this
review rather than built on weaker transaction semantics.

## Installed versions and audit scope

Read-only `pacman -Q` reports the installed packages below. These are package
versions, not claims that every already-running process uses the latest binary.

| Target | Installed package version |
|---|---|
| Ghostty | 1.3.1-2 |
| Zen (`zen-browser-bin`) | 1.23.2b-1 |
| Thunar | 4.20.10-1 |
| GTK3 | 1:3.24.52-2 |
| GTK4 | 1:4.24.1-1 |
| Neovim | 0.12.6-1 |
| Yazi | 26.9.1-2 |
| btop | 1.4.7-1 |
| Starship | 1.27.0-1 |
| Fastfetch | 2.70.0-1 |
| Hyprland | 0.56.2-4 |
| Quickshell | 0.3.2-1 |

Installed Ghostty manual/help and gapplication help, Neovim remote documentation,
btop help/theme fixtures, current adapters and operator enrollment paths were read.
Yazi `--help` returned an ioctl error in this non-terminal environment; no reload
capability is inferred from it. No application was started to test activation.

## Existing generation and ownership audit

Sources: `services/theme_orchestrator/coordinator.py`, `storage.py`,
`adapters/{base,desktop,terminal,neovim,zen}.py` in the accepted baseline.

`Orchestrator.perform(apply)` loops enabled targets. Each `apply_target` independently
checks enrollment, renders, publishes, performs dynamic scheme updates and invokes
`adapter.activate`. Errors are recorded per target and the loop continues. The
existing `test_failure_isolation_and_missing` explicitly expects Neovim to publish
the new theme after Ghostty rendering fails, while Ghostty retains the old theme.
This is intentional tested behavior, not an accidental undocumented edge case.

`Store.publish` writes immutable per-target generations/manifests and atomically
renames each target's `current` symlink. It protects ownership and retains previous
output, but there is no shared transaction commit pointer or validation barrier
across all targets. Adapter.render is not a universal application syntax validator.
An activation coordinator alone cannot provide the requested all-target guarantee.

Observed roots: `$XDG_DATA_HOME/magi/theme-orchestrator/<target>/current` with
`current -> generations/<sha256>` for ghostty, gtk, zen, neovim, yazi, btop, starship,
and hyprland. MAGI is reactive; Fastfetch consumes terminal ANSI instead of a separate
RGB output. Generated file ownership remains entirely with Theme Orchestrator.
No parallel transparency/config publisher is proposed.

| Target | Current generated artifacts / integration | Conservative activation contract |
|---|---|---|
| MAGI | Internal semantic palette | Live; no external reload |
| Hyprland | colors.lua, border colours only | Existing eval path; readback improvement needed |
| Ghostty | colors.conf and managed background-blur.css | Safe reload candidate; exact source supports action/signal |
| GTK / Thunar | gtk.css definitions and theme/gtk-3.0/gtk.css; fixed MAGI theme | Next process launch; no proven safe external refresh |
| Zen | chrome.css imported by selected profile userChrome.css | Restart required; no automatic restart |
| Neovim | colors/magi.lua via runtimepath integration | Next launch; optional explicitly enrolled RPC later |
| Yazi / yatline | flavour + yatline.lua; existing magi.yazi symlink | Next launch pending further exact-version reload verification |
| btop | magi.theme selected by operator configuration | Next launch/manual theme selection pending reload audit |
| Starship | starship.toml through STARSHIP_CONFIG | Next prompt in shells already using generated path |
| Fastfetch | Existing ANSI output through terminal palette | Next invocation; visible palette depends on terminal reload |
| Qt / hyprtoolkit | Deferred | Unsupported/deferred |

## Ghostty reference activation finding

The installed CLI action list has no reload helper. Pinned 1.3.1 GTK source registers
`reload-config` as a parameterless application action and installs a SIGUSR2 handler.
Both reach app-level reload; the reload path propagates configuration across terminals
in that process. `gtk-single-instance=false` permits independent processes, while
single-instance mode groups windows. A primary application's D-Bus action alone
cannot be claimed to cover every independent process.

Preferred candidate: discover existing authenticated D-Bus owner, verify action,
invoke against that unique owner with no auto-start. Absent app means next launch.
A tightly verified process/SIGUSR2 fallback needs UID/executable/session identity,
PID reuse protection and confirmation the handler is installed; never signal a
starting process blindly. Delivery/action acceptance is not loaded-generation
readback. Status must distinguish **Reload requested** from verified **Reloaded**.
No hook was executed and multi-process native proof remains pending.

Evidence (inspected 2026-10-24): [Ghostty 1.3.1 application.zig](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/apprt/gtk/class/application.zig),
`startupActionMap`, `startupSignals`, `handleSigusr2`, `Action.reloadConfig`;
installed `/usr/share/ghostty/doc/ghostty.1.md` and `gapplication help action`.
Source was inspected, not copied. Ghostty's MIT license applies upstream.

Preserve background-opacity, background-opacity-cells=false, and the GTK 20px
blur-region request from 12G. Reload must never lower foreground opacity, kill
terminal sessions, steal focus or simulate Ctrl+Shift+,.

## GTK3, GTK4 and Thunar gate

GTK3's `settings_init_style` loads the user CSS provider once; theme-name/dark
preference notifications update the theme provider. Current MAGI uses the fixed
name MAGI plus a generated import; replacing files does not establish a remote
refresh contract. A new window in the same process is not equivalent to GTK init.
Changing theme names to force notifications would be a different global policy,
with flicker/accessibility/ownership consequences, not an approved safe hook.

GTK4 reads platform/portal settings on Wayland; this does not make the existing
GTK3 palette a complete GTK4 theme. The current adapter deliberately leaves GTK4
full-palette and transparency coverage deferred. Thunar CLI/D-Bus service presence
alone proves neither CSS refresh nor safety during file operations. No safe
external refresh is established here; next-process status is the recommended limit.

Evidence: [GTK3 3.24.52 gtksettings.c](https://github.com/GNOME/gtk/blob/3.24.52/gtk/gtksettings.c)
(`settings_init_style`, `settings_update_theme`),
[GTK3 CSS provider](https://github.com/GNOME/gtk/blob/3.24.52/gtk/gtkcssprovider.c),
[GTK4 4.24.1 settings](https://github.com/GNOME/gtk/blob/4.24.1/gtk/gtksettings.c).
Inspected 2026-10-24; LGPL upstream source inspected, not copied. Attempts to fetch
exact Thunar XML paths did not resolve; absence of an API is not asserted as proven.
No broad transparent GTK CSS, forced restart or file-operation interference.

## Remaining target findings and limits

- **Zen:** the current hybrid renderer only overrides ctp-base/surface0/text aliases;
  native workspace styling remains operator-owned. Enrollment requires custom
  stylesheet preference and a confirmed profile. No verified non-destructive chrome
  reload is implemented. Keep restart-required status, never automatic termination;
  arbitrary website backgrounds stay unchanged. This is the existing adapter audit,
  not a completed new exhaustive Zen API investigation.
- **Neovim:** installed remote.txt documents --listen/RPC, but no MAGI session
  enrollment/discovery contract exists. Arbitrary sessions must be left alone.
  Base Normal/NormalNC backgrounds remain terminal-default; floats stay intentional.
- **Yazi:** preserve the existing flavour symlink and next-launch boundary. Safe
  current-version reload needs further verification after the architecture gate.
- **btop:** current renderer maps boxes distinctly but reuses gradients broadly:
  CPU/temp/used get blue→yellow→red; other resources share teal→blue→lavender.
  Selection foreground is accent on surface, which needs representative contrast
  checks. Proposed polish: stable CPU/memory/network roles, clearly paired selection
  foreground/background, resource-specific gradients and warning/highlight roles.
  `theme_background=false` is confirmed in operator config and must remain untouched.
  No palette change is shipped at this gate. btop help has no reload option; absence
  of a supported signal has not been conclusively established. Do not invent one.
- **Starship:** generated config preserves operator layout. It is loaded through the
  configured path; existing shells without that environment need a new shell.
  Next-prompt status needs no persistent-process reload. Exact-version config loader:
  [Starship 1.27.0 config.rs](https://github.com/starship/starship/blob/v1.27.0/src/config.rs),
  inspected 2026-10-24, `StarshipConfig::initialize` / file loading (ISC source, no copy).
- **Fastfetch:** current adapter consumes ANSI rather than generating independent
  RGB. Next invocation is the appropriate boundary, conditional on terminal palette
  activation. No process reload/start is needed.
- **Hyprland:** current adapter evals only generated border colours and checks
  configerrors. It does not read back the border values authoritatively. Keep blur,
  fullscreen/client opacity and effects out of this adapter.
- **MAGI:** Settings palette is reactive. No external restart belongs here.

## Proposed adapter v2 and coordinator (not implemented)

Choose **ThemeActivationCoordinator**. It consumes committed artifacts, never
renders or publishes application config. One capability registry should provide
id/label, generation support, validator, activation kind, safeAutomatic,
requiresUserAction and readback strength. QML consumes this registry rather than
maintaining another application list.

Kinds: live, safe-reload, next-launch, restart-required, unsupported. Result fields:
transactionId, targetGeneration, target, phase, status, detail, observedIdentity,
readbackEvidence. User labels: Live, Reload requested/Reloaded, Applies next launch,
Restart required, Unsupported, Apply failed. Do not claim visible success merely
because a command returned zero. Distinguish generation/publication/activation
failure and action required.

Transaction proposal:

1. Snapshot canonical palette + applicationAppearance + enabled target set.
2. Render every candidate and run adapter-specific validation without publication.
3. Build immutable release with artifact hashes; compare enrollment prerequisites.
4. Commit one shared release pointer, with durable journal and recovery protocol.
   Migration of existing per-target current pointers must preserve enrolled paths,
   ownership markers, older generations and the 12G appearance transaction.
5. Only then plan/dispatch activation. One app's runtime failure retains valid output
   and does not prevent other safe targets from activating.
6. Store results under `$XDG_STATE_HOME/magi/theme-activation/`, never settings.json.

Use a transaction ID hashing the full desired render input and target digest map.
Reject late A/B results when C is current. Deduplicate app/generation/action; bounded
explicit retry only. Respect existing save/debounce behavior. Startup reads the
published generation and previous activation state without replaying every reload.
App absent is not failure and must not auto-launch. Owner changes during dispatch
mean retryable/unavailable, never redirect a stale action to a new app implicitly.

The 12G appearance coordinator currently publishes Ghostty through the same store;
it must participate in the shared commit protocol rather than remain a second
independent path through a migrated layout. The separate global-blur service and
its baseline are outside the theme transaction. Schema stays 19: runtime status
and generations are not user preferences.

## UI and native acceptance plan

No UI changes or preview gallery at this stop. Recommended location after review:
Appearance → Application themes, one quiet summary and expandable rows fed by the
registry. Keep Transparency support details consistent with those same capabilities.
No first-class admin page, toast storm, unsafe restart button or fake parity.

After implementation approval: fake executor matrix for all kinds, stale A→B→C,
app absent/starting, duplicate generation, validation abort, publication recovery,
activation failure, startup reconciliation; btop contrast fixtures for Mocha,
Everforest Hard, Rosé Pine, Nord, Tokyo Night Moon and Rosé Pine Dawn. Native gate
then checks multi-window/process Ghostty safe reload and all 12G invariants; controlled
user-approved Zen restart; existing/new Thunar-process behavior without file-operation
interruption. No native acceptance is claimed in this initial pass.

## Verification and exact inventory

Existing regressions passed unchanged: Theme Orchestrator (15 tests, including the
intentional partial-failure contract), Phase12G (26 tests), global blur (11 tests),
12G lifecycle and presentation, copied schema-18→19 preservation/idempotence,
Settings persistence, Settings presentation/navigation, Settings Appearance,
Phase12F and runtime visuals. Existing adapter fixtures are included in the
Orchestrator suite. No new coordinator/btop-polish tests are claimed because their
implementation is held at this gate. No Settings UI changed, so no 12H captures.

Protected file content and symlink snapshots match; main tracked diff and untracked
inventory are identical to the start. Both indexes are empty. git diff --check passes.
No integration, staging, commit or push occurred.

Exact inventory: **4 paths — 1 added, 3 modified, 0 deleted**, documentation only:

- A `linux/magi/docs/design/phase12h-theme-activation.md`
- M `linux/magi/docs/README.md`
- M `linux/magi/docs/architecture.md`
- M `linux/magi/docs/decisions.md`

The ordinary git diff --stat lists the three tracked edits; the new design report
is untracked and included in the four-path inventory above. Audit snapshots and
runner logs remain outside Git under `/tmp/magi-12h-audit/`.

## Final isolated inventory and protected-state check

33 paths: **21 added, 12 modified, 0 deleted**. Source/model/adapter/UI: 12;
documentation (including gallery index): 5; preview PNGs: 6; tests/fixtures: 10.
Schema files and operator settings are unchanged. Both indexes are empty. The 14
protected entries match `/tmp/magi-12h-audit/protected.json` by bytes/link destination;
the main tracked diff matches its audit snapshot exactly. No live app action or
live generated-output write was performed.

```text
M linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/ApplicationsPage.qml
M linux/magi/.config/quickshell/magi/services/ApplicationAppearanceService.qml
M linux/magi/.config/quickshell/magi/services/ThemeOrchestrator.qml
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/adapters/__init__.py
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/adapters/base.py
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/adapters/terminal.py
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/coordinator.py
M linux/magi/docs/README.md
M linux/magi/docs/architecture.md
M linux/magi/docs/decisions.md
M linux/magi/tests/theme-orchestrator/run.py
A linux/magi/.config/quickshell/magi/services/theme_activation/capabilities.py
A linux/magi/.config/quickshell/magi/services/theme_activation/coordinator.py
A linux/magi/.config/quickshell/magi/services/theme_activation/executor.py
A linux/magi/.config/quickshell/magi/services/theme_activation/validation.py
A linux/magi/docs/design/phase12h-theme-activation.md
A linux/magi/docs/design/previews/phase12h/01-appearance-normal.png
A linux/magi/docs/design/previews/phase12h/02-healthy.png
A linux/magi/docs/design/previews/phase12h/03-mixed.png
A linux/magi/docs/design/previews/phase12h/04-failure.png
A linux/magi/docs/design/previews/phase12h/05-compact.png
A linux/magi/docs/design/previews/phase12h/06-dawn.png
A linux/magi/docs/design/previews/phase12h/README.md
A linux/magi/tests/phase12h/fixtures/btop-catppuccin-mocha.theme
A linux/magi/tests/phase12h/fixtures/btop-everforest-dark-hard.theme
A linux/magi/tests/phase12h/fixtures/btop-nord.theme
A linux/magi/tests/phase12h/fixtures/btop-rose-pine-dawn.theme
A linux/magi/tests/phase12h/fixtures/btop-rose-pine.theme
A linux/magi/tests/phase12h/fixtures/btop-tokyo-night-moon.theme
A linux/magi/tests/phase12h/presentation.py
A linux/magi/tests/phase12h/presentation.qml
A linux/magi/tests/phase12h/run.py
```

## Controlled native gate — preflight started, 2026-10-24

Operator approved controlled integration and confirmed All changes saved. Baseline
remains d4f22babf3f87e03154a8ee98a1590763694d2b5, divergence 0 0; main index empty.
Fresh protected/config/generated-output snapshot: `/tmp/magi-12h-native-p21ep2yw`.
Preferred theme is Catppuccin Frappé; schema 19; shared appearance managed at 50%
background opacity with blur enabled. Global blur is managed at 12, captured baseline
8. Shell runtime directory is `y610sddnt`; log position and instance identity saved.
A read-only candidate render matches every current Ghostty artifact and its generation
`1dfb3a836a94f806ac70a87ed2f5029dbe730042f5661dde7a5c13406c1dff3e`.

The sandbox isolates host processes and denies session D-Bus connection. Host
process/owner verification is pending operator read-only output; source integration
has not begun. No native activation result is claimed. An additional fake-executor
test proves failed activation is not automatically retried repeatedly, but explicit
Retry performs a new attempt and clears the failure. All 23 Phase 12H tests pass.

Operator process preflight confirms one MAGI process (1546), Ghostty PID 2449 at
`/usr/bin/ghostty`, D-Bus owner `:1.40` with UID 1000/PID 2449, running Zen PID
229890, and no Thunar process reported. Saved-state confirmation remains recorded.

Controlled 33-path integration completed. Shell `y610sddnt` retained identical
instance identity and logged Configuration Loaded at 16:13:36 without new QML
warnings/errors. Activation phase is ready; Ghostty explicitly recorded startup
activation skipped. Only btop's generated artifact generation changed, as expected
for adapter v2; other target generations and Phase 12G policy remained identical.
All 14 protected entries remain byte/link-identical and the index is empty.
First native theme switch and visual verification are pending operator action.

First native Frappé → Nord switch: operator confirmed Ghostty reloaded without
manual intervention. Runtime status is ready; Ghostty reports Reload requested
(coveredProcesses=1, otherProcesses=0), Zen Restart required. All enrolled target
palettes are Nord without errors. Settings differ from the preflight snapshot only
in the chosen theme; 50% background opacity, blur preference, and global blur
preferences remain unchanged. Generated Ghostty output retains single opacity/cell/
CSS keys and the 20px GTK blur request. Multi-window coverage and light-theme
visuals still require operator confirmation; no stronger machine readback is claimed.

### Native btop discovery failure — concrete correction

Operator confirms both ordinary Ghostty windows update automatically across the
requested theme changes, preserving transparency and blur. Fresh btop is readable
but looks stock; native btop acceptance is withheld.

Exact btop v1.4.7 `src/btop_theme.cpp`, `updateThemes`/`setTheme`, inspected
2026-10-24: theme selection is restricted to scanned custom/user/system directories.
An absolute generated path outside those directories is not loaded; it silently
falls back to Default. The configured MAGI path was therefore ineffective, despite
valid generated colours. Source: https://github.com/aristocratos/btop/blob/v1.4.7/src/btop_theme.cpp .

Corrected isolated enrollment creates an owned `btop/themes/magi.theme` symlink to
the single generated output and selects that enumerated path. No palette changes.
Regression checks enumeration, link ownership/removal and preservation of
`theme_background = false`. Existing enrollment needs a controlled re-enrollment
after the fresh btop exits normally; no process will be killed or messaged. A native
`btop --themes-dir "$HOME/.local/share/magi/theme-orchestrator/btop/current"` check
can first expose the intended palette without altering enrollment.

Operator confirmed the explicit theme-directory launch makes btop look better;
the stock-theme fallback diagnosis is natively supported. Corrected enrollment
code and its passing discovery/removal regression are integrated. Permanent
re-enrollment waits for the diagnostic btop to exit normally.

Operator closed diagnostic btop normally. Permanent re-enrollment completed under
the existing Theme Orchestrator lock/journal: only its `color_theme` path changed
and an owned `~/.config/btop/themes/magi.theme` link was added. Other target records
were identical; `theme_background = false` was retained. Plain-btop verification
remains pending. Touch/identical-content replacement did not trigger a reload.
Adding an explanatory debounce comment to the already-reviewed QML service caused
one normal watched-source reload, completing in the same shell instance without
QML errors. Artifact generations and target/action receipts remain unchanged;
startup reused existing activation results. Settings equal the original preflight
snapshot (Frappé). Post-reload theme switch/independent Ghostty test remain pending.

Independent-instance gate: supplied native screenshot/process view shows normal
Ghostty PID 2449 and diagnostic `--gtk-single-instance=false` PID 285649, with
original MAGI PID 1546 and Zen PID 229890 still present. Diagnostic startup logs
confirm generated colours and GTK blur CSS were read. Coordinator now reports
coveredProcesses=1, otherProcesses=1 with explicit manual-reload guidance, phase
ready. Saved theme is Frappé again; visual confirmation of separate-instance
behaviour remains pending. Plain btop is shown in the native process list without
the temporary themes-dir argument, with the corrected theme path/link installed.
