# Phase 16 — UX quality, accessibility and performance

Audit date: 2026-10-28. Accepted input `dabf462` (schema 22), synchronized and clean.
No new features, preferences, palette changes or native-lock changes. Production was
kept untouched during inspection and synthetic reproduction. This is a bounded source
and interaction audit, **not** a screen-reader certification or whole-desktop benchmark.

## First review and ranked findings

11 findings: **P0 0 / P1 1 / P2 8 / P3 1 / P4 1**. No critical defect established.
The first review preceded runtime edits. Four bounded fixes were selected; the rest
remain documented rather than turning this phase into a redesign.

Paths below are relative to `.config/quickshell/magi` unless stated otherwise.

| ID | Severity | Concrete issue / evidence | Decision |
| --- | --- | --- | --- |
| Q1 | P1 | `plugins/bar/controlcentre/ControlTile.qml` accepts Tab/Space/Return but renders identical pixels with/without keyboard focus. Focus location is invisible among four primary controls | Add an independent inset focus outline and guarded accessible press action; retain configured tile fill/rim/icon ink |
| Q2 | P2 | `services/NotificationModel.qml` runs its 50 ms expiry loop with zero records/toasts; synthetic `lastTick` changes during an empty 250 ms interval | Stop expiry timer when no work exists; reset elapsed-time origin on resume; retain hidden-notification expiration, hover pause and toast exit |
| Q3 | P2 | `components/controls/IconSlider.qml` uses decorative slider-border width for focus; setting width 0 removes all focus pixels | Give focused slider a minimum 1 logical-pixel outline, without changing the unfocused style |
| Q4 | P2 | Wi-Fi network rows have empty `Accessible.name` and no accessible action; password TextInput lacks a contextual name | Name rows using full SSID/signal, add guarded accessible press, name password input without exposing its value |
| Q5 | P2 | Brightness 2s / QuickActions 5s polling persists with surfaces closed; Clipboard has a 30 ms queue multiplex timeout | Defer: external brightness/VPN changes and two clipboard queues need explicit event/lifetime designs; no speculative frequency changes |
| Q6 | P2 | Bar expandable pills/workspaces/date are primarily pointer/shortcut driven, not a complete Tab traversal. Removing `activeFocusOnTab` from a currently focused custom tile emits a Qt warning | Defer comprehensive Bar/focus handoff contract; keyboard shortcuts continue to expose surfaces. Do not make the panel seize keyboard focus |
| Q7 | P2 | Audio application labels/device dropdowns and Wi-Fi SSIDs elide but do not consistently expose hover text; full Bluetooth row labels are accessible | Defer a consistent bounded tooltip policy; no width/layout expansion to display arbitrary names |
| Q8 | P2 | Palette audit already measures One Dark muted/background 2.32:1, One Light accent/background 3.88:1 and error/background 3.51:1 | Record limits; no silent upstream palette remapping or blanket contrast claim. Primary/selected ink checks remain independent |
| Q9 | P2 | No reduced-motion contract; surface/reorder/toggle transitions remain 70–200 ms and run during normal navigation | Document future accessibility preference, not a new Settings feature in this phase |
| Q10 | P3 | `AudioLevel.qml` appends “ volume” to labels already called “Output volume” / “Input volume” | Minor spoken-label duplication; defer rather than broadening patch |
| Q11 | P4 | Settings metrics coexist with local values in dense menus/previews | Intentional component-family differences; no mechanical spacing/size normalization |

## Accessibility / UX coverage

