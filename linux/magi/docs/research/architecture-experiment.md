# MAGI anchored-popup versus combined-surface experiment

Prepared **2026-09-24**. Runtime record updated **2026-09-25** against the
working tree based on MAGI HEAD
`6aac5747e1332fe75755e2c899ac95dc265b5d84`. The isolated fixture now exists
under `experiments/bar-surface/`; the completed measurements and the remaining
unexecuted tests are separated below from the earlier design proposal.

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
3. a full-output dismissal catcher while a transient menu is open.

The large native surface must not imply a full-screen input region. The
The catcher must be enabled only while a transient menu is open and must never
be enabled merely because the combined surface exists.

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

The implementation under test keeps bar, active menu and configurable catcher as
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
themselves. The bounded fullscreen-hiding result is recorded below. Additional
outputs and fractional scale remain open.

## Fullscreen product policy

MAGI's intended compositor-fullscreen behavior is to hide the bar and expanded
menus. A layer surface reporting `alpha: 0` in this state is therefore expected
and is not a failure by itself. The acceptance criteria are:

- entering compositor fullscreen hides the bar and menu cleanly;
- the fullscreen client remains fully interactive, with no invisible shell
  region taking pointer or keyboard input;
- menu state may persist internally while its surface is hidden;
- leaving fullscreen restores a coherent bar/menu state with correct geometry,
  focus and input routing;
- menu open, close and switching continue to work after leaving fullscreen;
- the reservation remains constant during the run; and
- fixture cleanup restores the original reservation and removes its process,
  layer, IPC target and keyboard eligibility.

Transient MAGI menus, including Control Centre, Wi-Fi, Bluetooth and Volume,
are intended to dismiss when the user clicks outside them. That outside click
must be consumed by the shell: it must close the menu without also focusing,
activating, scrolling or otherwise interacting with the application beneath
the menu. Consuming outside-click dismissal is therefore a product requirement
and its catcher behavior is a required host validation, not an optional policy.

This policy supersedes the earlier proposal to treat bar/menu visibility above
a fullscreen client as an undecided stacking choice.

## Final bounded host tests — completed runtime results, 2026-09-25

### Fixed setup used

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

The live-session reservation measured 96px because both MAGI and the fixture
reserved the same edge. This known double-reservation constraint is not the
combined host's standalone production geometry.

### Mask-only fullscreen hiding — pass

The run used combined mode with its explicit 48px reservation, OnDemand
keyboard focus and mask-only dismissal. Before fullscreen, menu one opened at
window-local geometry `x=1596, y=38, 220×180`, reached phase 3 and accepted
focus. The total top reservation stayed at 96px.

In compositor fullscreen, `hyprctl layers -j` reported `alpha: 0` for both the
live MAGI layer and the experiment layer. Screenshots showed the client without
either bar or the expanded menu. This is a **pass** under the product policy:
the shell surfaces hid cleanly rather than stacking above the fullscreen
client. Fixture IPC and logs showed that menu one could remain internally open
at phase 3 with its prior geometry while hidden.

The operator confirmed that the fullscreen client remained fully interactive
for clicking, scrolling and normal use, with no invisible input blocker or
focus trap. Menu one persisted coherently through entering and leaving
fullscreen. After leaving fullscreen, it could open and close normally; Escape,
the content Close control and the active pill all closed it, and keyboard input
returned to the selected application after each close. The reservation stayed
at 96px throughout the fixture run and did not vary with fullscreen or menu
state. No QML, binding-loop, focus or surface error appeared.

The original run stopped when `alpha: 0` was mistakenly treated as a failure,
so it did not execute the requested menu-one → menu-two → menu-one sequence in
the fullscreen state or immediately after returning to tiled mode. Under the
clarified policy, switching pills while the bar is hidden is not a meaningful
user interaction. The useful remaining check is a complete switch sequence
after leaving fullscreen, verifying the active Region, content focus and sole
interactive menu.

### Cleanup — pass

