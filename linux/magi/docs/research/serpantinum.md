# Serpantinum — source investigation

Inspected **2026-09-24**, MAGI research phase 2A. Current repository:
[ilyamiro/serpantinum](https://github.com/ilyamiro/serpantinum), default branch
**master**, commit **`9f0e36bd9199c1d379701d052b884762b0de008b`**
(2026-09-23). [version.txt][version] contains **2.1.9**; this identifies the
file at the inspected commit, not a verified release tag. Current source
links below pin that commit. The inspection date applies to all findings.

License: [README.md:186–190][readme] states **AGPL-3.0-or-later** and
[LICENSE.md][license] contains AGPL v3. **Metadata discrepancy:**
[nix/package.nix:158][package] declares MIT. Do not treat that conflicting
package field as permission to reuse AGPL-covered implementation under MIT.
No code/assets were reused. Asset-specific licensing was not exhaustively
audited; resolve provenance and the discrepancy before any reuse.

## Evidence and source map

**Verified source** describes inspected code; **historical** refers only to
the separately pinned imperative-dots snapshot below. **Intent** is an
upstream claim, while **proposal/risk** is our analysis. Neither project was
run, and no local UI/performance/focus/network tests were performed.

Local baseline: MAGI HEAD `04b5e4b9556624f7a365524bebc8869d05f6cc21`;
`.config/quickshell/magi/components/bar/ExpandablePlugin.qml:77`, `:330`,
`:341`, `:397`, `components/bar/Bar.qml:15`, `:47`, and
`services/MenuController.qml:10`. Short local source paths are relative to
`.config/quickshell/magi/`; ExpandablePlugin.qml is under `components/bar/`.
Runtime versions remain the previously
verified Quickshell 0.3.1, Qt 6.11.2 and Hyprland 0.56.2. See the
[phase-1 API report](quickshell-windows-and-lifecycle.md) for API guarantees
and outstanding tests; external source is not an API guarantee.

| Responsibility | Pinned source / symbols | What is demonstrated |
| --- | --- | --- |
| Composition | [src/quickshell/Shell.qml][shell] | ShellRoot instantiates Main, Bar, Launcher, Clipboard and other subsystems separately. |
| Launch/control | [bin/serpantinumd][daemon], [src/scripts/qs_manager.sh][ipc] | Daemon launches Quickshell using MAIN_QML; manager sends IPC to `main.handleCommand`. Scripts were read, never executed. |
| Bar surfaces | [src/quickshell/bar/Bar.qml][bar], [TopBar.qml][topbar] | Per-screen PanelWindow via Variants; explicit module instances in the horizontal bar. SideBar provides a separate orientation implementation. |
| Compact network entry | [bar/modules/system/WifiWidget.qml:269–293][wifiwidget] | Compact button invokes the manager's `toggle network wifi`; it does not create an anchored popup. |
| Shared menu host | [src/quickshell/Main.qml][main], `switchWidget()`, `executeSwitch()`, `ensureWidgetItem()` | Full-screen overlay PanelWindow owns geometry, navigation target, cached views, StackView, dismissal and screen choice. |
| Menu layout registry | [src/quickshell/WindowRegistry.js][registry], `getLayout()` | Explicit names map to Component file paths, dimensions and screen-relative positions. |
| Menu content | [src/quickshell/network/NetworkPopup.qml][network], `gotoTab()`, `resetAndPlayIntro()`, visibility/destruction handlers | Despite its name, the root is an Item, not a PopupWindow. It owns internal network tabs and content-level effects/work. |
| Separate animated hosts | [launcher/Launcher.qml][launcher], [clipboard/Clipboard.qml][clipboard] | Each creates its own overlay PanelWindow rather than using Main's StackView. |
| Other popouts | [popouts/PopoutManager.qml][popouts] | Instantiates Osd, TrayBase and SideMusicPopout. Their complete behavior was outside this focused trace. |
| Desktop widget extensibility | [widgets/WidgetRegistry.qml][widgets], `registerType()`, `faceComponent()` | A separate desktop-widget registry; not the shared menu contract. |

## S01 — Shared overlay, separate bar, several other windows

**Verified source:** [Main.qml:13–22, 199–213][main] is a transparent
all-edge-anchored PanelWindow on WlrLayer.Overlay with ExclusionMode.Ignore.
The bar is independent, instantiated per screen in [Bar.qml:11–19, 198–271][bar].
Main displays one selected menu on one selected screen. Thus the project is
a hybrid, not one surface for the whole desktop and not one PopupWindow
per compact bar widget.

The network click path is button → shell manager → IPC →
`handleCommand()` → `switchWidget()` → `executeSwitch()` → cached Item in
StackView. [WindowRegistry.js:73–226][registry] places network at a configured
screen corner with a bar offset; no pill `mapFromItem()` anchor is supplied.
Its nominal network size is 720×600, calendar 1360×510, and other entries
have fixed or fill dimensions, scaled by a user UI-scale value.

**MAGI relevance/proposal:** a separate shared overlay can preserve MAGI's
bar window while centralizing menu hosting. Preserving MAGI's exact moving
pill attachment would still require an explicit origin geometry contract;
Serpantinum's registry positions are not equivalent to MAGI's
TransformWatcher-backed anchor mapping. Test E1/E5.

## S02 — Host caches content; StackView is not the owner of all state

**Verified source:** [Main.qml:311–381][main] keeps `widgetCache` and
`componentCache`. `ensureWidgetItem()` loads a Component and calls
`createObject(preloaderContainer)`; a 150ms repeating timer preloads listed
menus while hidden. The preload list includes names absent from the current
layout table (for example battery/movies); `preloadWidget()` skips entries
without a layout. It is not discovery of arbitrary plugin directories.

`executeSwitch()` reuses cached Items and replaces the StackView entry with
`StackView.Immediate`. All six StackView enter/exit transitions are null
(lines 630–649). The current `delayedClear` timer only sets `disableMorph`;
it neither clears the stack nor destroys the cache. There is no close-path
view destruction in these functions. Different Component/view ownership
must not be inferred from the timer's name.

**MAGI relevance/proposal:** cached views avoid repeated construction but
need explicit activation, background-work suspension and secret clearing.
MAGI already retains its content Loader; caching alone is not a new benefit
that requires an overlay. Host/session state should remain separate from
durable network operations. Verify effective Item visibility and activity
when the native window hides, rather than assuming retained content stops.
Test E3 before adapting this policy.

## S03 — Switching, entry, exit and interruption are different paths

**Verified source:** [Main.qml:397–414, 568–790][main] separates target/current
menu names, animated container dimensions and final content-stage dimensions.
The container clips content. Its x/y/width/height Behaviors use 300ms
OutCubic. Switching updates target geometry and immediately replaces the
view; this is geometry interpolation with immediate content substitution,
not a host crossfade between two live menu images.

Entry from hidden sets geometry with morphing disabled, makes the window
visible, then reenables morphing through a guarded `Qt.callLater`. The
content stage has entry scale 0.96→1 (280ms OutCubic) and opacity 0→1
(200ms OutCubic). Nested views may run their own effects: for example
[NetworkPopup.qml:17–30, 92–158][network] animates a 0–1 intro value over
900ms and supplies easing/windowing helpers. These are independent layers
of animation, not a single universal menu timeline.

**Close-path limitation:** `visible: isVisible` at Main line 208, together
with `switchWidget("hidden")` immediately setting `isVisible=false`, hides
the native surface before a complete painted exit can be assumed. Content
defines exit scale/opacity durations of 160/140ms and an exit-duration field
of 180ms, but a 200ms delayed timer does not keep this window visible.
This is a source-derived concern; no observed flicker or timing is claimed.

**Interruption safeguards:** every switch increments `switchGeneration`;
deferred retries and delayed work check their generation. A new switch stops
the delayed timer. This prevents stale scheduled requests from winning.
It does not prove velocity continuity, successful focus transfer, or bounded
loading failure: failed/unready content leads to `Qt.callLater` retries,
including a Component.Error path returning null. Repeated failure needs a
bounded error state in any adaptation. Test E2/E3.

## S04 — Focus and outside-click policy are explicit host concerns

**Verified source:** [Main.qml:24–28, 203, 210–308][main] sets focusable true,
provides a window-scoped Escape Shortcut, and installs an outside MouseArea.
The normal input mask excludes a bar-shaped hole using Intersection.Xor.
The hole accounts for bar edge/autohide and some menu overlap; its thickness
is a literal 48, while registry offsets are UI-scaled. For draggable views
(including guide), the input region is the animated container and the
outside catcher is disabled. Outside dismissal is therefore not universal.

The content stage has its own MouseArea to block background clicks. StackView
requests item focus on selection and handles Escape too; NetworkPopup also
requests focus when visible and retries once with a 50ms timer. These calls
do not by themselves establish compositor focus readiness.

**Quickshell 0.3.1 compatibility fact:** [PanelWindow documentation][qspanel]
maps focusable to Wayland keyboard focus; [tagged implementation][qsfocus]
maps true to **OnDemand**, false to None. Main does not explicitly request
Exclusive in the inspected file. Escape delivery and restoration on
Hyprland 0.56.2 need a runtime test, especially for IPC opening without a
click. No native popup grab or HyprlandFocusGrab appears in this host path.

**MAGI relevance/test:** a full-output catcher gives the host a controllable
close request but deliberately changes which desktop clicks reach underlying
applications. The bar hole and draggable exception are product choices,
not automatic Quickshell behavior. E4 must test clicks on another menu pill,
blank bar, outside desktop, child inputs, and menus spanning the hole.

## S05 — Screen association and navigation are application policy

**Verified source:** [Main.qml:31–53, 145–181, 481–562][main] chooses the
Hyprland focused monitor by name, then an active-toplevel screen if available,
then current/first screen. Switching may reassign the single overlay's
screen. `handleCommand()` can change a current item's `activeMode`/`gotoTab`
instead of closing it when a new argument arrives. Items may override host
size through `targetMasterWidth/Height`.

[WindowRegistry.js][registry] computes positions from screen width/height
and UI scale, not actual button geometry. It does not generally cap fixed
menu sizes to available dimensions. Main rejects clearly invalid/off-screen
layouts, but this is not a full overflow/edge-adjustment algorithm.
`globalUiScale` is read from settings, including a per-monitor lookup;
screen changes report active state, while the inspected screen-change
handler does not itself refresh that scale lookup.

**MAGI relevance/proposal:** explicit screen and preferred-size contracts
are useful; do not multiply logical coordinates by devicePixelRatio.
Choose initiating-bar versus focused-monitor ownership deliberately, bound
oversized content, and reevaluate UI scale on output changes. E5 must test
focused-monitor changes, fractional scale, narrow outputs and simulated
hotplug before claiming compatibility.

## S06 — A separate host already demonstrates delayed hiding

**Verified source:** [Launcher.qml:14–25, 348, 998–1062][launcher] creates its
own overlay PanelWindow and retains visibility while `isVisible` is true
**or** animated progress exceeds 0.001. Progress animates entry over
420ms centred/340ms attached (OutBack, overshoot 1.28) and exit over
200/150ms (InQuad); dimensions depend on orientation/progress. Its outside
catcher is enabled only while logically open, and focusable follows that
same state. [Clipboard.qml:14–23, 118, 583–610][clipboard] similarly retains
the surface through its progress animation, with 300/200ms durations.

This is materially different from Main's immediate visibility close path.
It shows why “Serpantinum's animation system” is too broad a description.
The reusable idea is separating requested visibility from paint lifetime;
MAGI already does that via `revealedHeight > 0` at ExpandablePlugin.qml:379.
It does not require copying launcher geometry or replacing anchored popups.
E1/E2 should compare actual close/reopen behavior using equivalent content.

## S07 — Modularity and content work have limits

**Verified source:** [TopBar.qml:683–1055][topbar] explicitly instantiates bar
modules; [WindowRegistry.js][registry] explicitly maps menu names and
geometry. This is configurable application composition, not K4's catalog
and plugin object contract. [WidgetRegistry.qml][widgets] does expose type
registration and cached face Components, but for desktop widgets; it should
not be described as Main's menu plugin API.

[NetworkPopup.qml:122–164][network] starts scanning/refresh and intro work
on visibility, stops several timers/processes and clears pending fields
when invisible, and stops scans on destruction. These are cleanup attempts
in the content layer. They do not prove all operations finish safely or that
hiding Main necessarily triggers the desired child visibility lifecycle.
This is particularly important with cached Items and retained StackView
content. Networking details were inspected only to establish this lifetime
boundary, not as a complete networking audit.

**MAGI relevance/proposal:** adopt an explicit host/content activation
contract independent of Item.visible, with session and durable service
ownership defined before unloading. Preserve MAGI Wi-Fi's scan handoff,
known/open/PSK connection flow, errors, pending guards, masked input,
Enter/Cancel and input clearing (`plugins/bar/wifi/Wifi.qml:47`, `:72`,
`:182`, `:348`, `:479`). Do not port either project's networking code in
this research phase. E3 uses simulated operations; real Wi-Fi acceptance
remains phase-1 T08 and requires separate approval.

## Historical imperative-dots — do not attribute to current Serpantinum

Historical repository [ilyamiro/imperative-dots][oldrepo], default branch
**master**, pinned commit **`705501e29f8e3f2d3f29a8c185c6f845e30426d1`**
(2026-09-02), inspected 2026-09-24. Its [README][oldreadme] announces the move
to Serpantinum (the written link is malformed). GitHub reported no license,
and the inspected recursive tree contained no LICENSE/COPYING file.
License permission is **unestablished**, not implicitly MIT or AGPL.

Relevant historical paths are
`.config/hypr/scripts/quickshell/{Shell.qml,Main.qml,TopBar.qml}`,
the same tree's `network/NetworkPopup.qml`, and
`.config/hypr/scripts/qs_manager.sh`. The focused historical inspection
covered [Main.qml][oldmain] and the composition/README, not every module.

Historical Main already used a shared PanelWindow, a bar-excluding input
mask, cached content and StackView. Unlike current Main:

- Lines 387–419 define replace-enter opacity 0→1/scale 0.98→1 and
  replace-exit opacity 1→0/scale 1→0.98 transitions, with OutQuint/InQuint
  opacity easing and OutCubic scale easing.
- Lines 462–501 distinguish immediate replacement from animated replacement.
- Closing reduces animated width/height to one and sets isVisible false;
  the 200ms delayedClear actually calls `widgetStack.clear()` and marks
  currentActive hidden (lines 427–439, 521–528).
- It also binds window visibility directly to isVisible (line 76), so
  declared close animations still do not establish a fully visible exit.

Current Main instead has null StackView transitions, immediate replacement,
generation-guarded scheduling and a delayedClear that does not clear.
Historical crossfading must not be presented as current behavior. No commit
bisect or upstream rationale for those changes was researched. Adapt the
ideas only after an independent contract/test design and license review.

## Compatibility and proposed tests

Core host primitives exist in Quickshell 0.3.1: PanelWindow, Region, screen
assignment and OnDemand keyboard focus. Qt supplies StackView, Component,
Behavior and Shortcut. [nix/package.nix][package] accepts a Quickshell
dependency without pinning the MAGI version; this is not certification of
the entire application on 0.3.1/Hyprland 0.56.2. Its external scripts,
settings conventions and many dependencies are not MAGI interfaces.

All tests below are **proposed, unexecuted**, in isolated fixtures after
approval. Combine them with phase-1 T01–T07 and [K4 P1–P5](k4.md).

| ID | Experiment | Required evidence |
| --- | --- | --- |
| E1 | Identical dummy content in anchored popup, separate overlay, combined island | Frame-time comparison, seam/geometry, desktop reservation and complete exit visibility; no claim based on video aesthetics. |
| E2 | A→B→A, close/reopen during entry/exit, invalid component, delayed readiness | Latest generation wins, no infinite retries, stale focus, blank retained view or immediate unintended hide. |
| E3 | Cached and unload-after-close policies with fake async work | Item-visible changes versus native-window visibility, creation/destruction counts, stopped hidden work, preserved pending result and deliberately cleared drafts/secrets. |
| E4 | OnDemand versus tested alternative; Escape, typing, outside click, bar hole, drag | Actual keyboard recipient/restoration, click consumption, correct sibling switching, no invisible interactive surface during exit. |
| E5 | Two outputs with mixed compositor/UI scale, oversized content, simulated output loss | Initiating-output policy, bounded logical geometry, fresh scale lookup and no stale screen reference. |

## Technical comparison for MAGI

This is a design comparison, not a recommendation to replace the working
system. Source evidence is in K01–K05/S01–S07; current MAGI details remain in
[architecture](../architecture.md) and [decisions D003/D004](../decisions.md).

| Concern | A — MAGI per-plugin anchored popups | B — Separate shared menu overlay (Serpantinum Main demonstrates this) | C — Combined compact/expanded island (K4 demonstrates this) |
| --- | --- | --- | --- |
| Surfaces | Fixed bar plus each expandable popup; old/new surfaces can coexist during a switch. | Existing bar plus one selected-screen menu surface, with internal content replacement. Other specialised windows may coexist. | One large masked host per output contains both compact and expanded presentation; auxiliary plugin windows remain possible. |
| Motion | Established widen → reveal/fade; fade → retract → narrow, explicit reversal logic. Native popup size follows reveal. | Internal geometry can morph without resizing the full-output surface. Main replaces content immediately; shared ownership alone does not imply crossfade or visible exit. | Concurrent internal width/height OutBack morph with newly loaded view entry fade. No inter-window seam for the island, but unload/recreation can affect transitions. |
| Geometry | Preserves the actual pill attachment through TransformWatcher and window-relative mapping; edge adjustment is disabled. | Requires a separate origin/geometry contract to preserve attachment; Serpantinum instead uses screen-relative registry positions and a bar hole. | Geometry, compact layout and expansion share coordinates. Adopting it would change MAGI's bar surface, masking and placement model. |
| Focus/dismissal | Not yet defined for generic expandable menus; independent Wi-Fi password panel remains proven only by historical user reports. | Host can centralize focus and a catcher, but must define click consumption, bar access, activation and delayed hiding. | Plugin preferences feed host None/OnDemand/Exclusive and conditional catcher/hover policies; these may alter desktop interaction substantially. |
| Content/modularity | Existing Component interface plus explicit registry; add lifecycle/session metadata incrementally. | Modular Component registration can sit behind one host, but Serpantinum's current main registry is explicit and application-specific. Cache/transition ownership needs a contract. | Nonvisual plugin objects plus view Components offer a useful contract; priorities, shared state and cross-plugin references add policy/coupling. |
| Maintenance | Least migration risk; repeated hosts require coordinated focus and teardown tests. | Fewer main surfaces but a more complex shared state machine, masks, screen selection and cache policy; host failures affect all menus. | Shared visual logic but broader bar/menu coupling; monitor routing, reservation and auxiliary surfaces expand regression scope. |

A fourth demonstrated arrangement is Serpantinum's **specialised individual
overlay panels** for Launcher/Clipboard: separate hosts with progress-based
paint lifetime (S06). They are neither anchored PopupWindows nor Main's
shared content stack. They permit purpose-specific motion at the cost of
duplicated focus/dismissal/lifecycle coordination. This supports retaining a
special keyboard-oriented host where appropriate, not making every menu
an independent fullscreen catcher.

**Proposed adaptation order:** first review the phase-1 lifecycle contract
and test A unchanged as the control. Borrow explicit session activation,
generation guards and declarative focus/dismissal preferences independently
of surface choice. Then, if approved, compare small B/C fixtures with the
same content, input policy and output setup. Do not migrate Wi-Fi or change
MAGI's animation/positioning baseline until those results are reviewed.

Unresolved: desired click-through and bar-hole semantics; initiating versus
focused output; persistent versus unloadable plugin sessions; operation
ownership during hidden cached views; measurable construction/render cost;
and Serpantinum's license-metadata discrepancy. Neither source inspection
nor smoother-looking videos establish a winning architecture. Further
research and implementation await user approval.

[version]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/version.txt
[readme]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/README.md
[license]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/LICENSE.md
[package]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/nix/package.nix
[shell]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/Shell.qml
[daemon]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/bin/serpantinumd
[ipc]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/scripts/qs_manager.sh
[bar]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/bar/Bar.qml
[topbar]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/bar/TopBar.qml
[wifiwidget]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/bar/modules/system/WifiWidget.qml
[main]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/Main.qml
[registry]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/WindowRegistry.js
[network]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/network/NetworkPopup.qml
[launcher]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/launcher/Launcher.qml
[clipboard]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/clipboard/Clipboard.qml
[popouts]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/popouts/PopoutManager.qml
[widgets]: https://github.com/ilyamiro/serpantinum/blob/9f0e36bd9199c1d379701d052b884762b0de008b/src/quickshell/widgets/WidgetRegistry.qml
[qspanel]: https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/
[qsfocus]: https://github.com/quickshell-mirror/quickshell/blob/1a4716cde794a59928d9d9fc15f2afc7a95de360/src/wayland/wlr_layershell/wlr_layershell.cpp#L142-L146
[oldrepo]: https://github.com/ilyamiro/imperative-dots/tree/705501e29f8e3f2d3f29a8c185c6f845e30426d1
[oldreadme]: https://github.com/ilyamiro/imperative-dots/blob/705501e29f8e3f2d3f29a8c185c6f845e30426d1/README.md
[oldmain]: https://github.com/ilyamiro/imperative-dots/blob/705501e29f8e3f2d3f29a8c185c6f845e30426d1/.config/hypr/scripts/quickshell/Main.qml
