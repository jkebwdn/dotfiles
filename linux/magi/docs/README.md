# MAGI documentation

## Phase 10C.1 — accepted and complete (2026-10-22)

Power & Idle is integrated with schema 15 and saved 300/600/0 policy. The
managed user service owns Hypridle and reads generated runtime configuration
outside Git. Default Apply, timed lock, DPMS wake, inhibitor refusal/recovery,
invalid ordering, manual lock and real suspend/resume passed the live gates.
First-character resume input and temporary suspend-listener activation passed. The original
canonical config is an emergency fallback only. The exact startup command passed an idempotent active-service check; a true
fresh login remains untested. The operator accepted finalization; protected local state is excluded.
See [ownership, acceptance evidence, rollback and remaining limits](design/phase10c1-power-idle.md).
No MAGI Lock/PAM redesign, Hyprmon replacement or Phase 10C.2 work.


## Phase 10B — accepted and complete (2026-10-21)

Optional external bars share the existing services. ShellScreen-keyed Variants,
origin-scoped status/Calendar and singleton Hub routing, Top/Bottom, horizontal
inset and edge offset are implemented with schema 14 defaults preserving the
single top bar. Each enabled output reserves 48 + edgeOffset logical px. The operator confirmed the physical dual-output, hotplug and geometry checks.
The operator accepted the standalone final state after leaving the office and
authorized the exact Phase 10B commit/push; protected local state is excluded.
[Architecture audit, policy, API evidence, tests, previews and vertical feasibility](design/phase10b-bar-multimonitor.md).
The startup guard is applied; the correction auto-reload was clean. Main output
prefers internal, then retained eligible main, then focused active output once,
then connector-name order. Keyboard shortcuts target the focused enabled output
without moving main; bar clicks retain their origin. The checkpoint records the initial live-reload incident
and authorized one-key settings repair. Physical checklist results and the final standalone snapshot are recorded there.
No lock/authentication, Hypridle or Phase 10C changes.

Phase 10A fallback correction: selected pack → same-ID MAGI Default → bundled
SVG placeholder. No parent inheritance or user overrides; [audit and previews](design/phase10a-icon-fallback.md).

## Phase 10A — accepted and complete (2026-10-20)

Baseline `649326c77022bd400bf241336894102d50ff0616` was synchronized at `0 0`.
MAGI Lock remains complete at production `magi-lock 0.1.0-3`; Hyprlock is retired,
Hypridle remains. This milestone does not change lock/authentication architecture.
Live review passed; Clipboard option B retains pinned-first ordering with newest-on-entry.
Phase 10C remains deferred; Phase 10B now has a separate review checkpoint above.
See [Phase 10A ownership, tests, previews and deferred work](design/phase10a.md).


Phase 2E + 2E.1 + 2E.2 is **natively accepted**. The current shell includes the
five-mode persistent Hub, Settings/Wallpaper integration, shared visual settings,
first-party utility services, Profile/Media typography and opt-in live weather.
The [MAGI README](../README.md) is the product/setup landing page.

## Current references

- [Final Phase 2E acceptance, documentation audit and exact allowlist](design/runtime-phase2e-finalization.md).
- [Architecture](architecture.md), [decisions](decisions.md) and [Quickshell reference](quickshell-reference.md).
- [Phase 2E.2 keys, weather service and focused validation](design/runtime-phase2e2.md).
- [Phase 2E.1 interaction/presentation corrections and retirements](design/runtime-phase2e1.md).
- [Phase 2E shared surfaces, retention and Settings restructure](design/runtime-phase2e.md).
- [Research index](research/README.md) — dated source evidence, not the current product roadmap.

The operator has accepted live weather, all eight shortcuts, light-theme presentation
and the final visual/interaction behavior. Rofi was removed by the operator and is
confirmed absent. MFTrunk and Rofi repository retirement is included.

## Historical implementation notes

The following entries retain their original implementation-time review status.
Their “pending”, “uncommitted”, older schema and future-host wording is historical;
the acceptance above supersedes it. Consult current references for runtime behavior.

## Phase 2E.1 — native review pending (2026-10-17)

Phase 2E.1 final feedback is implemented over the uncommitted Phase 2E tree. Hub is explicitly dismissed, Settings controls/sidebar are refined, cards measure natural content, and MFTrunk/Rofi runtime routes are retired. The operator subsequently removed Rofi; absence was verified in Phase 2E.2. [Exact paths, tests and native checkpoint](design/runtime-phase2e1.md).

