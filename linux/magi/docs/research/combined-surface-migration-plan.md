# Combined-surface production migration plan

Prepared **2026-09-25**. This is an implementation plan, not an implementation
record. Live MAGI QML has not been changed by this plan.

It reconciles the validated
[combined-host experiment](architecture-experiment.md), the
[render-derived architecture requirements](../design/render-architecture-requirements.md)
and the current source under `.config/quickshell/magi/`. Paths in source
references below are relative to that live shell directory unless stated
otherwise.

## Evidence and status

### Verified current behavior

- `components/bar/Bar.qml:15-28` owns MAGI's present 48px top PanelWindow.
  Its explicit registry at `Bar.qml:47-90` and three Settings-driven Rows at
  `Bar.qml:96-258` provide configurable placement.
- `components/bar/ExpandablePlugin.qml:21-27` already accepts collapsed width,
  expanded width, menu height and a Component-valued menu body. It owns the
  seven-phase animation at lines 53-247 and the pill click at lines 253-275.
- The anchored popup baseline uses TransformWatcher, window-relative
  `mapFromItem()` coordinates and `PopupAdjustment.None` at
  `ExpandablePlugin.qml:330-379`. Its content Loader begins at line 397.
- `services/MenuController.qml:10-29` stores one requested menu ID and provides
  toggle/open/close operations. It does not own native windows, Item
  references, animation phases or plugin state.
- Wi-Fi keeps selection and connection UI state in
  `plugins/bar/wifi/Wifi.qml:13-92`, a 300x350 scrolling selector at lines
  182-435, and a separate keyboard-focused password PanelWindow at lines
  479-623. The password window uses `ExclusionMode.Ignore` and
  `WlrKeyboardFocus.OnDemand`; it is outside the expandable-host migration.
- The isolated fixture validated same-surface geometry, all six interruptible
  transition phases plus open state, OnDemand focus, consumed outside-click
  dismissal, sibling switching, fullscreen hiding/restoration and an explicit
  fixed 48px reservation on the installed Quickshell 0.3.1 / Hyprland 0.56.2
  single-output scale-2 session. Exact measurements and limits are in
  `docs/research/architecture-experiment.md`.

### Product requirements

The render establishes the intended compact-pill composition, variable-width
collapsed states, right-side status modules, dedicated transient menus,
larger Control Centre, bounded lists and icon/header continuity. These are
requirements supplied by the user, not behavior verified in current MAGI.

### Proposed behavior

Everything below that describes new production components, interfaces,
migration order or rollback is a design proposal until its checkpoint is
implemented and tested. Multi-output and fractional-scale behavior remain
unverified locally.

## Non-negotiable production invariants

1. **Production coordinate origin.** The combined surface is MAGI's sole
   reservation owner and begins at each output's top edge. The experiment's
   compositor `y=48` existed only because live MAGI was also running; no such
   outer offset or margin may enter production. Within the surface, bar and
   pill coordinates remain window-local.
2. **Exclusive zone.** Combined mode reserves exactly 48 logical pixels.
   Selected-menu height, animation phase, content size, Region geometry and
   dismissal-catcher state never change that reservation.
3. **Fallback geometry.** Anchored fallback retains the present 48px native
   bar plus the TransformWatcher, rounded window-relative mapping and
   `PopupAdjustment.None` behavior unchanged until the migration is accepted
   and a separate decision removes it.
4. **One native host.** For a plugin, only the host selected for the current
   run may render, accept pointer input, request focus or load interactive
   content. Production must not copy the fixture's always-instantiated pair of
   host adapters.
5. **Collapsed-width flexibility.** ExpandablePlugin cannot assume that every
   collapsed plugin is permanently 28px wide. A plugin may change its compact
   width and content with state, including a wider connected-Bluetooth state,
   without changing host architecture.
6. **Menu-size flexibility.** Each plugin supplies its expanded width and
   height. The common lifecycle and host must support small Volume, bounded
   Wi-Fi/Bluetooth and larger Control Centre content without fixed fixture
   dimensions.
7. **Visual continuity.** Host ownership cannot prevent the plugin's
   icon/header from remaining visually continuous from compact pill through
   horizontal widening and vertical menu reveal. The common host must not
   impose a second, unrelated header.

The existing motion contract also remains fixed: opening is 180ms widening,
then 140ms reveal with a concurrent 90ms fade; closing is 70ms fade, 120ms
retract and 160ms narrowing, all with current-value interruption and
retargeting. OnDemand focus, consumed outside-click dismissal, fullscreen
hiding/restoration and one interactive menu are production gates.

## Architecture review against the render

### Compatible parts

- The explicit registry and left/centre/right arrays already support the
  render's independent placement. They should be extended with new IDs rather
  than replaced by filesystem discovery.
