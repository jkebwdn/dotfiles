# Quickshell windows and menu lifecycle — research phase 1

Date inspected: **2026-09-24**. Status: research complete for this bounded
phase; design below is proposed, not approved or implemented. No runtime
tests, shell restarts, settings changes or external-shell investigations
were performed. Only documentation was changed.

## Scope, versions and evidence

Read AGENTS.md and the reconciled README, architecture, decisions and
Quickshell reference before researching. Reinspected MAGI's bar, expansion,
controller and Wi-Fi code. Current repository HEAD is
`7c79b1e85623bf4ccff9c5d2d7c62e703fe3a848` (knowledge-base commit).
`git diff e375e5e HEAD -- .config/quickshell/magi` is empty: source references
from the initial audit remain applicable. Paths below are relative to
`.config/quickshell/magi/` unless identified as upstream source. Short
`Bar.qml` and `ExpandablePlugin.qml` references mean `components/bar/`;
`Wifi.qml` means `plugins/bar/wifi/`. The inspection date above applies to
every URL and finding in this report.

Package versions rechecked: Quickshell 0.3.1-1, Hyprland 0.56.2-3,
qt6-base 6.11.2-3 and qt6-declarative 6.11.2-2. Installed binary versions do
not establish the versions loaded by an existing session.

- **API**: official Quickshell v0.3.1 or Qt documentation contract.
- **Source**: behavior inspected in the upstream v0.3.1 implementation;
  this is narrower than an API guarantee across releases/builds.
- **MAGI**: current local code, without a new interactive test.
- **Historical**: user-reported two-menu positioning stress test and working
  Wi-Fi/password flow retained from earlier sessions; not reproduced here.
- **Proposal/inference**: design reasoning or a risk requiring verification.
- **External projects**: none inspected; no findings about K4, Noctalia,
  Lucid, Caelestia or Serpantinum are used.