> Phase 2E.1: Hub uses Escape after child interactions; Super+Q is only an ordinary compositor application binding, not a Hub close requirement.

> Phase 2E.1 supersedes legacy-tool references below: MFTrunk and Rofi are retired; MAGI Apps is the sole launcher route. Earlier references record historical state.

## Phase 2E whole-shell reconciliation — native review pending (2026-10-17)

Phase 2D is natively accepted at `b77e449`. Phase 2E adds shared borders, configurable
Hub anchoring, Appearance subnavigation, compact theme enrollment summary, notification
retention/hierarchy and final interaction polish. Schema 12 preserves operator tuning;
48px reservation and accepted service ownership remain. No commit/push.
[Checkpoint, exact paths, validation and native checklist](design/runtime-phase2e.md).

## Phase 2D secondary surfaces — native review pending (2026-10-17)

Calendar composition, Settings-embedded canonical Wallpaper Manager and media polish are implemented over accepted Phase 2C. Wallpaper has no production standalone host or extra Hub mode. Shared masks and operator values are preserved. See [exact paths, tests, protected-state comparison and native checklist](design/runtime-phase2d.md).

## MAGI Hub — Phase 2C, native review pending (2026-10-17)

Native follow-up: the operator accepts the Hub composition and integration. The final
Notifications-only refinement removes its remaining title and measures surface height
from content up to 640px. One native Notifications screenshot remains; see the
[refinement checkpoint](design/runtime-phase2c.md#native-notifications-refinement--2026-10-17).

Apps, Clipboard, Notifications, Emoji and Settings now share one retained Hub host
with a separate selector pill anchored at two-thirds of the logical output height.
Canonical Settings content and the real pinned Control Centre preview are integrated;
production Settings actions no longer create a standalone window. Shared search,
header-only masked artwork and utility presentation refinements are implemented.
Automated/offscreen checks pass; native screenshots, focus/input-region and GPU-edge
review remain. No commit/push. See [architecture, exact paths, tests and native
checkpoint](design/runtime-phase2c.md). Earlier dated architecture descriptions below
record their original milestones and are superseded by this phase where noted.

Final v1 refinement: MAGI, border-only Hyprland, Ghostty reload, GTK/Thunar and
Yazi are operator-accepted. Zen's operator-tested hybrid now has alias-only CSS,
a dynamic workspace background recommendation and hex-only Copy in Settings.
Fifteen focused tests, production pointer/Copy coverage, Settings and native
terminal checks pass; repository diff whitespace is clean. Compositor IPC remains
unavailable to this agent. See [acceptance, ownership and exact Git allowlist](design/theme-orchestrator.md).

## Zen native theme investigation — 2026-10-15

Read-only installed-source tracing identifies workspace-specific native base colour
and a separate profile accent preference. Recommended hybrid/manual native route
is recorded in [Zen native theme boundary](research/zen-native-theme-boundary.md);
no adapter or browser state was changed by this investigation. The earlier
unenrolled handoff state below is historical: the current Zen stylesheet has a
MAGI integration import.

## System Theme Orchestrator v1 — 2026-10-14, uncommitted review

Enrollment follow-up: Follow MAGI now keeps pending opt-in visible and presents confirmation inside the target row. A real production-page pointer regression covers enrollment, failure and removal; Zen reuses its confirmed profile.

Ten existing palettes remain canonical. Independent opt-in adapters, generated
XDG storage, reviewed reversible hooks and per-target Settings status are implemented.
Focused lifecycle, real QML/Settings and native terminal-parser tests pass. Native
operator acceptance and enrollment have since advanced as recorded above. See [architecture, ownership, validation and exact Git
allowlist](design/theme-orchestrator.md). The research checkpoint is unchanged.


## Wallpaper Manager — 2026-10-12, uncommitted review

Separate wallpaper tool/Settings page over configured hyprpaper 0.8.4, with a
bounded PNG/JPEG library, virtualized thumbnails, confirmed runtime selection,
per-monitor state, favourites and recents. Schema 10 adds focused preferences;
wallpaper state lives separately in XDG state. Automated/offscreen checks pass;
live compositor/renderer checks are blocked by this execution environment's socket
access. No packages, theme orchestration, Hub modes or Hyprland configuration changes.
See [checkpoint, limitations, native checklist and exact allowlist](design/wallpaper-manager.md).


## Control Centre action catalogue — 2026-10-10, uncommitted review

Hub consolidation baseline is committed at
`b32b88a4cfb68755f00eb1a25148892cc4319cea`, `main` tracking `origin/main`,
zero divergence at milestone start. Control Centre now offers optional Apps,
Notifications, Emoji, Clipboard and confirmed Reboot. Shared catalogue data
drives Settings validation and rendering, fixing secondary Settings rejection.
Defaults, schema9, configured order and independent columns remain unchanged.
See [audit, implementation, validation and exact allowlist](design/control-centre-action-catalogue.md).
Earlier dated checkpoints below retain their historical review wording.

## MAGI Hub — 2026-10-06, uncommitted operator review

Apps, Notifications, Emoji and Clipboard now share one utility host, while their
services/models remain independent. Existing shortcuts/IPC select modes directly;
the compact upper-right selector swaps retained content without replacing the
native window. Control Centre/Calendar stay anchored and coordinated; toasts and
capture remain independent. Four dedicated hosts and the permanent bell are retired.
No schema migration or runtime settings edit. See the [source of truth, validation
limits, review checklist and exact allowlist](design/magi-hub.md).

Emoji baseline verified as committed `a007259a4f8e79cd8372d520ea2c9902cb2a3393`,
`main` tracking `origin/main`, no divergence. The dated entries below retain their
historical checkpoint wording; temporary-host/future-Hub wording is superseded.

## Emoji Picker — 2026-10-05, uncommitted operator review

`SUPER+.` opens the new compact first-party Emoji Picker. Unicode 17.0 supplies
3,944 complete sequences; deterministic search spans nine categories, with
persistent bounded Recents. Independent model/search/service and reusable
EmojiContent sit inside a temporary zero-reservation host. Schema 9 adds Emoji
Settings; selection reuses the existing clipboard path and closes for normal paste.
Automated Emoji and focused regressions pass; the operator confirmed shortcut,
search, selection/paste, dismissal and focus restoration. See the [checkpoint,
remaining checks and exact allowlist](design/emoji-picker.md) and
[API/data evidence](research/emoji-picker-apis.md).

The temporary Emoji host described in that checkpoint has since been absorbed
into Hub; Control Centre and Calendar remain separate.

## Calendar / Date surface — 2026-10-04, committed `4f4205d`

The bar time/date now expand into a shared Calendar surface, absorbing their
normal presentation until closing completes. Reuses the existing shared-surface
lifecycle and bar window; no extra reservation. Local Gregorian month navigation,
keyboard selection, locale labels and schema 8 Date & time Settings are implemented.
Automated Calendar, Settings, shared-status, Launcher, Clipboard and Notifications
checks pass; operator live interaction checks passed. See the [review checkpoint
and exact Git allowlist](design/calendar-date-surface.md) and [API evidence](research/calendar-apis.md).
Calendar was committed as `4f4205dd021a44ce88acad3869799edfcc243ab2`, verified
locally at Emoji milestone start. Its earlier checkpoint retains historical review wording.


## Application launcher — 2026-10-04, committed `b895498`

First-party application-only launcher is implemented over baseline `c5bd0e2`.
List and grid share GIO desktop discovery/launch, normalized token ranking and
session frequency. Schema7 adds a Launcher Settings page with layout, size,
icons/labels and optional image controls. `SUPER+SPACE` toggles the zero-reservation
focus overlay; `SUPER+CTRL+SPACE` retains Rofi. Operator launch/focus/dismissal
checks passed; Neovim-in-Ghostty and grid foundation are now operator-accepted.
Hidden applications persist by desktop ID, with contextual Hide and Settings
Restore; an application-icon resolver separates lookup from layout. See [implementation and validation](design/application-launcher.md)
and [API evidence](research/application-launcher-apis.md).


MAGI is a modular Quickshell environment for Arch Linux and Hyprland.
This directory records implementation evidence, decisions and proposed research.
For the project overview, features and deployment, see the [MAGI README](../README.md).

## Legacy shell retirement — 2026-10-04

Current shell: **Arch + Hyprland + MAGI**, based on pushed `a5cce6b`.
MAGI owns the 48px bar/status surface, Control Centre, Settings, notification
D-Bus service/toasts/history/DND and first-party Clipboard Manager. The bounded
retirement checkpoint records package/configuration removal, preserved cliphist
history, retained wl-clipboard, runtime checks and the exact Git allowlist:
[operator checkpoint](research/legacy-shell-retirement-checkpoint.md).
Earlier dated entries below are historical evidence; package-preserving SwayNC
rollback and the installed cliphist service described there are superseded by
this retirement. Clipboard was committed at `a5cce6b`; its earlier uncommitted
review wording describes the checkpoint at the time.

## Planned future shell work

Separate future milestones: event/agenda providers;
MAGI lock screen replacing Hyprlock only after security review; further system
actions beyond this catalogue expansion; and a later whole-shell Settings/visual/composition pass.
Hyprlock remains the current lock screen. None is implemented in this retirement.

## Clipboard Manager — 2026-10-04, ready for final review

First-party Clipboard now uses an exact-offer Wayland capture helper, a bounded
MAGI-owned Python model and a normal540×660 floating desktop window. Text, safe
HTML-derived text, PNG/JPEG and URI lists support search, restore, pins, deletion
and clear-unpinned. `SUPER+SHIFT+V` opens it; the legacy cliphist watcher startup
is removed without reading/importing/removing its database. History defaults to
session-only; schema6 adds explicit opt-in disk persistence and privacy controls.

Initial clipboard contents are skipped; sensitive hints are rejected before
reading. Unmarked sensitive content cannot be identified reliably. Automated
model/schema/UI and harmless live-protocol checks pass. Current runtime retains
notification ownership, one1920×1080 main layer and48px reservation. Operator
interaction and corrected nonmodal focus checks passed. The old live cliphist
watcher is stopped; its installed service is disabled/inactive, with no startup
route in the current configuration. Existing cliphist history remains untouched.
Final milestone review is pending. See [design](design/clipboard-manager.md)
and [checkpoint](research/clipboard-manager-checkpoint.md). No commit/push.

## Permanent notification ownership — 2026-10-03, operator-accepted

MAGI now activates its accepted first-party NotificationServer directly from the
production ShellRoot on every process start. The legacy SwayNC DND adapter is no
longer queried. Hyprland starts only MAGI, and `SUPER+N` opens MAGI's Notification
Centre. The SwayNC package/configuration remain intact; its user service is masked
against D-Bus activation through the tracked Stow systemd package; its greeting
timer definition remains available but has no enablement links.

A final clean MAGI process restart automatically reacquired
`org.freedesktop.Notifications` as PID143717 without IPC activation. One live
notification produced a toast/history entry; Centre and DND checks pass. The
fresh runtime log is INFO-only, one main1920×1080 layer remains, and reservation
is exactly 48px. See the
[permanent ownership checkpoint](research/permanent-notification-ownership-checkpoint.md)
for exact state and rollback. Operator review passed; committed at `1598e12`.

## Notifications + Toasts — 2026-10-03, operator-accepted implementation

Continue from the [durable checkpoint](research/notifications-toasts-checkpoint.md)
and [design](design/notifications-toasts.md), based on accepted `d539b9b`.
First-party Quickshell notification service, bounded memory history, separate toast
stack and Notification Centre, DND integration and schema5 Settings are implemented.
Private-bus protocol tests, focused Settings/appearance/module tests and48-step
shared lifecycle pass. Connected-only Bluetooth and inherited primary/secondary
state colors are implemented; existing primary palette accents remain intact.

This section records the earlier temporary handoff; it is superseded for startup
ownership by the permanent-ownership checkpoint above.
The operator reports all checks passed and supplied Centre/toast screenshots;
pointer/fullscreen recovery, Settings, Bluetooth and state styling are accepted.
Latest runtime retains one1920×1080 main layer and exactly 48px reservation. The
checkpoint records the earlier owner/PIDs and upstream action-label limitation.
At that temporary checkpoint SwayNC had failed after a competing start; the
permanent tracked mask above now supersedes that live state. Plain-text body
markup polish, disk history and multi-output/fractional-scale remain follow-ups.
The accepted implementation is committed at `f3bdd43`; Clipboard follows above.

## Visual/state/morph sprint — 2026-10-03, accepted

Implementation, automated validation and final operator review are accepted.
The close-out adds per-control semantic palette accents and icon-only compact
Bluetooth. Continue from
[the durable sprint ledger](design/visual-refinement-checkpoint.md), not from the
original prompt. It records changed files, thresholds, appearance settings,
real-component tests, runtime measurements and remaining checks.

The status header remains one persistent Row with independent geometry progress.
Volume is a compact mute/wheel control. Wi-Fi authentication is now inline (the
Network backend is unchanged). CC has permanent media empty state, masked/profile
artwork, local greetings, unboxed actions and configurable semantic visual tokens.
The default and live status icon size are18px, still adjustable. Primary backgrounds
and rims use configurable signed shades of each selected-palette accent. Settings
schema v4 stores the semantic base accent per primary control; resolved RGB remains
theme-owned. The sprint is ready to checkpoint. Conditional connected-only Bluetooth
visibility and generalized inherited icon-state styling are deferred decisions.

## First-party MAGI icon pack — 2026-10-01

Implemented and operator-accepted: all 47 corrected 24×24 exports pass the
bounded SVG audit and are bundled byte-for-byte as the partial first-party
`magi-default` pack. Production semantic tinting preserves internal opacity in
default, accent and muted states across Catppuccin dark and light themes;
explicit fixed-color mode remains available for future multicolor artwork.
Missing roles inherit MAGI Legacy through the existing resolver.

The production shell is left on `magi-default` and Catppuccin Mocha. Full
settings and 48-step lifecycle tests pass, logs are clean, and the compositor
baseline remains one layer at `(0,0)` with 48px reservation. See the
[audit and acceptance checkpoint](research/magi-default-icon-pack-checkpoint.md)
and [icon-pack contract](design/icon-pack-contract.md).

## Control Centre actions and icon packs — 2026-09-28

Implemented and operator-accepted: settings schema v3 generalizes Control Centre into
primary tiles, dedicated sliders, secondary actions and detail views.
Production adapters cover Low Power, aggregate Airplane Mode, NetworkManager
VPN, SwayNC DND, Wayland idle inhibition, lock and confirmed
hibernate/shutdown. Defaults are data, not fixed UI slots.

Local inspection found no configured VPN and no user-writable power-profile
backend, so those actions correctly remain unavailable. Full local icon packs
now use validated 24×24 SVGs, managed XDG storage, a bounded manifest and parent
fallback to MAGI Legacy. See the
[checkpoint](research/control-centre-actions-icons-checkpoint.md) and
[icon-pack contract](design/icon-pack-contract.md).

All automated suites pass. The live shell has one 1920×1080 layer at `(0,0)`,
exactly 48px reservation, a saved/diagnostic-free v3 store and clean logs.
The operator passed DND, Caffeine indication, live secondary configuration,
destructive single-click arming and existing-feature regression checks.
Airplane Mode remains automated-only to avoid dropping the remote session;
Hibernate is unavailable on this no-swap system.

## Profile, real media and managed icon overrides — 2026-09-27

Implemented and operator-accepted. Settings schema v2 preserves the existing
configuration and adds explicit profile/media/Control Centre section data.
Control Centre now has optional live profile and real MPRIS regions; player
appearance/disappearance retargets the open surface without collapsing. Managed
avatar and bounded SVG imports use content-addressed XDG storage. Settings floats
and centres through a narrow class+title Hyprland rule while remaining a normal
movable/resizable desktop client.

All automated suites and 48 lifecycle steps pass. The operator passed profile
persistence/avatar, real MPRIS metadata/artwork/transport/disappearance, SVG
override/default, existing Wi-Fi/Bluetooth/Volume and outside dismissal. One
1920×1080 layer remains at `(0,0)` with exactly 48px reservation. See the
[implementation and acceptance record](research/profile-media-icons-checkpoint.md).

## Icons, Control Centre configuration and Settings — 2026-09-27

Implemented; **requested operator checks passed, checkpoint accepted**. Semantic IconRegistry uses the existing
MAGI glyph pack, CC renders ordered/enabled module definitions with live geometry,
and Settings opens as a separate normal desktop window with Appearance, Bar and
Control Centre pages. All edits use the accepted settings writer. See the
[implementation/test checkpoint](research/settings-application-checkpoint.md).

Automated settings/appearance/ownership/icon/window/layout tests and all 48
lifecycle steps pass. Production startup is clean: one 1920×1080 layer at `(0,0)`,
48px reservation, plus a normal Settings desktop client. Right-click the CC bar
trigger or use `quickshell ipc -c magi call settingsWindow open`. The operator confirmed window manipulation, all pages and the requested live
configuration/persistence/detail-navigation checks. Post-review logs are clean,
settings are saved and the 48px baseline remains unchanged. Further feature work
awaits a separate instruction.

## S1/S2 configuration and appearance foundation — 2026-09-27

Implemented and validated: schema v2, chained pre-schema migration, one atomic settings
writer, reset/validation/live notifications, stable module sessions independent
of bar placement, ten data-defined palettes and semantic roundness. Catppuccin
Mocha is the live default/reference. RenderTokens now holds geometry/typography;
render-sampled colors are no longer the production palette source.

[Implementation and validation record](research/settings-foundation-checkpoint.md)
contains the migration backup, exact files, tests, runtime evidence and limits.
The [approved architecture](design/settings-architecture.md) and
[schema example](design/settings-schema-v1.example.json) also describe future
work: icon registry, configurable CC composition and the normal Settings window.
This paragraph records the earlier S1/S2 checkpoint. Semantic icons, configured
CC, Settings, profile and MPRIS are now implemented in the newer checkpoints.

Final regressions passed: settings, appearance, module ownership and 48 lifecycle
steps. qmllint exits 0 with documented metadata/unqualified warnings. The live
combined shell has one 1920×1080 layer at `(0,0)` and exactly 48px reservation;
startup and bounded module-switch logs are clean. No new pointer/fullscreen,
real network/password, multi-output or fractional-scale acceptance is claimed.

## Literal-render reference checkpoint — 2026-09-26

The accepted shared-surface architecture is frozen. The
[measured visual specification](design/render-visual-specification.md) records
source-image dimensions/colors, explicit logical-pixel adaptations and exact
pre-pass mismatches. Control Centre now implements the supported reference
subset using scoped RenderTokens, icon-only colored tiles, dark icon-on-slider
controls and an unboxed power summary. Other detail views retain their styling.

Static checks and the expanded 44-step lifecycle/geometry regression pass;
startup retains one layer and 48px reservation with clean logs. The supplied
CC screenshot shows the reference tile/slider treatment, and the operator
confirmed compact-height restoration after Wi-Fi/Bluetooth detail navigation.
This is bounded geometry confirmation, not blanket visual approval. Missing custom icon assets and
unimplemented profile/media/action modules prevent full literal reproduction;
no empty placeholders or new services were added.

## Shared composition review — 2026-09-26

The right status cluster now expands as one `SharedStatusSurface`, with
persistent plugin-owned status visuals and body Components. Internal view
navigation replaces per-plugin collapse/reopen in combined mode. Volume is
icon-only; Battery carries percentage; Control Centre sliders place icons over
the tracks. The anchored fallback remains selectable.

The operator confirmed the shared-cluster visual model, then reported a
collapse/reopen stall. Its binding-order fix passes a 41-step offscreen
real-component regression. The operator subsequently passed full collapse,
repeated/rapid Control Centre reopening, and Control Centre → Bluetooth detail
→ Back without surface collapse. This **bounded structural checkpoint is accepted**;
full focus/fullscreen/password-flow regression remains separate.
Startup, logs and the one-layer/48px compositor baseline passed; those checks
are not proof of transition, focus or network-flow equivalence. See
[the design correction and checkpoint](design/shared-status-surface.md).

## Prior accepted production checkpoint

Updated **2026-09-26** from repository HEAD
`35c282012f2d749081a3f8b1821f01bf0b8aa6ea` plus the current uncommitted
integration work.

- The combined same-surface host is selected in `shell.qml`. MAGI owns one
  output-local full-height top-layer surface and reserves exactly 48 logical
  pixels. Bar, selected menu and consuming dismissal catcher share one native
  input Region.
- The anchored PopupWindow/TransformWatcher implementation remains selectable
  as rollback. It is not the design target for new plugins.
- Volume, Wi-Fi, Bluetooth and Control Centre are real configurable
  ExpandablePlugin entries. The former inline Settings/Controls demonstrations
  are removed from production placement.
- The right-side order is Volume, Wi-Fi, conditional Bluetooth, Battery and
  Control Centre. Bluetooth hides while disconnected but remains reachable
  through Control Centre.
- Shared services now cover Network, PipeWire audio, BlueZ Bluetooth,
  brightnessctl-backed brightness, UPower battery, Settings and semantic menu
  selection.
- Wi-Fi browsing uses the combined host while password entry remains a
  separate OnDemand PanelWindow. The operator passed scanning, radio,
  known/open/PSK connections, masked entry, Enter/Connect/Cancel, error/retry,
  successful connection and scanning handoff.
- On the tested eDP-1 scale-2 session, every checkpoint retained one
  1920x1080 combined MAGI layer at `(0,0)` and reservation
  `[0,48,0,0]`. Multi-output and fractional-scale behavior remain untested.

See [Architecture](architecture.md) for current ownership and
[the migration record](research/combined-surface-migration-plan.md) for
checkpoint evidence.

## Verified installed environment

Verified locally on 2026-09-24 with `pacman -Q`, `quickshell --version` and
`Hyprland --version`:

| Component | Installed version |
| --- | --- |
| Quickshell | 0.3.1; Arch package 0.3.1-1; binary revision blank |
| Hyprland | 0.56.2; Arch package 0.56.2-3 |
| Hyprland commit | `efb50993780079460b0cbed1363e2166a2de1d9f` |
| Qt base | 6.11.2-3 |
| Qt declarative | 6.11.2-2 |

These identify installed software, not the binaries loaded by an existing
session. API research must target Quickshell 0.3.1 and account for this Qt
and Hyprland environment.

## Documentation

- [Architecture](architecture.md): current structure and proposed concerns.
- [Quickshell reference](quickshell-reference.md): version-specific evidence.
- [Decisions](decisions.md): implementation history and preservation rules.
- [Local audit](research/local-audit.md): findings and unanswered questions.
- [Research index](research/README.md): completed and planned investigations.
- [Quickshell windows/lifecycle](research/quickshell-windows-and-lifecycle.md):
  phase-1 API research, proposed lifecycle and pending tests.
- [K4](research/k4.md) and [Serpantinum](research/serpantinum.md): phase-2A
  pinned source investigations, including a neutral surface comparison.
- [Combined-surface experiment](research/architecture-experiment.md): isolated
  fixture design, measurements and completed host-validation results.
- [Render architecture requirements](design/render-architecture-requirements.md):
  architecture-relevant visual and interaction direction from the current
  MAGI render; it is not a styling specification.
- [Combined-surface migration plan](research/combined-surface-migration-plan.md):
  production invariants, ownership, staged checkpoints and rollback paths.
- [Profile/media/icon checkpoint](research/profile-media-icons-checkpoint.md):
  schema v2, managed assets, real MPRIS, runtime and operator evidence.
- `tasks/`: intended location for bounded research and implementation tasks.

## Historical next steps (before Notifications milestone)

1. Plan the next Control Centre content/interaction step from the accepted
   profile/media composition; defer subjective UI/morph work.
2. Validate multi-output association, hotplug and fractional scaling.
3. Add explicit Bluetooth pairing-agent UX only after its prompt/security
   lifecycle is designed.
4. Consider Wi-Fi timeout, enterprise-security and adapter-failover work as
   separate Network-service changes with real connection tests.
5. Continue Noctalia **v4**, Lucid and Caelestia investigations when external
   research resumes.

The initial audit and external-project reports remain historical evidence.
Record new source/API findings, runtime measurements and compatibility limits
without rewriting historical results.

Supplementary references retained for later evaluation:
[Quickshell Book](https://github.com/programmersd21/the_quickshell_book) and
[Tony's tutorial](https://tonybtw.com/tutorial/quickshell/).


## Settings Phase 2A — native review pending

All eleven Settings pages now share page/control foundations, responsive rows and scrolling navigation. Automated production UI, persistence, Theme Orchestrator and 48-step shared-surface regressions pass. Operator state is unchanged; no commit/push or shell-surface redesign. See [exact changes, evidence and native checklist](design/settings-phase2a.md).


## Settings Phase 2A.1 — composition review pending

Phase 2A foundations are accepted. Settings now has flat navigation, compact styled controls, composed Control Centre/Icons/Launcher pages and quiet save feedback. Focused tests and software renders across five palettes pass; native operator screenshots remain the acceptance checkpoint. See [changes and evidence](design/settings-phase2a1.md).


## Settings Phase 2A.2 — native interaction review pending

The accepted uncommitted composition is retained. Control Centre now supports handle-based ordering; Bar has responsive Left/Centre/Right lanes plus Available. Shared Settings-only drag previews, keyboard alternatives and existing canonical writers preserve configuration semantics. Focused production interaction and existing regression checks pass; protected operator state is unchanged. See [implementation, exact paths and native checklist](design/settings-phase2a2.md). No commit/push or Phase 2B work.


## Settings Phase 2A.3 — final native review pending

Accepted Settings and drag foundations are retained. Sidebar selection is marker-only; Control Centre uses compact configured rows and Available while retaining disabled records; application-theme rows disclose healthy detail; unhandled Escape closes Settings. Existing Hyprland Super+Q is retained. Focused checks pass and all protected operator records match. See [exact changes, evidence and future Wallpaper direction](design/settings-phase2a3.md). No commit/push or Phase 2B implementation.


Phase 2A.3 native review is accepted apart from the final application-theme status refinement. Collapsed rows now use short, single-line labels; full diagnostics remain in details and errors/setup failures stay visible. Final operator review remains pending.


## Runtime visual Phase 2B — native operator review pending

From committed Settings baseline `7afd1c6`, Bar optional utilities, workspace roundness, Control Centre/profile/media composition and Wi-Fi/Bluetooth presentation are updated. Existing hosts, services, catalogue and 48px reservation remain. Focused automated checks pass; native clipping, palette, positioning and input acceptance remain pending. No commit/push. See [checkpoint, exact paths and native checklist](design/runtime-phase2b.md).


Phase 2B native-feedback correction restores configured primary tile accents, rounded-square avatars and bare slider icons. Shared artwork now masks inside the frame and uses a smooth alpha threshold. Relevant regressions pass; native edge review remains pending. [Corrective paths and validation](design/runtime-phase2b.md#native-feedback-corrective-pass--2026-10-17).


Phase 2B appearance follow-up adds accent-derived primary icon ink, bounded Control Centre appearance controls (schema 11), and a pinned preview of the real runtime surface. No commit/push; native review remains pending. [Appearance/preview checkpoint](design/runtime-phase2b.md#control-centre-appearance-and-pinned-preview--2026-10-17).


Phase 2B live tuning now preserves the Settings-session preview across every page, with a compact global close affordance. Primary accent tone/shade/strength edits no longer snap through a contrast search. Accepted schema 11 geometry/masking/sliders remain. [Live-tuning checkpoint](design/runtime-phase2b.md#settings-session-live-tuning-correction--2026-10-17).


The operator selected 7afd1c6 as the exact primary Control Centre colour reference. The old controlInk/stateColor path is restored; HSL primaryIconInk is removed. Size/roundness, masking and Settings-wide preview remain. [Exact colour restoration checkpoint](design/runtime-phase2b.md#exact-7afd1c6-colour-restoration--2026-10-17).


Final Phase 2B tuning adds three independent profile font sizes and four explicit section gaps under Control Centre → Appearance. Schema 11 is retained; restored colours and Settings-wide preview are unchanged. [Final tuning checkpoint](design/runtime-phase2b.md#final-profile-typography-and-section-gap-tuning--2026-10-17).


Phase 2B native acceptance is complete. Bar / Control Centre / Profile / Network,
restored 7afd1c6 colour semantics, Settings-wide preview, and final Schema 11
typography/spacing controls form the accepted baseline. Operator-tuned settings
and runtime integrations remain local and excluded from the source commit.
[Accepted checkpoint and path allowlist](design/runtime-phase2b.md#native-acceptance-and-source-checkpoint).


## Phase 9B resume-input investigation — paused

The failed production resume remains under investigation; no input-acceptance
change or visual rollback is made. Bounded, opt-in development diagnostics and
NativeInput ordering characterizations preserve fail-secure readiness. Installed
0.1.0-2 remains untouched; host IPC validation and operator review are required
before another live test. See [evidence, protocol findings and recovery plan](design/lock-screen-phase9-resume-input-investigation.md).


Phase 9 resume compatibility follow-up implements a fixed two-event, 100 ms
early-input slot, authoritative-modifier replay, lifetime invalidation and explicit
unknown Caps state. Full host validation and audited 0.1.0-3 packaging remain
pending; installed 0.1.0-2 is unchanged. No live test or finalization is authorized
by implementation alone. [Fix and validation checkpoint](design/lock-screen-phase9-resume-input-investigation.md#compatibility-fix-implementation--awaiting-host-validation).

### Phase 9 production acceptance (2026-10-19)

Installed magi-lock 0.1.0-3 passed operator-approved normal dual-output lock and
single suspend/resume acceptance, including correct input and clean display return.
Accepted visuals and native security boundaries remain intact. The bounded
early-key compatibility fix and 37-path final allowlist are documented in the
Phase 9 visual and resume-input checkpoints. Host offline validation is complete;
final post-suspend host health verification passed; repository finalization is authorized.