- ExpandablePlugin's width/height inputs already express different menu sizes,
  and its widening affects Row layout. The combined host can retain this
  behavior.
- Keeping the pill/header in ExpandablePlugin while revealing menu content
  beneath it supports the required visual origin in both combined and
  anchored modes. It avoids trying to reparent one QML Item across native
  windows.
- A per-plugin Component body fits dedicated Wi-Fi, Bluetooth and Volume menus
  and a larger modular Control Centre. The host does not need to understand
  their internal modules.
- Wi-Fi's existing Flickable/list pattern demonstrates bounded scrolling that
  can move into plugin-owned menu content later without changing service or
  password-window ownership.

### Contradictions to resolve before real plugin migration

1. **The current pill presentation is too rigid.** ExpandablePlugin hardcodes
   a single Text at `ExpandablePlugin.qml:253-269`, changes it from icon to
   title based only on phase, and fixes height to 28. Although
   `collapsedWidth` is a property, runtime changes after an animation are not
   an established contract. This conflicts with richer, variable-width
   Bluetooth and icon/header continuity. Add plugin-owned compact/header
   content slots and explicitly synchronize or animate a changed collapsed
   width while closed before migrating real plugins.
2. **A universal visual MenuContentFrame would be wrong.** The earlier
   structure proposed that name, but a frame that supplies a standard header
   would duplicate or break the render's pill/header continuity. If retained,
   it may provide only clipping, padding and lifecycle plumbing; plugin visuals
   stay in ExpandablePlugin and the menu Component.
3. **The fixture instantiates both adapters.**
   `experiments/bar-surface/ExpandablePill.qml:280-315` creates anchored and
   combined hosts and disables
   one. That was useful for a fair fixture, but it conflicts with the
   one-native-host invariant. Production needs a selector whose inactive
   Component is not instantiated.
4. **Fixture coordinates are coexistence coordinates.** The measured
   full-height experiment layer began below live MAGI at compositor `y=48`.
   Copying that geometry would put the production surface and its Region one
   bar too low. Production starts at output `y=0`, with its bar strip occupying
   local `y=0..48`.
5. **Fixture menu sizes are examples.** Its 220x180 and 220x260 sizes verify
   host flexibility but are not production constants. Size comes from each
   plugin and bounded lists scroll inside it.
6. **Current Bar contains inline test menus.** `Bar.qml:162-242` bypasses the
   registry. They must not become the template for Control Centre or status
   modules; production expandable plugins belong in the same registry and
   placement lists as other bar items.
7. **Current Wi-Fi owns its selector window.** Moving that selector content
   too early would combine service, content and host changes. Its real network
   flow and separate password window remain intact until host behavior has
   passed with dummy and lower-risk production content.

There is no architectural contradiction between variable menu sizes and a
single combined surface. There is also no conflict between fixed 48px
reservation and tall menus because visual height and exclusive zone are
separate. The unresolved risks are the compact/header API, dynamic collapsed
width after interrupted animation, output association, and exact content
lifetime during host selection.

## Proposed production structure

```text
.config/quickshell/magi/
├── components/bar/
│   ├── Bar.qml
│   ├── ExpandablePlugin.qml
│   └── menu/
│       ├── MenuHostSelector.qml
│       ├── AnchoredPopupHost.qml
│       ├── CombinedMenuHost.qml
│       └── MenuContentFrame.qml
├── plugins/bar/
│   ├── controlcentre/
│   │   ├── ControlCentre.qml
│   │   └── ControlCentreMenuContent.qml
│   ├── wifi/
│   │   ├── Wifi.qml
│   │   ├── WifiMenuContent.qml
│   │   └── WifiPasswordWindow.qml
│   ├── bluetooth/
│   │   ├── Bluetooth.qml
│   │   └── BluetoothMenuContent.qml
│   └── volume/
│       ├── Volume.qml
│       └── VolumeMenuContent.qml
└── services/
    └── MenuController.qml
```

This is a responsibility map, not permission to create every file at once.
Files are introduced only in the step that needs them. `MenuContentFrame.qml`
is optional; omit it if the two hosts can share lifecycle plumbing without a
visual wrapper. It must not own plugin headers or fixed menu dimensions.

### State and lifecycle ownership

