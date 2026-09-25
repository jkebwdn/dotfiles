# MAGI anchored-popup versus combined-surface experiment

Prepared **2026-09-24**. Runtime record updated **2026-09-25** against the
working tree based on MAGI HEAD
`6aac5747e1332fe75755e2c899ac95dc265b5d84`. The isolated fixture now exists
under `experiments/bar-surface/`; the completed measurements and the remaining
unexecuted test are separated below from the earlier design proposal.

The agreed constraint is that MAGI keeps compositor-aware desktop reservation.
The experiment therefore compares:

- **A — anchored popup:** the existing 48px PanelWindow and one PopupWindow
  per expandable plugin.
- **B — combined surface:** one K4-inspired PanelWindow contains the bar,
  expanding pills and menu visuals, while reserving exactly 48 logical pixels
  at the top edge. Menu height never changes the exclusive zone.

Hyprland gaps are outside the experiment. They may remain a visual preference,
but are not the source of MAGI's bar reservation.

## Evidence classification

### Verified before this experiment

- MAGI's current bar is a top/left/right-anchored PanelWindow with
  `implicitHeight: 48` and automatic exclusion
  (`.config/quickshell/magi/components/bar/Bar.qml:15–27`).
- Its explicit component registry and Settings arrays place plugins in left,
  centre and right Rows (`Bar.qml:47–135`, `:250–258`).
- ExpandablePlugin exposes a Component-valued `menuContent` and owns a
  seven-phase, interruption-aware animation. Full opening is 180ms horizontal
  expansion followed by a 140ms vertical reveal and concurrent 90ms content
  fade. Closing is 70ms fade, 120ms retract and 160ms contraction
  (`ExpandablePlugin.qml:27–243`).
- Approach A positions each PopupWindow relative to the actual bar using
  TransformWatcher and `mapFromItem()`, with PopupAdjustment.None
  (`ExpandablePlugin.qml:330–379`). The user previously tested this positioning;
  this plan does not claim a new test result.
