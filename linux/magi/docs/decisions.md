# MAGI — Decisions and Debugging History

Reconciled on **2026-09-26** against source HEAD
`35c282012f2d749081a3f8b1821f01bf0b8aa6ea` plus the current uncommitted
production-plugin integration. Paths are relative to
`.config/quickshell/magi/`. Earlier debugging reports remain historical;
new runtime results are labelled explicitly.

## Verified Git references

Local Git history confirms these commits and subjects:

| Commit | Subject |
| --- | --- |
| `08e06454cbba9e3f5e8b15310fb15e8e00b35ed5` | magi: checkpoint expandable menus and Hyprland integration |
| `1a3a2f0b1ed59a87f1dd414d94e0bab52f5c4141` | magi: fix expandable menu positioning |
| `e375e5ee95e82f5609c2aeb4b880b21eb38b1086` | magi: add modular expandable menu content |
| `12a6d4ea85a2d40a4a26ce83c6a3224f15337a5a` | fix(magi): enable keyboard input for wifi password prompt |
| `c46d15b71f25054e987ed1614654604d8c5480c9` | feat(magi): add status plugins and wifi network menu |

Commit existence/subjects are verified history, not proof of test outcomes.
The positioning commit's diff was also inspected for the window-reference,
watcher and mapping changes described in D003.

## D001 — Keep bar reservation independent of menus

The production combined PanelWindow begins at output-local `(0,0)`, spans
the output for painting/input masking and explicitly reserves 48 logical
pixels. Menu height, animation phase and catcher state do not change the
exclusive zone. Runtime sampling on 2026-09-26 held reservation at
`[0,48,0,0]` through real-plugin interaction and fullscreen.

Anchored rollback preserves its native 48px bar and separate PopupWindows.

## D002 — Separate menu presentation from plugin content

ExpandablePlugin owns pill expansion, popup geometry and content opacity.
`menuContent` supplies a Component to its Loader (lines 27 and 397).
Commit `e375e5e` records modular expandable content.

Volume, Wi-Fi, Bluetooth and Control Centre now adopt the shared interface
through the same settings-driven registry as other bar plugins. Plugin content
supplies its own dimensions and visual header; Bar owns Region, catcher and
native keyboard eligibility. Selected-host Loaders remain alive while closed
to preserve view-session state.

## D003 — Use explicit window-relative popup positioning

Historical problem: two expandable pills in a right-aligned Row could have
popups offset from their pills, with offsets depending on interaction order.
Earlier session notes report unsuccessful experiments involving anchor
rectangle dimensions, a watcher without changing anchoring strategy, and
an undefined root.QSWindow reference. These experiments were not reproduced
or independently established from complete historical diffs in this audit.

Verified fix: commit `1a3a2f0b1ed59a87f1dd414d94e0bab52f5c4141`, dated
2026-09-20, passes the actual bar PanelWindow to both test instances and
uses window-relative mapping with TransformWatcher.