The hidden menu was closed through IPC and the fixture was stopped with
`Ctrl-C`. Its process and layer disappeared, the top reservation returned from
96px to the original 48px, and only live MAGI PID 1552 remained. The fullscreen
client remained fullscreen and accepted input. The consuming catcher was never
enabled, so no catcher result can be inferred from this run.

### Required mask-only validation — pass

The follow-up run used the same combined host, explicit 48px fixture
reservation, OnDemand focus and mask-only dismissal. It completed the recovery,
placement and interruption checks that remained open above.

With menu one open at phase 3, entering compositor fullscreen hid both shell
layers at `alpha: 0` while the fixture retained menu one's
`x=1596, y=38, 220×180` state. The live-session reservation stayed at 96px.
Exiting fullscreen restored both layers at `alpha: 1` and restored menu one
with the same geometry. An immediate menu-one → menu-two → menu-one sequence
then passed: the outgoing content logged `active: false`, incoming content
accepted focus, and each settled snapshot contained exactly one requested
phase-3 menu. Menu two settled at `x=1632, y=38, 220×260`; the final menu-one
state returned to `x=1596, y=38, 220×180`.

The active native Region is not exposed through fixture IPC. Region tracking
was therefore verified through the source binding from `activeMenu` to
`activePill.combinedMenuRegion`
(`experiments/bar-surface/ExperimentWindow.qml:20–27`), the runtime requested
menu and geometry snapshots, and the previously completed manual pointer-mask
test. No state showed two requested or interactive menus.

All configurable placement presets kept both expanded menus within the
1920×1080 logical surface:

| Preset | Menu one, 220×180 | Menu two, 220×260 |
| --- | --- | --- |
| `menus-left` | `x=16, y=38` | `x=52, y=38` |
| `menus-center` | `x=806, y=38` | `x=842, y=38` |
| `split` | `x=16, y=38` | `x=1632, y=38` |
| `default` | `x=1596, y=38` | `x=1632, y=38` |

Each placement settled with the requested menu at phase 3, the other menu at
phase 0, correct focus ownership and no clipping or detached geometry.

Timed IPC requests then exercised every animation phase. The log's
`animations-interrupted` records show retargeting from current values:

| Phase | Interrupted state | Request and settled result |
| ---: | --- | --- |
| 1 — widening | width `202.504` | sibling request; menu two opened normally |
| 2 — revealing | height `167.852`, opacity `0.9995` | sibling request; menu two opened normally |
| 3 — open | menu one `220×180`, opacity `1` | sibling switch; menu two opened normally |
| 4 — fading | opacity `0.148` | menu one reopened from current opacity |
| 5 — retracting | height `16.403` | menu one reopened from current height |
| 6 — narrowing | width `65.704` | menu one reopened from current width |

In every case the latest request won, final dimensions and opacity were exact,
focus settled on the requested content, and no stale completion, blank final
state, orphaned interactive menu, QML error or binding loop appeared. The
reservation measured 96px before fullscreen, during fullscreen, after recovery,
after all placement checks and after all interruption checks.

The fixture was closed in mask-only/default state and stopped with `Ctrl-C`.
Its process, layer namespace and IPC instance disappeared; the tiled client
returned from `y=104, height=954` to `y=56, height=1002`; the reservation
returned from 96px to the original 48px; and live MAGI PID 1552 remained the
only Quickshell process.

### Required consuming-catcher validation — pass

The final run used the combined host, explicit 48px fixture reservation,
OnDemand focus and `dismissal consume`. The catcher filled the host below the
bar (`ExperimentWindow.qml:254–275`) and was added to the native Region only
while a menu was requested (`ExperimentWindow.qml:204–216`). Results that
depend on where a physical click was delivered are **operator-observed**;
lifecycle, focus and request sequencing are corroborated by fixture logs.

The operator confirmed that every outside click closed the open menu without
focusing, activating, scrolling or otherwise interacting with the client
beneath it. Logs contained four separate `menu-closed` records with reason
`outside-catcher`; each click produced one request-generation increment and one
close record. No duplicate close or underlying-client action was observed.