| Concern | Production owner | Contract |
| --- | --- | --- |
| Requested menu | MenuController | Stores one semantic menu ID and request generation; exposes open/toggle/close and close reason. No Item/window references. |
| Registry and placement | Bar | Keeps explicit ID-to-Component mapping and left/centre/right Settings arrays. Adds status/Control Centre IDs as they become real plugins. |
| Native combined surface | Bar | One top-edge PanelWindow per selected output; explicit `exclusiveZone: 48`; screen-height paint/input canvas; bar strip at local y=0. |
| Pill motion and header | ExpandablePlugin | Owns collapsed/expanded dimensions, seven phases, current-value retargeting, compact/header Components and their visual continuity. |
| Host selection | MenuHostSelector | Instantiates only combined or anchored adapter for the run. It does not choose menu state or alter animation values. |
| Expanded geometry/content | Selected host | Uses the pill's live origin, animated width, revealed height and content opacity; clips reveal and owns the menu Loader. |
| Menu content | Plugin | Supplies a Component, preferred initial-focus hook, content-first Escape/Enter behavior and bounded internal scrolling. It cannot change native reservation or Region. |
| Native input Region | Bar | Combines the 48px bar strip, selected revealed menu geometry and consuming catcher geometry. Removed/noninteractive shell state must not trap fullscreen clients. |
| Outside dismissal | Bar | Catcher lies below bar/pills/menu, exists only while a transient menu is requested, closes once and consumes the triggering pointer event. |
| Keyboard policy | Bar and selected host | Bar switches the native window between no focus while closed and OnDemand while an eligible menu is active; host requests focus in incoming content only after it is interactive. |
| Durable system state | Services | Scanning, devices, audio/network state and operations outlive menu views. Wi-Fi service migration is separate and requires its own equivalence tests. |
| Wi-Fi credentials | Separate password window | Retains current OnDemand keyboard-focused PanelWindow and connection/cancel/clear semantics throughout this host migration. |

### Plugin menu contract

Expandable production plugins should provide:

- a stable `menuId`;
- plugin-owned compact/header content;
- a collapsed-width value or binding that may change while closed;
- expanded width and menu height;
- a Component-valued menu body;
- an optional `requestInitialFocus()` entry point on loaded content; and
- content-first Enter/Escape handling, with unhandled Escape delegated to the
  host to close the menu.

The host supplies content bounds and current interactivity. Content must not
own PopupWindow/PanelWindow visibility, exclusive zones, the outside catcher
or global menu selection. The default lifecycle should retain each plugin's
loaded menu body while that production host is selected, matching the current
always-loaded behavior and the fixture's state-retention test. Later unloading
must be an explicit, separately tested optimization; service operations and
Wi-Fi connection observers cannot depend on a transient delegate surviving.

For visual continuity, the pill/header remains owned by ExpandablePlugin and
drawn above the menu reveal. The menu Component begins below that header. A
plugin may animate icon position, label visibility or richer compact content
from the same phase/progress values. No design requires moving one Item
between the bar and popup windows.

## Smallest safe migration sequence

Each step is independently reviewable. Do not begin the next step until the
checkpoint passes. The anchored implementation remains the rollback path
until the combined host has passed real-plugin equivalence.

### M0 — Freeze baselines and acceptance records

- Preserve the current source and the measured fixture report.
- Write a short manual acceptance checklist for existing bar placement,
  animation timings, Wi-Fi scan/list/connection/password flows and fullscreen
  behavior.

**Checkpoint:** current anchored bar and Wi-Fi behavior are recorded without
editing them. **Rollback:** documentation only.

### M1 — Extract the anchored adapter without changing behavior

- Move the present TransformWatcher/PopupWindow/Loader implementation into
  `menu/AnchoredPopupHost.qml` with the same bindings and adjustments.
- Route existing inline test menus through it. Keep Bar's current PanelWindow,
  exclusion mode, 48px height and placement unchanged.

**Checkpoint:** source diff shows geometry and timing equivalence; normal,
switching and interruption checks match the control. **Rollback:** restore the
inline block in ExpandablePlugin.

### M2 — Generalize the pill contract under anchored fallback

- Replace the hardcoded pill Text with plugin-supplied compact/header content
  while keeping the current icon/title behavior as the default.
- Make closed-state width updates explicit and interruption-safe. Exercise at
  least icon-only 28px, a wider connected-device state and two different menu
  dimensions.
- Keep plugin header visuals in ExpandablePlugin, above either host.

**Checkpoint:** variable collapsed width relayout, visual header continuity,
  all animation phases and anchored popup tracking pass. **Rollback:** select
  the default icon/title presentation and fixed width; anchored geometry is
  untouched.

### M3 — Add production host selection in dark mode

- Add MenuHostSelector and CombinedMenuHost, initially behind an internal
  development setting that defaults to anchored.
- Instantiate only the selected adapter. Keep identical pill animation and
  Component content inputs.
- Add Bar-owned Region, OnDemand and catcher plumbing without making it active
  in anchored mode.

**Checkpoint:** inactive host has no window, Loader, focus or input
  participation; anchored results remain unchanged; combined dummy content
  reproduces the fixture gates. **Rollback:** set selector to anchored and
  remove the inactive combined Component from the runtime path.