Current rollback source at `components/bar/menu/AnchoredPopupHost.qml:23`
watches the bar contentItem and pill. Anchor x/y bindings read watcher.transform and
round `barWindow.contentItem.mapFromItem(root, 0, root.height)`. The popup
uses anchor.window, with PopupAdjustment.None. The watcher read establishes
reactivity; mapping alone does not. See the
[version-specific reference](quickshell-reference.md#f002--transformwatcher-as-a-binding-dependency).

Earlier notes report that the user stress-tested the two-menu result.
The audit confirms the saved implementation, not a new stress-test result.
Preserve this positioning baseline until a separately reviewed test
supports any replacement, including screen-edge adjustment changes.

## D004 — Retain the current animation baseline

Source: `components/bar/ExpandablePlugin.qml:41` (timings), line 92
(coordination) and lines 202, 231 and 263 (animations).

| Path | Sequence |
| --- | --- |
| Full opening | Widen 180ms, then reveal vertically 140ms while content fades in over 90ms concurrently. |
| Full closing | Fade content out 70ms, retract vertically 120ms, then narrow 160ms. |

All animations use OutCubic. The phase values are collapsed (0), widening
(1), revealing (2), open (3), fading out (4), retracting (5), narrowing (6).
Popup visibility follows revealedHeight > 0, including retraction.

Interrupted paths stop the animations and use current width/height/opacity.
Opening at full width proceeds directly to reveal; closing before a reveal
proceeds to narrowing. Reopening with a partly narrowed but still revealed
panel first retracts it. Consequently, full-path timings are not universal
interaction durations. MenuController sets the requested ID immediately;
outgoing and incoming animations are not serialized.

Preserve timings and sequencing during unrelated migrations. Rapid-switch,
reversal and lifecycle behavior still require dedicated tests.

## D005 — Preserve Wi-Fi semantics during host migration

Historical sessions reported working scanning, connections and password
entry. Current source confirms the implementation, but the audit performed
no network or keyboard test. The password-focus fix is recorded in commit
`12a6d4e`; current password-window code begins at
`plugins/bar/wifi/Wifi.qml:479`.

The 2026-09-26 migration kept `services/Network.qml` unchanged, moved the
network browser to `WifiMenuContent.qml`, and retained a separate
`WifiPasswordWindow.qml`. A secured selection closes and fully retracts the
combined browser before the password PanelWindow receives focus; a candidate
keeps scanning active through the handoff.

The operator passed known/open/PSK connections, scanning, radio control,
bounded list scrolling, masked entry, Enter/Connect/Cancel, incorrect-password
feedback, retry and successful connection. This satisfies the migration
equivalence checkpoint on the tested network environment.

## D006 — Combined host is the production plugin architecture

`MenuHostSelector.qml` instantiates only the selected adapter. Production
selects `CombinedMenuHost`; `AnchoredPopupHost` remains rollback. Bar owns
one registered active pill, input Region, consumed outside-click catcher and
OnDemand eligibility. MenuController remains a semantic string controller.

The production runtime and bounded anchored fallback both passed on
2026-09-26. New plugins target the combined architecture; retiring the
fallback requires a later decision.

## D007 — Share durable system state across dedicated menus and Control Centre

Audio, Bluetooth, brightness, network and battery state live in services.
Dedicated menus and Control Centre read and mutate the same service objects.
Wi-Fi selected/pending/error state remains plugin-owned because it belongs to
the browser/password interaction session.

Bluetooth connect/disconnect is offered only for paired/bonded devices.
Battery is displayed only when BlueZ exposes it. Pairing-agent UX and
device-specific modes are deferred.

## Open decisions

- Multi-output ownership, hotplug, fractional scaling and row collisions.
- Final render-driven Bluetooth name/header presentation and optional battery.
- Bluetooth pairing-agent UX and device-specific features.
- Wi-Fi timeout, enterprise-security handling and adapter failover.
- Settings validation/persistence and final theme/styling adoption.
- Stabilization period and criteria for retiring anchored fallback.


## D008 — The status cluster is one expandable composition

On 2026-09-26 the operator clarified the render: independent compact pills
are the collapsed state of one shared surface. Combined production now uses
`SharedStatusSurface.qml`, persistent plugin visuals/bodies and internal module
navigation. This supersedes D006's per-plugin combined presentation, while
retaining its native window, fixed reservation, focus, dismissal and fallback.

The actual right Row stays alive inside the expanding silhouette. Module
changes fade/resize in place; they do not collapse the shared surface.
MenuController adds only semantic ID history. Wi-Fi's shared closing phase
still gates its separate password window. No device/network service was
rewritten. Source/static/startup checks are complete; operator visual review
and interaction regression checks remain pending for this new presentation.


### D008 follow-up — settle dependent state before starting transitions

The first shared-surface review confirmed its composition but exposed stuck
collapse and missing reopened content. The real-component regression reproduced
selection handlers reading the previous derived `requestedOpen` value. Defer
selection and compact-width synchronization with `Qt.callLater`; do not change
animation timings or add a forced-collapse workaround. The 41-step offscreen
regression passes after the correction. The operator subsequently passed all
three requested rechecks: complete collapse, repeated/rapid Control Centre
reopening and in-surface Bluetooth detail/Back navigation. This accepts the
bounded structural checkpoint, not an unperformed full service/focus/fullscreen
regression. The correlated live log remained clean.


## D009 — Freeze architecture; measure the render before styling

The 2026-09-26 literal-render pass freezes the accepted shared-surface lifecycle.
The original 6000×15000 render is measured in source pixels, with an explicitly
chosen logical scale rather than treating source pixels as display pixels.
Control Centre is the first reference consumer of scoped RenderTokens and
per-view presentation fields; other detail styling remains unchanged. Missing
custom assets/profile/media/action capabilities are recorded deviations, not
invented controls or empty padding. The 44-step geometry/lifecycle regression
passes. The subsequent CC screenshot shows the reference tile/slider treatment;
the operator confirms Wi-Fi/Bluetooth detail-return height restoration. Full
literal fidelity remains limited by the explicitly omitted modules/assets.
