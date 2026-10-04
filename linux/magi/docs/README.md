# MAGI — Research and Development

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

Separate milestones: first-party Emoji Picker; status-bar Calendar/date panel;
MAGI lock screen replacing Hyprlock only after security review; broader Control
Centre actions; and a later whole-shell Settings/visual/composition pass.
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
is exactly48px. See the
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
Latest runtime retains one1920×1080 main layer and exactly48px reservation. The
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