Clicking menu two's sibling pill while menu one was open switched directly
rather than being swallowed by the catcher. The log recorded `pill-clicked`
for menu two, changed the sole requested menu from menu one to menu two, removed
focus from menu one and accepted focus in menu two at phase 3. Menu two settled
at `x=1632, y=38, 220×260`. This is consistent with the bar's `z: 10` above the
catcher's `z: 0`; the active Region binding followed the newly requested pill,
and no state contained two interactive menus.

With menu two open, entering compositor fullscreen hid both shell surfaces as
required. The operator confirmed normal clicking, scrolling and typing in the
fullscreen client: the hidden full-output catcher did not consume input. The
fixture retained generation 8 and menu two as its sole requested menu while the
content focus log changed from `active: true` to `false`. On leaving fullscreen,
the same generation and menu regained focus without a close request, stale
geometry or input trap. The operator then confirmed that consumed outside-click
dismissal and direct sibling-pill switching continued to work after recovery;
the final outside close is log-correlated as generation 9.

The live-session reservation remained 96px while the fixture was present. It
was 96px after fullscreen recovery and after the final catcher close; menu and
dismissal state did not alter the fixture's reported 48px contribution. No QML,
binding-loop, focus or surface error appeared.

Before cleanup, dismissal was restored to `mask-only` through IPC and both
menus were confirmed at phase 0. `Ctrl-C` removed experiment PID 59430, its
layer namespace and IPC instance. The tiled client returned from
`y=104, height=954` to `y=56, height=1002`, the top reservation returned from
96px to the original 48px, and live MAGI PID 1552 remained the only Quickshell
process.

The placement, phase-interruption and rapid-switching gates are now covered for
the tested single-output scale-2 session. A second output and fractional scale
should be tested when such an output is available; until then they remain
explicit compatibility risks rather than claims supported by this run.

## Original test matrix

This matrix remains as the broader experiment backlog. The default-placement
parts of sections 1–2, the phase and switching paths in section 3, mask-only and
consuming input in section 4, section 5, section 6 and fullscreen
hiding/recovery in section 7 have the measured coverage recorded above.
Additional-output and fractional-scale cases remain unrun.

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

**Pass:** the bar and menu hide cleanly; no invisible part of the screen-sized
surface captures pointer or keyboard input; internal menu state may persist;
leaving fullscreen restores coherent geometry, focus and input routing; menus
work normally after restoration; and the reservation stays constant during
the run and returns to baseline after fixture exit. A consuming catcher must
also become non-interactive while hidden and must not make the fullscreen
client ambiguous or trap focus.

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
| Focus/dismissal | Existing plugin-specific behavior is the migration baseline. | OnDemand/Escape, mask-only pass-through, consuming outside dismissal and fullscreen hiding/restoration passed. |
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
- Compositor fullscreen hid the live and experiment layers cleanly, left the
  client interactive, preserved internal menu state, restored coherent menu
  behavior on exit and did not change the reservation.
- Post-fullscreen menu-one → menu-two → menu-one switching transferred focus
  and state cleanly with one interactive menu.
- All four placement presets remained within the output at their measured
  left, centre and right-edge positions.
- Every animation phase accepted a bounded interruption and retargeted from its
  current width, height or opacity to the latest request.
- Consuming outside clicks closed once without acting on the client beneath;
  sibling pills retained priority; the catcher became non-interactive while
  fullscreen hid the shell; and dismissal and switching survived recovery.

Still open or only partially covered:

- No blank frame, clipping or detachment was observed in normal A/B cycles,
  but the experiment did not quantify whether B improves seam or frame
  continuity over A.
- Fractional-scale rounding and additional outputs remain untested.

Wi-Fi, real services, dynamic plugin discovery, content unloading, per-output
menu arbitration and alternative animation curves are explicitly outside this
experiment. They require separate review after the surface decision.