| Surface | Keyboard/focus, label and hit-target evidence | Status / remaining limit |
| --- | --- | --- |
| Bar / workspaces | Full-cell MouseAreas; utility buttons have names; expandable pills handle right-click/wheel and originating output. Workspaces use compositor keyboard shortcuts | Q6; no claim every Bar item is Tab reachable |
| Hub | Shared selector buttons, arrow handling, AfterItem Escape; retained Settings ownership; outside mask separates content from dismissal | Existing Hub/catalogue and multi-output regressions; no ownership change |
| Apps | Search owns arrow/Enter navigation; item has application name and accessible press; full item pointer target | Search/catalogue/lifecycle regressions; system app icons remain system-owned |
| Clipboard | Search/navigation routes, card actions, explicit destructive confirmation and bounded history | Presentation/model coverage; private-bus image decode remains environment-limited |
| Notifications / toasts | Full-card action area, named dismiss/action controls, text bounds; hover pauses expiry | Q2 corrected in real model with fake notifications; no notification-protocol replacement |
| Emoji | Search/category keyboard routing, named grid items and accessible choose action | Existing category/selection/empty-result tests |
| Settings / lock designer | Shared 34px controls, 24px page padding, row trailing-field constraints, focus primitive; family/item ownership | Long Profile text with pinned preview regression retained; local editor metrics intentionally differ |
| Control Centre | Primary tiles keyboard-operable but lacked focus pixels; secondary ActionButton already has focus border | Q1 corrected; original colour oracle still applies to configured rim/ink |
| Wi-Fi | Full 52px row target, keyboard activation, nested password Escape, long SSID eliding | Q4 corrected; Q7 tooltips deferred; connection/backend logic unchanged |
| Bluetooth | Paired-first list, row/button labels, busy gating, prompt Escape/cancel, bounded discovery | Existing pairing/Agent1 tests; authenticated hardware acceptance remains separate |
| Audio | Named input/output dropdowns, grouped application sliders, independent icon mute target, matching 48px slider height | Q3 corrected; dropdown uses existing Settings primitive; Q7/Q10 remain |
| Calendar | Named navigation/day cells; arrow/PageUp/PageDown/Home and explicit focus ownership | Existing Calendar and Hub/surface dismissal coverage |
| Tray | Full cells, Return/Enter/Space/Menu/Shift+F10; keyboard focus separate from native menu-open and attention | Existing interaction/removal/overflow/fleet tests; no shortcut popup resurrected |
| Wallpaper Manager | Virtualized grid, search/monitor selectors, Return/Enter choose, favourite button, filename tooltip, Escape | Existing renderer/backend/presentation tests; no wallpaper process changes |
| Native lock presentation | Native input authority; QML is rendered presentation, not an independently focusable credential form | Presentation tests and palette credential preview only; no PAM/lock authority modifications or real-lock test |

Shared expanded surface owns geometry, transition, mask and dismissal. Audio fits content
with bounded scroll; Wi-Fi/Bluetooth retain list bounds; Calendar has fixed date-grid
geometry. Those differences are useful rather than defects. Existing surface tests cover
inside/outside clicks, invalid output removal, focused-output routing and family dismissal.
Settings nested editors handle Escape first; Hub handles unconsumed Escape afterward.
Native tray menu dismissal remains platform-owned and covered by prior native acceptance.

Long Profile name/message, notification text, Bluetooth names, SSIDs, audio labels and
wallpaper names were traced to wrapping/eliding constraints and existing synthetic
fixtures. Q7 records missing tooltip coverage, not an assertion that all long text is
fully readable. New Wi-Fi accessible names preserve the entire synthetic SSID.

## Focus and visual evidence

`tests/runtime-visual/quality.qml` uses actual tile/slider/Wi-Fi/NotificationModel source
with isolated service inputs. Before correction: tile/zero-border-slider focus image
pairs were byte-identical, idle expiry advanced, Wi-Fi row name was empty. After:
focus changes pixels, Tab/Shift+Tab order and Space/Return/slider arrows/Home/End work,
full row hit targets activate, disabled accessible tile action does nothing, and names
remain meaningful. It tests 640/1280/1920 logical widths and a separate 1.5-scale run.
These are representative logical geometries, not physical 4K monitor acceptance.

Eight palettes checked: Everforest Dark Hard, Kanagawa Wave, Dracula, One Dark,
Gruvbox Dark, Gruvbox Light, One Light and Rosé Pine Dawn. Background alpha 1/.75/.5
(the supported range) preserves opaque text/focus tokens. Disabled-control opacity is
an intentional separate affordance, not a shared-transparency regression.

The existing palette composition generated eight temporary captures covering Bar,
Settings gallery, Control Centre, Audio, Calendar, notification and lock credential
preview; Kanagawa Wave and Gruvbox Light were inspected side by side. No screenshot
set is committed. Software captures omit some SVG artwork in this environment; they
validate geometry/palette hierarchy, not native SVG or compositor blur quality. Hub,
Wi-Fi/Bluetooth and Settings opening/dismissal remain exercised by the same production
fixture and existing suites. Native smoke is a separate closeout gate.

## Timer and periodic-work inventory

All **28 QML Timer declarations** were enumerated, including one-shots. A = necessary
periodic observation while needed; B = bounded maintenance/debounce/deadline;
C = event-driven follow-up candidate; D = accidental idle work. Cost below is source-
derived frequency, not measured CPU, power draw or battery-life improvement.