The [v0.3.1 release](https://github.com/quickshell-mirror/quickshell/releases/tag/v0.3.1)
links to upstream commit
[`1a4716cde794a59928d9d9fc15f2afc7a95de360`](https://github.com/quickshell-mirror/quickshell/commit/1a4716cde794a59928d9d9fc15f2afc7a95de360).
All Quickshell source URLs below were read at that release tag. The Arch
binary reports no build revision; byte-for-byte equivalence to upstream is
not established. Qt pages below displayed **Qt 6.11.2** when inspected;
their `/qt-6/` URLs are rolling and should be rechecked after upgrades.

No upstream code or assets are copied into MAGI. The installed Quickshell
license at `/usr/share/licenses/quickshell/LICENSE` is LGPL v3; Qt documentation
pages identify GFDL 1.3. Protocol XML includes its own license notices.
These observations do not replace file-specific review before future reuse.

## W01 — Panel surfaces, reservation and layers

**API sources (v0.3.1):**
[PanelWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/),
[ExclusionMode](https://quickshell.org/docs/v0.3.1/types/Quickshell/ExclusionMode/),
[WlrLayershell](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlrLayershell/).

PanelWindow anchors attach to screen edges; opposite anchors constrain that
axis. Margins apply on anchored edges. Auto exclusion attempts to reserve
the window and margins with three anchors. Ignore neither reserves space
nor respects other layers' exclusion. WlrLayershell is the Wayland attached
API; its default layer is Top and keyboard mode None. Namespace must be
set before windowConnected.

**MAGI:** `components/bar/Bar.qml:18` uses Auto, Top and three anchors;
line 27 requests 48px. The password panel at `plugins/bar/wifi/Wifi.qml:479`
uses Ignore and top/right margins. Separate surfaces preserve the separation
between bar reservation and menu dimensions.

**Compatibility/test:** these contracts do not guarantee stacking against
all fullscreen clients or other panels. T01/T07 must confirm reservation,
fullscreen interaction and other reserved surfaces on the installed compositor.

## W02 — Popup visibility, parent and actual geometry

**API:** [PopupWindow v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupWindow/).
A popup needs a valid window anchor and visible=true; it defaults hidden.
`parentWindow` and relativeX/Y are deprecated in favor of anchor properties.

**Source:** [src/window/popupwindow.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/window/popupwindow.cpp),
`ProxyPopupWindow` constructor, completeWindow(), onClosed(), setScreen().
The visibility target also depends on the parent's backing visibility.
completeWindow() assigns the transient parent and selects Qt::Popup for a
focus-grabbing popup or Qt::ToolTip otherwise. onClosed() clears requested
visibility. setScreen() refuses independent screen assignment. This resolves
the documentation's contradictory read-only screen property and writable
screen prose: choose the parent screen, not popup.screen.

**MAGI:** `ExpandablePlugin.qml:341` under `components/bar/` binds visibility
to revealedHeight > 0 and has no explicit grabFocus or closed handler.
A compositor close is not currently reconciled into MenuController/phase.
Do not infer that a Qt::ToolTip-backed popup receives keyboard input merely
because a child calls forceActiveFocus().

**Compatibility/test:** backend classification is release-source evidence,
not a promise of Qt/Hyprland keyboard delivery. T02/T04/T07 must inspect
forced closure, reopening and parent/screen disappearance.

## W03 — Anchor movement and coordinate dependencies

**API sources (v0.3.1):**
[PopupAnchor](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupAnchor/),
[TransformWatcher](https://quickshell.org/docs/v0.3.1/types/Quickshell/TransformWatcher/).
Window/item anchoring are alternatives. Item-relative placement is sampled
when shown; updateAnchor() recalculates after movement. Mapping is not
reactive. TransformWatcher's opaque transform property changes when the
geometry path changes, specifically to invalidate dependent expressions.
The anchor rectangle is integer-valued and at least 1×1. Default edges are
top/left and gravity bottom/right.

**MAGI:** `ExpandablePlugin.qml:330` watches barWindow.contentItem and the
pill. Both coordinate bindings read transform, then round
`barWindow.contentItem.mapFromItem(root, 0, root.height)`. Preserve that read
and the explicit window reference. This places the panel below the pill,
not necessarily below the bar's bottom edge. Existing Wi-Fi/volume/battery
popups use item anchors instead.

**Source corroboration:** [src/window/popupwindow.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/window/popupwindow.cpp),
reposition()/onPolished(), schedules changed geometry for a polish pass;
a binding update is not proof of same-instant compositor placement.

**API clarification:** [QsWindow v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsWindow/)
documents the Item-attached `QSWindow.window`. The historical unsuccessful
`root.QSWindow` experiment is not evidence that this API is absent. It does
not justify replacing MAGI's tested explicit barWindow reference.

**Compatibility/test:** T01 checks alignment during both pills' movement,
including legacy popups. Historical success applies to the two test menus;
scaling and all screen arrangements remain untested.

## W04 — Screen-edge adjustment is a design choice

**API:** [PopupAdjustment v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupAdjustment/).
Flags combine; correction order is Flip, Slide, Resize. Flip changes gravity,
Slide moves along an axis and Resize reduces that dimension to fit.

**MAGI:** `ExpandablePlugin.qml:374` uses None. That preserves the intended
pill seam but provides no requested edge correction. Enabling All is not
an equivalent fix: a panel may detach, flip above the pill or shrink.

**Proposal:** retain None for the baseline. Compare an explicit size cap
with scrollable content against SlideX/ResizeY in an isolated test. If the
surface is resized, content must use actual available dimensions rather
than assuming menuHeight always fits. The API does not choose the desired
visual behavior for MAGI.

**Compatibility/test:** T01/T07 cover narrow outputs, constrained height,
large fonts and scaling. Do not change positioning during a Wi-Fi migration.

## W05 — Animation completion is not cancellation

**API:** [Qt Animation, 6.11.2](https://doc.qt.io/qt-6/qml-qtquick-animation.html),
stop(), complete(), finished(), stopped(), alwaysRunToEnd.
Normally stop() retains the intermediate value; complete() jumps to the
endpoint. finished is for natural completion of standalone top-level
animations, not manual cancellation or child animations in groups,
Behaviors or Transitions. stopped covers manual and natural endings.

**MAGI:** `ExpandablePlugin.qml:77` stops three standalone NumberAnimations,
then explicitly chooses the next phase and starts from current values.
Its onFinished handlers therefore fit the documented standalone model.
The full opening is 180ms widening, then 140ms reveal with 90ms fade-in
concurrently. Closing is 70ms fade, 120ms retract, 160ms narrowing. All use
OutCubic. Retargets use full configured durations even for short distances.

**Inference:** replacing stop() with complete(), using onStopped to advance
phases, or wrapping animations in a group could change behavior. A smoother
velocity-preserving reversal is not guaranteed by restarting OutCubic.

**Compatibility/test:** T02 exercises every phase and same-frame reversals;
retain timings until separately approved.

## W06 — Declarative transitions are an alternative, not a drop-in repair

**API:** [Qt Transition, 6.11.2](https://doc.qt.io/qt-6/qml-qtquick-transition.html),
animations, reversible, from/to. Transition chooses the best state match;
top-level animations run concurrently unless grouped sequentially. A
matching Transition overrides a Behavior on the same property. Reversible
permits reverse state changes, but does not define MAGI's asymmetric
open/close policy or replace external window-lifecycle handling.

**MAGI:** the numeric phase state machine at `ExpandablePlugin.qml:43`
is imperative coordination, not QML State/Transition declarations.

**Proposal/trade-off:** retain explicit phases for minimal change and clear
interruption branches. A future State/Transition rewrite may reduce manual
coordination, but needs new completion handling and regression tests; do
not carry standalone onFinished assumptions into it.

**Compatibility/test:** T02 is prerequisite to any rewrite. Documentation
alone does not establish equivalence under all interrupted transitions.

## W07 — Painting, control input and window hit regions differ

**API sources:** [Qt Item, 6.11.2](https://doc.qt.io/qt-6/qml-qtquick-item.html)
(clip, opacity, enabled, forceActiveFocus) and
[QsWindow v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsWindow/)
(mask, dimensions).
Item.clip clips painting to a bounding rectangle, not rounded corners.
Opacity does not disable input. enabled=false blocks keyboard/press input
and removes active focus, but Qt 6 can still deliver hover. QsWindow.mask
controls which surface areas receive clicks; transparent color is not an
input mask. implicit dimensions are requested; width/height are actual.

**MAGI:** the reveal rectangle clips at `ExpandablePlugin.qml:386`; Loader
opacity changes at line 410, but no input-enabled phase policy exists.
This is harmless for the present text tests; future buttons could remain
active during fading. Rounded backgrounds do not establish rounded input.

**Proposal:** gate content actions separately from paint opacity and preserve
a host-level dismissal path while closing. Do not add a fullscreen catcher
without explicitly defining which clicks it consumes.

**Compatibility/test:** T03 tests fading controls, corners, scroll/drag,
transparent pixels and press-cancel behavior; T01 checks actual geometry.

## W08 — Keyboard focus has a compositor layer and an item layer

**API sources (v0.3.1):**
[WlrKeyboardFocus](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlrKeyboardFocus/),
[WlrLayershell](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlrLayershell/).
None rejects keyboard input; OnDemand lets the system determine focus;
Exclusive requests exclusive keyboard access. OnDemand is not an automatic
focus-transfer guarantee. Qt Item.forceActiveFocus() focuses the item and
ancestor focus scopes; it is not a substitute for compositor eligibility.

**Protocol/source:** [wlr layer-shell XML](https://raw.githubusercontent.com/swaywm/wlr-protocols/master/unstable/wlr-layer-shell-unstable-v1.xml),
interface version 4 as inspected (rolling master, no commit pinned),
set_keyboard_interactivity/get_popup: child popups inherit interactivity.
[Quickshell v0.3.1 surface.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/wayland/wlr_layershell/surface.cpp),
LayerSurface::attachPopup(), uses get_popup for an xdg_popup; commit() maps
the keyboard mode to the protocol.

**MAGI:** Bar does not request keyboard focus. Wi-Fi's separate panel uses
OnDemand and forceActiveFocus() at `Wifi.qml:495`/`:507`. The user's historical
success supports preserving it, not assuming equivalent behavior inside
the shared popup. A focus grab plus a non-grabbing popup under a None bar
is a test candidate, not an established keyboard solution.

**Compatibility/test:** T04 must compare modes without changing the live
bar. Retain the separate password host; avoid Exclusive as a default menu policy.

## W09 — Dismissal alternatives and their limits

**API:** [PopupWindow.grabFocus, v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupWindow/)
hides the popup on outside dismissal; changing grabFocus while open takes
effect only after hiding/showing. This can bypass a graceful close animation.

**API:** [HyprlandFocusGrab, v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandFocusGrab/)
whitelists windows, retains focus and emits cleared on outside click/touch.
It does not itself hide the popup. Activation needs a visible window;
cleared may also result from hiding/removing all listed windows.

**Source:** [focus_grab/qml.cpp at v0.3.1](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/wayland/hyprland/focus_grab/qml.cpp),
onGrabCleared() emits cleared before setActive(false); tryActivate() warns
and cannot work without the compositor protocol. Avoid assuming active is
already false inside onCleared or synchronously reactivating there.

**Protocol context:** [hyprland-focus-grab-v1.xml](https://raw.githubusercontent.com/hyprwm/hyprland-protocols/main/protocols/hyprland-focus-grab-v1.xml),
interface v1, rolling main inspected without a commit pin, permits
compositor-selected keyboard focus and clearing for other compositor actions.
It does not promise which whitelisted window gets initial focus or whether
an outside click activates the underlying application. The Quickshell
page's protocol hyperlink currently points to global-shortcuts XML; use
the focus-grab XML above for this subject.

**MAGI/proposal:** no current grab or dismissal handler. Prefer testing a
HyprlandFocusGrab adapter that converts cleared into a close request while
keeping the existing animation. Whitelisting the entire bar permits pill
switching but makes blank-bar clicks internal; that needs a separate policy.

**Compatibility/test:** T03/T04/T06 cover click-through, touch, grab clearing,
rearming, switching, multiple surfaces and focus restoration.

## W10 — Escape and pointer handling belong to explicit policy

**API:** [Qt Keys, 6.11.2](https://doc.qt.io/qt-6/qml-qtquick-keys.html)
provides escapePressed and BeforeItem/AfterItem priorities; accepted events
stop propagation. Specific-key handlers accept by default. This operates
on delivered key events, not as a global compositor shortcut.
[Qt MouseArea, 6.11.2](https://doc.qt.io/qt-6/qml-qtquick-mousearea.html)
defines clicks by press/release and exposes canceled when another item,
such as a Flickable, steals handling. Composed-event propagation concerns
other MouseAreas, not arbitrary desktop windows.

**MAGI:** `ExpandablePlugin.qml:271` toggles on pill click; it has no Escape
handler. Wi-Fi uses TextInput.onAccepted and a Flickable list. An Escape
handler on an unfocused window cannot be assumed to run.

**Proposal:** content handles local cancel/back first; an unconsumed Escape
requests host dismissal. Explicitly define whether nested pages consume the
first Escape. A parent fallback cannot override a child's accepted event.
Do not intercept Enter indiscriminately and break password submission.

**Compatibility/test:** T03/T04 test text selection, IME, Tab/Shift-Tab,
Escape propagation and canceled drags; do not claim automatic Escape closure.

## W11 — Component and Loader ownership

**API:** [Qt Loader, 6.11.2](https://doc.qt.io/qt-6/qml-qtquick-loader.html).
Loader defaults active; deactivation releases its item while retaining its
source definition. Changing source/sourceComponent destroys the old item.
Explicit Loader dimensions size visual content. Loader is a focus scope;
focus must be established through that scope. onLoaded also handles a
successful initial load where status may already be Ready. Asynchronous
instantiation can span frames and requires readiness/error handling.

**API:** [Qt Component, 6.11.2](https://doc.qt.io/qt-6/qml-qtqml-component.html).
A Component retains its declaration context; that context must outlive its
instances. Completion/destruction handler order is undefined. Neither is
an open/close callback for a retained view.

**MAGI:** `Bar.qml:169`/`:210` declare content; `ExpandablePlugin.qml:397`
loads it without an active binding. Closing does not explicitly unload it.
The fixed Loader dimensions, not the content's preferred size, govern the
loaded visual root. No focus/lifecycle contract exists yet.

**Proposal:** loader owns view objects; a host-owned session owns transient
menu state; services own durable operations. Keep content through exit
animation, then retain or unload according to an explicit policy. Never
unload at close-request time if its pixels are still needed.

**Compatibility/test:** T05 counts creation/destruction, retained state,
load errors and context removal. Wi-Fi pending callbacks must not be moved
into an unloadable view without an approved ownership migration.

## W12 — Backing window destruction is not view destruction

**Source (v0.3.1):**
[popupwindow.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/window/popupwindow.cpp), deleteOnInvisible();
[proxywindow.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/window/proxywindow.cpp),
constructor, setVisibleDirect(), deleteWindow(), disownWindow(), completeWindow();
[wlr_layershell.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/wayland/wlr_layershell/wlr_layershell.cpp), deleteOnInvisible().
Both popup and layer-shell backends opt into backing-window deletion when
hidden. ProxyWindowBase owns a persistent contentItem, detaches it before
deleting the backing window and reattaches it when a window is created.
Therefore hiding alone does not destroy MAGI's Loader tree. Destroying the
QML owner or deactivating its Loader is a different operation.

**API:** [QsWindow.closed, v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsWindow/)
is for external/error closure, not setting visible=false. The same page
distinguishes desired visibility from backingWindowVisible.

**MAGI:** revealedHeight reaching zero hides the popup while its inline
content remains owned by the QML graph. Component.onCompleted is not a
reopen hook. The source contains no external-closure recovery policy.

**Proposal/test:** T05 logs view lifetime separately from window connection
and visibility. T06 verifies idempotent cleanup on external close and parent
loss. Do not interpret windowConnected as proof of keyboard readiness.

## W13 — Lazy loading entire windows is optional

**API:** [LazyLoader v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/LazyLoader/)
can asynchronously prepare window objects and owns/destroys its loaded
object. active=true or accessing item during loading can force synchronous
completion; activeAsync avoids that request. active=false destroys content.
UI reload loads synchronously for window reuse; not all nested components
support asynchronous creation.

**MAGI/proposal:** current inline PopupWindow and Qt Loader are sufficient
for the small tests. Use Qt Loader for replaceable visual content first;
consider LazyLoader for an entire expensive window only after measurement.
Loading policy must not bypass the session's closing/unloading rules.

**Compatibility/test:** T05 compares retained, on-demand and asynchronous
content. Test interrupted loads and error recovery before adopting lazy
windows. No performance advantage was measured in this phase.

## W14 — Screen identity and logical pixels

**API sources (v0.3.1):**
[ShellScreen](https://quickshell.org/docs/v0.3.1/types/Quickshell/ShellScreen/),
[Variants](https://quickshell.org/docs/v0.3.1/types/Quickshell/Variants/),
[QsWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsWindow/).
ShellScreen objects become dangling on disconnect; reconnecting does not
revive stored references. Variants creates non-Item instances from model
values and documents a screen-per-window use case, with a reload caveat
if its model mutates during creation. QsWindow uses logical pixels;
devicePixelRatio relates them to monitor pixels.

**Source:** [surface.cpp at v0.3.1](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/wayland/wlr_layershell/surface.cpp),
LayerSurface constructor/commit(), converts Qt geometry through QHighDpi;
an explicit valid output is passed unless compositor selection is requested.
The layer-shell protocol permits compositor output selection for null output.
W02 establishes that popup screen selection belongs to its parent.

**MAGI:** `shell.qml:6` creates one bar; neither Bar nor the Wi-Fi password
panel explicitly binds screen. The password panel is not parent-anchored.
Rounded anchor coordinates are logical pixels: multiplying them by DPR
would apply an extra scale conversion. Current single global menu IDs
would also open duplicate per-screen instances if copied unchanged.

**Proposal/test:** T07 tests mixed scales and hotplug. Future hosts should
receive the bar's screen identity, reacquire live screen objects after
hotplug and distinguish instance IDs from plugin type IDs. Default-output
selection remains compositor-specific; no multi-monitor result is claimed.

## Proposed technical design — not implemented

### Preserve the baseline and separate responsibilities

Retain the 48px bar, per-pill ExpandablePlugin geometry, TransformWatcher
mapping, None adjustment and the exact D004 animation timings for the first
prototype. Keep Wi-Fi's current service/UI/password arrangement intact.
Use the existing dummy menus for an isolated lifecycle/input experiment.

Proposed responsibilities (names describe a contract, not new API types):

| Owner | Responsibility |
| --- | --- |
| Menu coordinator | Requested instance, request generation, close reason, host registration; choose latest request and reject stale callbacks. |
| Per-instance host | Existing animation phase/geometry, popup visibility, loading policy, input eligibility, focus/dismissal adapter and cleanup. |
| Content view | Render service/session state, declare preferred size and initial focus item, emit actions and close/back requests. No direct window visibility mutation. |
| Session | Selection/navigation and temporary draft state retained through closing/reversal; deliberately clear secrets on cancel/submit/teardown. |
| Services | Durable operations and observers that must survive view unloading, after a separately approved migration. |

Use globally unique instance IDs including output identity if per-screen bars
are introduced; plugin type names alone are insufficient. Keep requested,
rendered and interactive states distinct. There may be two animating hosts
but only one owner of actionable content/focus.

### Proposed lifecycle

1. **Closed:** no requested session, popup hidden, no grab; content retained
   initially for behavior parity. A later opt-in unload policy can release it.
2. **Prepare:** validate host/anchor/screen, create a session and ensure content
   is ready. Synchronous local content can proceed immediately; asynchronous
   content waits or shows an explicit loading view. Handle errors explicitly.
3. **Opening:** run existing widening/reveal/fade. Keep content actions disabled
   until the chosen readiness/phase condition is satisfied. Acquire a tested
   input adapter only after its required surface exists, then select the
   content focus item. No keyboard-success claim follows from visibility alone.
4. **Open:** allow content actions; route close requests from pill, Escape,
   outside input or content through one coordinator method.
5. **Closing:** disable content actions immediately, cancel pointer interaction
   safely, release keyboard/grab ownership and run fade/retract/narrow. Keep
   content available for painting. Outside dismissal must not automatically
   reacquire a grab. A deliberate reopen may reacquire after readiness checks.
6. **Closed completion:** emit the host's own completion event, clean the
   session, then optionally deactivate Loader. Do not use QsWindow.closed
   as the notification for this intentional close.
7. **Forced teardown:** external closure, parent/output destruction or resource
   loss invalidates the request generation, stops transitions, clears ownership
   and removes grab references. Settle closed without requiring an animation
   on a missing surface; ignore duplicate or stale completion callbacks.

Retained views receive explicit session activation/deactivation rather than
using Component.onCompleted as an opening hook. Cleanup must tolerate partial
loading and arbitrary destruction order. Content should not destroy itself;
the host/Loader controls object ownership.

### Interrupted transitions and switching

Keep current stop-and-retarget logic for each instance. Stop all relevant
animations, read their current values and choose the existing safe phase;
advance only from natural completion matching the current phase/request.
Use a monotonically increasing request generation for asynchronous loading,
focus scheduling and queued callbacks so a late result cannot reopen an old
menu. Reopening during closing cancels pending unload and reuses the view.

Prefer preserving concurrent outgoing/incoming animation initially, with
only the newly requested host accepting content actions. A centralized
focus adapter transfers ownership; a click on an old pill is a new request.
Alternative: fully close before opening the next host, keeping only the
latest queued request. This simplifies surface/focus overlap but adds up to
the close duration to switching and changes the established experience.

A future declarative Transition rewrite is independent work, not required
for this lifecycle design. Distance-scaled duration or velocity-continuous
reversal would change motion and requires separate review.

### Focus and dismissal alternatives

| Candidate | Benefit | Trade-off / required proof |
| --- | --- | --- |
| Existing non-grabbing PopupWindow + HyprlandFocusGrab | Keeps geometry and permits an animated response to outside dismissal. Preferred first test on Hyprland. | Must prove keyboard delivery under current bar mode and Qt window flags. Hyprland-specific; outside click propagation and initial focus are unresolved. |
| PopupWindow.grabFocus=true | Built-in outside dismissal with fewer moving parts. | Compositor can hide before the exit animation; configure before showing; reconcile external close. It may alter pill switching and does not prove password equivalence. |
| Separate OnDemand PanelWindow for keyboard content | Preserves Wi-Fi's established host pattern and separates keyboard eligibility from the bar. | Explicit screen/geometry and grab integration needed; does not automatically reproduce the connected pill seam. |
| Temporarily make bar OnDemand for child popup sessions | May address inherited keyboard eligibility. | Changes bar focus behavior; must prove no typing theft or retained focus. Not recommended as an untested live change. |
| Full-output input catcher/overlay | App controls internal pointer dismissal and timing. | Changes stacking, click consumption and screen coverage; substantial geometry/input redesign. Defer. |

Prototype the first candidate only in a separately approved test. If it cannot
provide reliable keyboard input without disturbing the bar, retain the
separate keyboard host rather than migrating password entry prematurely.
Do not combine native grabFocus and HyprlandFocusGrab without a demonstrated
need and tests for competing grabs.

Whitelist decisions must be explicit: including the bar makes sibling pills
clickable without dropping the grab, but includes its blank area and other
plugins. Define blank-bar dismissal and interactions with the independent
Wi-Fi window before integrating real menus. Keep the grab scoped to actual
session surfaces, release it during teardown, and do not force focus back to
a previous application after an outside click; the user may have selected a
new application. Focus restoration on Escape remains a test requirement.

For Escape, use a content-first cancel/back contract, then host dismissal for
unconsumed events. Preserve Enter behavior and IME composition. A menu that
cannot receive keyboard input cannot promise Escape dismissal.

### Content ownership and geometry alternatives

Start with retained views and explicitly suspend their session work while
closed: this preserves current behavior and avoids migration-related callback
loss. Later compare unload-after-close for stateless/heavy views, with durable
work kept outside them. Retention preserves scroll/drafts but costs memory
and can keep observers/timers alive. Unloading saves view resources but resets
local state and requires an explicit session/service ownership boundary.

Keep width/menuHeight explicit initially. A future content-size contract can
supply preferred dimensions, capped to output bounds, with scrollable overflow.
Do not size a Loader from the same child dimension the Loader itself forces;
that risks a sizing loop. Edge sliding/flipping remains a separate design
choice because it can break the visual attachment to the pill.

## Recommended local tests — all pending approval

Use an isolated test configuration, not live QML. The following are proposed
acceptance checks, not executed results. Record installed versions, output
scale/geometry, input method, event order and actual outcome for every run.

| ID | Test | Required evidence / pass condition |
| --- | --- | --- |
| T01 | Two pills, repeated switches, legacy tooltip open beside a moving pill; constrained edges | Popup remains attached through movement; actual/requested dimensions recorded; bar reservation unchanged. Compare None with candidate adjustment only in isolation. |
| T02 | Close/reopen/switch in every phase, repeated/same-frame requests | No stuck phase, blank reopening, stale completion or unloaded outgoing view; final state matches latest request and baseline timings. |
| T03 | Outside click/touch, blank bar, sibling pill, fading button, drag into/out of popup, Flickable cancel, corners | One intentional action/dismissal, no invisible actionable controls, documented click-through/consumption and canceled pointer behavior. |
| T04 | Keyboard focus matrix: non-grabbing/grabbing popup, focus grab, bar None/OnDemand, separate panel | Record actual keyboard recipient; typing, Tab, Shift-Tab, Enter, Escape and IME work as intended; desktop focus resumes; closed menus do not steal typing. |
| T05 | Retain/unload/async load, close during load, reopen during close, host deletion | Count content creation/destruction separately from backing connections; no blank exit, late reopen, leaked references or lost required operation observer. |
| T06 | Native dismissal, cleared grab, hidden parent, competing grab, forced host removal | Coordinator and view settle consistently; no immediate regrab loop, stale ID or crash; clean next open. Resource-loss recovery may require a simulated host-level event, not a destructive system test. |
| T07 | Two outputs, mixed scale, negative output origins, output removal/reconnection, fullscreen | Correct screen association and logical geometry, acceptable seam rounding, no reuse of dangling screen references; password host stays with intended bar. |
| T08 | Later Wi-Fi migration equivalence | Preserve scan handoff, known/open/PSK paths, failure/retry, password clearing, Cancel and keyboard behavior; review separately before any migration. |

## Unresolved questions and approval boundary

- Can the preferred non-grabbing popup/focus-grab combination receive keyboard
  input reliably with the current non-focusable bar? Protocol and Qt surface
  behavior must be resolved by T04, not by a code-name assumption.
- Does dismissal consume the outside click, and which whitelisted surface
  receives keyboard focus during a switch? What is the desired blank-bar policy?
- Are retained or unloadable views appropriate per plugin, and which pending
  operations must survive closure? Wi-Fi ownership changes remain unapproved.
- Should menu arbitration be global or per output? Proposal uses unique
  instances with one global interactive owner; user experience may prefer otherwise.
- What edge behavior preserves the annotated design: size cap, slide, flip or
  scrolling? What rounding is acceptable at fractional scale?
- Upstream source is pinned by release, but Arch build patches and live-process
  versions were not audited. Protocol XML references are contextual rolling
  sources, not evidence of the exact negotiated protocol in this session.

Recommend reviewing this design and authorizing T01–T06 in a separate test
configuration first, followed by T07 on available outputs. No further
research, live implementation or external-project investigation starts
without the user's next approval.