- Quickshell 0.3.1 separates a PanelWindow's visual dimensions from its
  exclusive zone, and a window mask controls pointer-receiving regions. Item
  clipping and opacity do not define the native input region. See
  [the phase-1 report](quickshell-windows-and-lifecycle.md#w07--painting-control-input-and-window-hit-regions-differ).
- K4 demonstrates a screen-sized layer surface containing compact and expanded
  content with an explicit bar-sized reservation. It also demonstrates that
  this choice couples geometry, masking, focus and dismissal
  ([K4 K01 and K04](k4.md#k01--compact-and-expanded-content-share-a-host-surface)).

These are source/API findings. They do not prove that B behaves correctly on
the installed Quickshell 0.3.1 and Hyprland 0.56.2.

### Historical design proposal

Approach B will use a top/left/right-anchored PanelWindow whose requested
height covers its selected output. It will set `exclusiveZone: 48` explicitly;
setting this also selects normal exclusion behavior. Three anchors are retained
because Quickshell documents that an exclusive zone requires one or three
anchors. The visual bar remains a 48px Item at the top.

The window's mask will normally combine only:

1. the 48px bar strip;
2. each currently revealed menu rectangle; and
3. an optional full-output dismissal catcher while a menu is open.

The large native surface must not imply a full-screen input region. The
catcher is a separately selected policy and must never be enabled merely
because the combined surface exists.

Each expandable plugin remains an Item in its configured Row. Its compact
height remains 28px; its animated width continues to affect Row layout and
move neighbouring plugins. Its menu is a clipped child drawn below the pill
inside the same PanelWindow, with width equal to the animated pill width and
height equal to `revealedHeight`. The Row must not include menu height in its
layout calculation.

The experiment preserves the existing animation state machine, durations,
easing and stop-and-retarget behavior. It changes only the expanded content's
surface ownership. The same Component-valued `menuContent` is loaded by both
hosts with the same 12px inset. Plugin content cannot set window visibility,
exclusive zones or focus policy.

The explicit registry and three placement arrays remain the composition
model. Two fake expandable plugins and three inert status plugins are enough
to exercise left/centre/right placement, sibling displacement and switching.
No real MAGI service or Wi-Fi component is imported.

This section records the proposal used to construct the fixture. It is not
runtime evidence. The verified subset and its limits are recorded under
**Measured runtime results**.

## Minimum isolated fixture

The approved fixture was created outside the live `.config/quickshell/magi/`
tree:

```text
experiments/bar-surface/
├── shell.qml                 # ShellRoot and selected test screen
├── ExperimentWindow.qml      # registry, placement Rows, fixed reservation,
│                             # input mask, coordinator and IPC test controls
├── ExpandablePill.qml        # unchanged animation core and pill presentation
├── AnchoredPopupHost.qml     # A: TransformWatcher + PopupWindow adapter
├── CombinedMenuHost.qml      # B: same-surface clipped menu adapter
└── TestMenuContent.qml       # TextInput, buttons, Flickable and event counters
```

This is the minimum fair A/B fixture: the registry, placement, content and
animation core are shared; only the host adapter changes. `ExperimentWindow`
accepts a startup mode of `anchored` or `combined`, but never creates both
hosts in one run. Running both would confound surface, focus and reservation
measurements.

The fixture must have its own Quickshell entry path, IPC target and layer-shell
namespace. It must not import MAGI singletons, read `settings.json`, invoke
system services, or use real plugin implementations. A small IPC surface is
enough to select a placement preset, toggle either test menu, choose
mask-only versus consuming-catcher dismissal, and print a state snapshot.
State snapshots go to stdout as one-line records; the fixture need not write
logs or settings.

Default startup is non-focusable, mask-only and `exclusiveZone: 0`. This safe
mode covers geometry and animation without adding a second reservation to the
live desktop. The fixed-reservation test is a deliberate, separate run with
`exclusiveZone: 48`; closing that fixture must restore the pre-test work area.
The working MAGI process is neither changed nor restarted.

## Instrumentation

Both modes must emit the same records:

- requested menu, rendered menu, phase and request generation;
- pill and menu x/y/width/height in window-local logical pixels;
- animation start, natural finish, interruption and current values;
- content construction/destruction and active-focus item;
- keyboard mode, input-mask mode, close reason and pointer target; and
- screen name, logical size and devicePixelRatio.

Record compositor state before launch, after launch with menus closed, during
full expansion, after closing and after fixture exit. Capture the selected
output's work area and layer surface geometry. A screen recording can support
visual review, but timestamps and geometry are the acceptance evidence.

## Measured runtime results — 2026-09-25

These results apply to **Quickshell 0.3.1** (Arch Linux package) and
**Hyprland 0.56.2**, commit
`efb50993780079460b0cbed1363e2166a2de1d9f`. The tested output was `eDP-1` at
3840×2160 physical pixels, 1920×1080 logical pixels and scale 2. Live MAGI was
left running as `quickshell -c magi` throughout.

The geometry, process, layer and reservation values below were measured from
fixture IPC snapshots, terminal event logs, `pgrep` and read-only `hyprctl`
queries. Pointer and keyboard behavior explicitly marked **operator-observed**
was manually tested by the user. No result in this section is inferred from a
screenshot.

### Anchored control — pass

The control used `MAGI_EXPERIMENT_MODE=anchored` and
`MAGI_EXPERIMENT_RESERVE=0`, with keyboard focus disabled and mask-only input.
The experiment created its own
`magi-bar-surface-experiment-anchored` layer at logical `y=48`, width 1920 and
height 48. Hyprland's existing top reservation remained 48 pixels, and the
live MAGI PID and layer remained present and responsive.

Menu one settled at window-local geometry `x=1596, y=38, 220×180`; menu two
settled at `x=1632, y=38, 220×260`. Each completed widen → reveal/fade → open
and fade → retract → narrow. Switching menu-one → menu-two → menu-one left one
correctly aligned active popup, with no blank frame, clipping or detached
geometry observed. Runtime output contained no QML, binding-loop, anchor,
surface or focus error. `Ctrl-C` removed only the fixture process and layer;
the work area remained at its 48-pixel baseline.

This verifies the basic default-placement control. It does not cover all
placement presets, rapid interruption in every animation phase, fractional
scale or multiple outputs.

### Combined surface with zero additional reservation — pass

The combined run used `MAGI_EXPERIMENT_MODE=combined` and
`MAGI_EXPERIMENT_RESERVE=0`. Hyprland reported a 1920×1080 experiment layer at
logical `y=48`, while its top reservation remained `[0, 48, 0, 0]`. Menu one
and menu two preserved the anchored control's 220×180 and 220×260 expanded
geometry, phase order and alignment. Normal open/close cycles and
menu-one → menu-two → menu-one switching produced no blank frames, clipping,
detachment or runtime error.

The implementation under test keeps bar, active menu and optional catcher as
explicit mask regions (`experiments/bar-surface/ExperimentWindow.qml:26–36`,
`:192–216`), while both hosts use the same animation and menu-content inputs
(`experiments/bar-surface/ExpandablePill.qml:17–37`, `:280–315`).

### Pointer mask pass-through — operator-observed pass

With the screen-height combined surface open and dismissal set to mask-only,
the user manually changed workspaces; clicked, focused, typed and scrolled in
unrelated Ghostty, Yazi and ChatGPT regions; launched applications; moved
between applications; used both pills; switched menus; and used the Count and
Close controls. Normal pointer interaction outside the explicit Region mask
was not blocked.

With keyboard focus deliberately disabled, clicking the menu TextInput left
keystrokes routed to the underlying application. That was the expected
pre-focus-test condition, not a combined-surface failure.

### OnDemand keyboard focus — operator-observed pass

The existing IPC flag enabled `WlrKeyboardFocus.OnDemand` only while a menu
was active (`experiments/bar-surface/ExperimentWindow.qml:198–202`,
`:226–251`). No focus architecture was changed. The user confirmed:

- TextInput received typed input;
- text persisted while switching between menus;
- Escape with text present cleared the field and kept the menu open;
- Escape with an empty field closed the menu;
- Enter was handled by menu content; and
- after menu closure, keyboard input returned to the previously selected
  application.

Logs recorded accepted initial-focus requests, active-focus changes during
switching, `content-enter` events and focus loss on closure. The content-first
Enter/Escape behavior exercised here is implemented in
`experiments/bar-surface/TestMenuContent.qml:20–31`, `:52–77`. No QML,
binding-loop, surface or focus error was observed.

### Explicit 48px reservation — measured pass

The final completed run used combined mode, OnDemand keyboard focus,
mask-only dismissal and `MAGI_EXPERIMENT_RESERVE=1`. Because live MAGI already
reserved 48 pixels, the fixture was expected to add a temporary second
reservation. Measurements were:

| State | Hyprland top reservation | Tiled Ghostty vertical geometry |
| --- | ---: | --- |
| Before fixture | 48px | `y=56`, height `1002` |
| Fixture open, menus closed | 96px | `y=104`, height `954` |
| Menu one open, 220×180 | 96px | `y=104`, height `954` |
| Menu two open, 220×260 | 96px | `y=104`, height `954` |
| Menus closed again | 96px | `y=104`, height `954` |
| After `Ctrl-C` | 48px | `y=56`, height `1002` |

The fixture therefore contributed exactly 48 logical pixels, and neither menu
height nor animation phase changed the exclusive zone. After exit, its PID,
namespace and IPC target disappeared; live MAGI remained the only Quickshell
process and its original layer and reservation were unchanged. The independent
SwayNC notification layer was present during some cleanup snapshots and is not
part of either shell.

These results verify the basic anchored control, combined geometry, explicit
mask pass-through, OnDemand focus and fixed reservation on the installed
single-output scale-2 runtime. They do not select the combined architecture by
themselves. Fullscreen behavior, the consuming catcher, broader placement,
multiple outputs, fractional scale and phase-by-phase interruption remain
open.

## Final bounded host test — prepared, not run

Nothing in this section is a test result. Run it only after separate approval,
using the existing isolated fixture. Do not edit live MAGI QML, add Hyprland
rules or restart either shell.

### Fixed setup

1. Record live MAGI's PID/layer, `hyprctl monitors -j`, `hyprctl layers -j`
   and the chosen client's normal tiled geometry.
2. Start only:

   ```bash
   MAGI_EXPERIMENT_MODE=combined MAGI_EXPERIMENT_RESERVE=1 \
     quickshell -p /home/jkebwdn/dotfiles/linux/magi/experiments/bar-surface/shell.qml
   ```

3. Enable the fixture's existing OnDemand flag through its IPC `keyboard true`
   method and explicitly retain `dismissal mask-only`. Confirm the snapshot
   reports combined host, reservation 48, keyboard enabled and mask-only
   dismissal.
4. Use an existing noncritical client and its normal fullscreen action. Do not
   issue `hyprctl keyword`, edit Hyprland configuration or add window rules.

The live-session reservation is expected to measure 96px because both MAGI
and the fixture reserve the same edge. Record that known double-reservation
constraint rather than treating it as standalone production geometry.

### A. Fullscreen stacking and mask-only dismissal

1. With the client tiled, record fixture-closed, menu-one-open and closed-again
   layer geometry and reservation.
2. Make the client compositor-fullscreen and record whether the live bar,
   experiment bar and expanded menu are visible, occluded or placed above the
   client. This is an observation; either stacking policy may require a later
   product decision.
3. Open menu one. Click and scroll in the fullscreen client outside the bar and
   menu. **Expected mask-only behavior:** the client receives input and the
   menu remains open because no outside-dismissal region is active.
4. Close by Escape, content Close and the active pill in separate cycles.
   Confirm focus returns to the fullscreen client and the reservation remains
   constant.

Stop immediately if an invisible part of the full-height surface blocks the
client, the menu traps keyboard focus after closing, or fullscreen changes the
exclusive zone.

### B. Switching between pills while open

In tiled and fullscreen states, run menu-one → menu-two → menu-one using the
bar pills. Record request generation, phase changes, focus changes and final
geometry. Verify that the outgoing content loses focus, the incoming content
accepts focus, exactly one menu remains interactive, the active Region follows
the new menu, and no blank frame, clipped content or detached geometry appears.

### C. Optional consuming catcher

Only after mask-only passes, use the existing IPC method to set
`dismissal consume`; do not change QML. Test this as a separate policy:

1. Open each menu and click once in the client outside the bar/menu. The
   catcher should consume that click and close exactly once; the client must
   not also act on it.
2. Reopen a menu and click the sibling pill. Because the bar is above the
   catcher in the fixture
   (`experiments/bar-surface/ExperimentWindow.qml:254–262`), record whether
   the click switches directly, closes without switching, or is incorrectly
   consumed. Do not infer the outcome in advance.
3. Repeat the outside-click and pill-switch checks over the fullscreen client.
   Reject this policy if it creates an invisible blocker, ambiguous double
   activation or a focus trap.
4. Restore `dismissal mask-only` through IPC before cleanup.

### D. Cleanup and evidence

Exit fullscreen, close the menu and stop the fixture with `Ctrl-C`. Confirm
that the experiment process, namespace, IPC target, keyboard eligibility and
extra 48px reservation disappear; the client returns to its baseline vertical
geometry; and live MAGI remains responsive. Preserve fixture status records,
relevant lifecycle logs and read-only compositor snapshots. Report operator
observations separately from command-measured geometry.

## Original test matrix

This matrix remains as the broader experiment backlog. The default-placement
parts of sections 1–2, the normal switching path in section 3, mask-only input
in section 4, section 5 and section 6 have the measured coverage recorded
above. Catcher and fullscreen coverage is limited to the prepared final host
test. Broader placement, interruption, monitor and scale cases remain unrun.

Run A first as the control, then B with the same screen, placement preset,
content and input policy. Do not change animation parameters between runs.

### 1. Preflight and control

1. Record installed Quickshell/Hyprland versions, selected output geometry,
   scale, current work area and relevant layer surfaces.
2. Start the fixture in A/mask-only/zero-additional-reservation mode.
3. Confirm its bar and menus are independent of the live MAGI configuration.
4. Exercise one complete open/close and save the event/geometry record.

**Runtime proof required:** the dedicated process and namespace do not replace,
reload or send IPC to the working shell.

### 2. Placement and geometry

For both A and B, test presets with expandable pills in left, centre and right
Rows, and with two expandable pills adjacent in the right Row.

- Open each menu after neighbouring pill widths have changed.
- Switch menu-one → menu-two → menu-one between the two fake menus.
- Test near the left/right screen edges and with a menu taller than its normal
  180px test size.
- If a second output or fractional scale is available, repeat there without
  multiplying coordinates by devicePixelRatio.

**Pass:** pill placement follows the selected arrays; horizontal expansion
moves siblings consistently; the menu remains attached to its pill; vertical
growth does not change Row height or the 48px bar location; no content is
clipped by the native surface. Differences in seam rounding between A and B
are recorded rather than hidden.

### 3. Animation continuity and interruption

For both modes, issue close, reopen and sibling-switch requests during every
phase: widening, reveal/fade, open, fade-out, retract and narrowing. Include
same-frame repeated requests and menu-one → menu-two → menu-one switching.

**Pass:** the latest request wins; all transitions start from current values;
there is no jump to a default size, blank menu, stale completion, orphaned
input region or wrong final phase. B must preserve the established sequence
and timings before any alternative concurrent morph is considered.

### 4. Input regions and dismissal

Test with a pointer-event counter in the application beneath the fixture.

1. Closed, mask-only: click bar controls, transparent space below the bar and
   unrelated desktop/application regions.
2. Open, mask-only: click inside the pill, menu, transparent rounded corners
   and outside the menu.
3. Open, consuming catcher: repeat outside clicks, including blank bar and the
   sibling pill.
4. Start a press inside a button or Flickable, drag outside, then release.
5. Close during a press and during content fade-out.

**Pass:** B never acts like a full-screen blocker in mask-only mode; menu and
bar regions receive their intended events; transparent areas follow the
documented policy; the catcher closes exactly once and its consumption is
recorded; fading/closed controls are not actionable. Sibling-pill behavior is
an explicit result, not inferred from K4.

### 5. Keyboard focus and Escape

Use TestMenuContent's TextInput and buttons. Compare None while closed with
OnDemand while a keyboard-requiring menu is open; do not add Exclusive or a
HyprlandFocusGrab in the first fixture.

- Open by pointer and IPC; type, Tab/Shift-Tab, press Enter and Escape.
- Switch menus while the TextInput has focus.
- Dismiss by pointer, then type into the previously focused application.
- Repeat rapid close/reopen and ensure delayed focus work cannot target the
  previous generation.

**Pass:** closed menus do not receive keys; requested content receives input;
Escape follows content-first handling and then host close; focus does not
remain on hidden content; the previous/selected application can receive keys
after dismissal. Failure of OnDemand is a recorded result and a reason for a
later bounded focus variant, not permission to change live MAGI.

### 6. Fixed desktop reservation

Use a normal tiled test window and record its geometry. Run B with its explicit
48px reservation while the live shell remains untouched. Because live MAGI
already reserves its bar, the fixture may add a temporary second reservation;
measure the delta rather than treating it as B's standalone work area.

Record tiled-window/work-area geometry with B closed, opening, fully open,
closing and after fixture exit.

**Pass:** the compositor observes the fixture's explicit 48px reservation and
the work area remains constant throughout menu animation; menu height never
enters the exclusive zone; exiting the fixture restores the baseline. Two
surfaces reserving the same edge may prevent the live-session delta from
representing B's standalone 48px contribution. If so, record that limitation
and repeat later in a separate or already-available nested Wayland session.
Do not install a nested compositor for this test.

### 7. Fullscreen behavior

With no Hyprland rule changes, open a client in compositor fullscreen and
repeat closed/open/close for B in mask-only and catcher modes.

**Pass:** no invisible part of the screen-sized surface captures input;
reservation returns unchanged after leaving fullscreen; observed bar/menu
visibility and stacking are recorded. Whether the bar should appear above a
fullscreen client is a product decision after this test, not an assumed pass
condition. The consuming catcher must not be accepted if it makes fullscreen
interaction ambiguous or traps focus.

### 8. Cleanup and comparison

Stop only the experiment process. Confirm its layer surface, reservation,
keyboard eligibility and IPC target disappear, the work area returns to the
preflight value, and the live MAGI shell remains responsive.

Compare A and B using event logs and geometry under identical scenarios:

| Decision input | A | B viability gate |
| --- | --- | --- |
| Attachment | Existing window-relative mapping is the baseline. | Same-surface menu stays aligned in every placement and scale tested. |
| Motion | Existing phase sequence and interruption behavior. | Same sequence/timings with no new jump or blank frame. |
| Reservation | Bar reserves 48px independently of popup height. | Explicit 48px contribution remains constant for every menu phase. |
| Input | Separate popup and bar regions. | Full-height surface is harmless outside the explicit mask. |
| Focus/dismissal | Generic policy remains unresolved. | OnDemand/Escape passed; mask-only pass-through passed; consuming catcher remains untested. |
| Maintenance | Per-plugin windows retain proven geometry. | One host can retain registry, placement and Component interface without plugin-specific window logic. |

B is a viable architecture candidate only if it passes the geometry,
interruption, mask and reservation gates. Focus or fullscreen failures may
justify one further isolated variant, but they must not be papered over with
live compositor rules. The experiment does not select B automatically; A
remains the working fallback and comparison control.

## Runtime questions and current status

Resolved on the tested Hyprland 0.56.2 session:

- A screen-height top/left/right PanelWindow with `exclusiveZone: 48`
  contributed exactly 48 logical pixels while using a smaller explicit mask.
- OnDemand delivered focus to the dummy TextInput, supported content-first
  Escape handling and returned input to the prior application after closure.
- The zero-reservation screen-height surface did not block pointer interaction
  outside its mask.

Still open or only partially covered:

- No blank frame, clipping or detachment was observed in normal A/B cycles,
  but the experiment did not quantify whether B improves seam or frame
  continuity over A.
- Fullscreen stacking, visibility and input routing await the prepared final
  host test.
- The optional consuming catcher and its interaction with sibling pills await
  the prepared final host test.
- Fractional-scale rounding, additional outputs, all placement presets and
  interruption during every animation phase remain untested.

Wi-Fi, real services, dynamic plugin discovery, content unloading, per-output
menu arbitration and alternative animation curves are explicitly outside this
experiment. They require separate review after the surface decision.