| Owner (Timer count) | Interval / running condition | Purpose / cost | Class and disposition |
| --- | --- | --- | --- |
| Brightness (2) | 60ms write debounce; 2s always | User write coalescing; up to 30 brightnessctl reads/minute even while closed | B / C; retain external-brightness observation pending hardware watcher design |
| QuickActions (1) | 5s always, duplicate queued status requests suppressed | 36 Python status launches/minute plus up to 84 child utility launches/minute with all backends available | C; defer event-driven status ownership |
| NotificationModel (2) | 60s retention; 50ms expiry | Bounded history scan; previously 20 idle wakeups/s and record copies | B / D; expiry now needs a toast or unpaused live finite timeout |
| MediaController (1) | 1s only supported progress + playing + CC open | MPRIS position refresh, no subprocess | A; retain |
| ProfileHeader (1) | 60s outside preview | Local hour/greeting; per presentation, cheap Date read | B; retain |
| Weather (3) | 750ms debounce; self-rearmed 30min; 20s deadline | Opt-in configured weather worker; not active when disabled | B; retain |
| ApplicationAppearanceService (1) | 450ms after intent/readiness change | Coalesced reconciliation, no periodic poll | B; retain |
| GlobalBlurService (1) | 450ms after intent/readiness change | Coalesced compositor reconciliation | B; retain |
| ThemeOrchestrator (1) | 450ms after activation/intent | Coalesced publication; receipts avoid repeated activation | B; retain |
| LockAuxiliary (1) | 300ms after payload changes | Display-only snapshot write, no continuous sampling | B; retain |
| AudioModel (2) | 5s each, explicit sink/source request only | Pending-selection error deadline | B; retain |
| Bluetooth (2) | 30s discovery; 10s backend startup | Bounded discovery and worker startup, no periodic reconnect | B; retain |
| Clipboard (1) | 70ms search debounce | One search message after typing settles | B; retain |
| ActionConfirmation (1) | 5s after arming | Disarm destructive action | B; retain |
| Wallpaper (2) | 700ms topology debounce; 3s startup retry | Bounded restore/reconciliation, no library polling | B; retain |
| SettingsStore (1) | 250ms after edit | Coalesced save, no periodic save | B; retain |
| SettingsDragHandle (2) | 500ms hint; 5s dismiss | Pointer/keyboard hints only | B; retain |
| SettingsReorderBoard (2) | 140ms selection; 16ms while dragging | Interaction-only auto-scroll (~62.5Hz), not idle work | B / A; retain |
| ClipboardPage (1) | 5s after arming erase | Local confirmation | B; retain |

Additional periodic mechanisms:

- `ClockState`: one shared SystemClock at minute precision.
- Clipboard Python worker: `commands.get(timeout=.03)` then one event-queue check,
  about 33 waits/second even without incoming content. Bounded queues (4 events,
  16 commands); merging wakeups deserves a separate lifecycle test, Q5.
- Native lock: logind bus pump 10ms while connected; auth worker poll 10ms during
  an auth attempt; 1s clock tick renders only on minute changes; protocol deadlines
  5/15s, sleep deadline up to 4s, 100ms pending-input slot, auth retry and development-
  only deadline. Single-shot 0/16ms work handles lifecycle/frame scheduling. Security
  owner is explicitly out of scope; no timer/security change proposed.
- Wallpaper backend's 100ms wait is a bounded renderer-start wait, not permanent
  shell polling. Clipboard capture loops block on input; Bluetooth uses GLib I/O,
  and its 15s D-Bus request timeout is a deadline, not a poll.

### Performance correction and limits

Q2 removes **20 empty expiry callbacks per second** by construction. The regression
observes no `lastTick` changes during empty/fully-expired states, then verifies a new
notification after simulated long idle is not instantly expired. Hover pause/resume,
non-toast expiration and persistent-toast exit still complete. The minute retention
scan remains; no claims are made about total idle CPU or startup milliseconds.

## Subprocesses, models, I/O and lifetime

- Brightness / QuickActions are the recurring process paths above. Combined maximum
  with all queried utilities present is 150 process starts/minute (including Python
  workers); this is a source-derived upper estimate, not a host measurement.
- User actions: GIO launcher, clipboard/emoji copy, power/VPN change, import/asset
  validation, wallpaper choice and Settings persistence. Arguments are vectors;
  no launch or destructive action was invoked by this audit.
- Startup/reactive: persistent clipboard and Bluetooth workers; wallpaper restore;
  theme/appearance/blur reconciliation; optional weather and auxiliary publication.
  Settings/palette inputs use FileView/watch and generation checks. Catalogue/search
  reuse models instead of scanning icon/application directories per frame.