### M4 — Make the combined surface the sole bar/reservation owner

- Change Bar's production combined mode to a screen-height top/left/right
  PanelWindow starting at output top, with explicit `exclusiveZone: 48`.
- Place the 48px bar at local y=0. Build Region from bar, one selected menu and
  catcher only. Do not copy the experiment's coexistence offset.
- Preserve layer/fullscreen behavior demonstrated by the fixture.

**Checkpoint:** standalone reservation is exactly 48px in every menu phase;
  menu geometry follows all placement presets; mask pass-through, consumed
  dismissal, sibling switching, focus return and fullscreen recovery pass.
  Test each available output/scale. **Rollback:** choose anchored host and its
  native 48px Bar without changing TransformWatcher geometry.

### M5 — Migrate low-risk transient content

- Replace inline tests with one small production menu, preferably Volume,
  using plugin-owned sizes and header content.
- Add Control Centre only after the same contract handles a larger modular
  body. Keep internal modules independent of host/window logic.
- Add Bluetooth when its service and state model are separately reviewed;
  include the wider connected-device collapsed state and bounded device list.

**Checkpoint per plugin:** placement, sizing, focus/Escape, outside-click
  consumption, sibling switching, scroll bounds, interruption and fullscreen
  restore all pass. **Rollback:** remove that registry entry/menu binding while
  leaving other combined-host users intact.

### M6 — Migrate only the Wi-Fi selector content

- Separate the current selector body from Wifi.qml without changing Network
  calls, scan ownership, selected/pending/error state or row result handling.
- Supply the selector as bounded, scrollable WifiMenuContent to the shared
  host. Keep the password PanelWindow separate and unchanged.
- Verify known-profile, open-network and PSK/password paths, duplicate-attempt
  guards, scan handoff between selector/password views, retry/error feedback,
  cancellation, input clearing and focus restoration.

**Checkpoint:** the Wi-Fi acceptance checklist passes against real services,
  including password entry and failure paths. **Rollback:** restore the legacy
  selector PopupWindow while retaining the combined host for already-migrated
  plugins.

### M7 — Select combined mode by default

- Change the default only after every migrated plugin passes and cleanup
  leaves no legacy popup, duplicate focus owner or stale Region.
- Keep anchored mode available for one stabilization milestone and document
  the switch used to select it.

**Checkpoint:** cold start, shell reload, rapid switching, fullscreen recovery,
  output changes available on the machine, Wi-Fi, and cleanup all pass.
  **Rollback:** one configuration change returns the complete bar to the
  anchored adapter and native 48px geometry.

### M8 — Retire fallback only by a later decision

Remove TransformWatcher fallback only after combined mode has survived the
agreed stabilization period and remaining multi-output/fractional-scale tests.
This is not part of the initial migration approval.

## Production concepts versus fixture-only material

Promote these concepts:

- identical animation values feeding interchangeable host adapters;
- explicit fixed reservation independent of surface/menu height;
- Bar-owned Region and catcher with pills above the catcher;
- OnDemand only while menu content is eligible for focus;
- one requested menu and current-generation focus requests;
- plugin Component content and plugin-specific menu dimensions; and
- logging sufficient to diagnose phase, geometry, focus and close reason
  during migration.

Keep these test-only:

- environment-variable startup configuration;
- fake menus/status modules and TestMenuContent counters;
- experiment IPC placement/phase controls and snapshot format;
- simultaneous fixture/live-shell coexistence and its compositor y=48 offset;
- the fixture's two always-instantiated host objects; and
- the temporary 96px aggregate reservation caused by two shells.

The experiment source remains a regression fixture. Production should reuse
its demonstrated ownership rules, not import its components or test controls.

## Remaining questions before implementation

- What internal development setting should choose anchored versus combined
  during the stabilization milestone without exposing an unsupported public
  setting?
- Should a changed Bluetooth collapsed width snap or animate while its menu is
  closed? The architecture supports either; the render does not decide it.
- Which content state belongs in long-lived services versus retained menu
  objects for Control Centre and future Bluetooth? Wi-Fi connection observers
  are the highest-risk case.
- How should one Bar instance be created and associated per output if MAGI
  adopts multi-monitor support? Current MAGI creates one unassigned Bar, and
  the combined fixture was validated on one output only.
- Are menu dimensions fixed per plugin or constrained by available output
  geometry at runtime? Bounded lists are required, but edge/scale policy still
  needs tests on additional output configurations.

These questions do not block M1 or the API work in M2. Multi-output ownership
must be decided before claiming M4 production-complete, and Wi-Fi state
ownership must be decided before M6.