- `services/qmldir`, `Audio.qml`, `TrayService.qml`, `Network`, `Bluetooth`, Launcher,
  Clipboard and Notifications keep protocol models singleton-owned. `BarFleet` creates
  per-output presentation, not duplicate PipeWire/BlueZ/tray watchers. Settings preview
  models are synthetic; this audit's runners stub services and remove live endpoints.
- Clipboard: 8MiB/item, 256KiB/text, 64MiB total, configured history cap; pinned cap
  min(50, historyLimit), sensitive-offer suppression retained. Conversion thumbnails
  are bounded and lifecycle-owned. No history/storage normalization performed.
- Notification snapshots limit app/title/body/actions; history count and retention
  prune through the owner. The expiry patch does not prune extra data or change policy.
- Wallpaper thumbnails decode at 320x200 asynchronously; library grid is virtualized.
  Shared rounded artwork uses 2x display-size decode; lock auxiliary artwork has a
  16-file bound. Lock presentation uses native-owned image providers. No measured
  retained-image growth was established; no speculative cache eviction added.
- Audio groups are metadata-derived and react to node arrival/removal; group edits
  explicitly target member streams. Same-name grouping remains documented debt.
  Bluetooth discovery/pair/auth lifecycle and native Tray menu ownership are unchanged.
- Shell startup activates the documented owners. There is no initializer audio-route
  write, Bluetooth connect, application launch or Tray activation in inspected paths.
  A runtime reload smoke check remains required after integration; source review alone
  cannot establish live routing/mute/theme state preservation.

## Test quality and acceptance

Strict Qt warnings/assertions remain failures. The new fixture reuses the existing
isolated production harness rather than another stub framework. Two fixture mistakes
were corrected during development: unsupported alpha .4 (schema minimum is .5), and
forcing availability off while the tile held focus (Qt warns; recorded under Q6).
No warning was whitelisted. Old palette-colour and Profile layout regressions remain.

The host private-D-Bus notification test passed creation/replacement, timeout and hover,
DND/fullscreen, actions/resident/exact close reasons, transient/burst/history bounds,
reload/replacement and singleton ownership across reload. It uses temporary state and
does not touch the desktop notification service. This independently covers the real
protocol behind the timer change, beyond the fake model used for focus/idle checks.

Final canonical run: **88 commands; 84 PASS, 0 FAIL, 4 ENVIRONMENT, 0 SKIPPED,
0 UNKNOWN**. The environment limits are Bluetooth private-bus transport, Clipboard
sandbox image decoding, Notifications private-bus transport and native-lock
SOCK_SEQPACKET transport. Notification protocol coverage also passed on the host as
recorded above. No coverage was retired or warning signature weakened.

Slowest commands in this run:

| Command | Seconds | Result |
| --- | ---: | --- |
| `launcher/lifecycle` | 128.2 | PASS |
| `phase10b/run` | 81.0 | PASS |
| `runtime-visual/run:appearance.qml` | 73.5 | PASS |
| `runtime-visual/run:typography.qml` | 62.3 | PASS |
| `native_lock` | 41.8 | ENVIRONMENT |

The launcher delayed-write regression is intentionally slow and unchanged. The new
quality fixture completed in 3.2s; it also passed separately at 1.5 scale. Documentation
link checks and `git diff --check` passed.

Native integration produced exactly one normal Quickshell reload in the existing
process, with no WARN/ERROR lines. Before/after snapshots matched Settings data and
all 34 protected byte/link entries, PipeWire default routes/node volumes, Bluetooth
connection/pair/trust state, Tray registrations, compositor application clients and
current generated-theme pointers. These are endpoint comparisons, not a continuous
trace of every transient hardware event.

The initial checker correctly stopped on a changed activation-status SHA-256. Focused
reconciliation reconstructed the full-target pre-reload JSON and matched that exact
SHA-256; after reload Application Appearance had published the Ghostty-only summary.
Receipt keys, statuses, details and process coverage were identical; only summary
scope and the Ghostty receipt's bookkeeping generation differed. The unchanged
coordinator's matching-key branch reuses the receipt and skips activation dispatch.
This is expected reconciliation bookkeeping, not a theme reapply storm; no production
change or broad exception was added. Future reload diagnostics should compare receipt
semantics, not require byte-identical full-target versus single-target summaries.

Operator native smoke passed on 2026-10-28: Bar, Hub, Settings, Audio, Bluetooth,
Tray, Launcher and the requested keyboard-focus checks. No further feature work
is included. Schema remains 22.
