# MAGI — Decisions and Debugging History

Reconciled on 2026-09-24 against source HEAD
`e375e5ee95e82f5609c2aeb4b880b21eb38b1086`. Paths are relative to
`.config/quickshell/magi/`. Earlier debugging and user test reports are
preserved as historical reports; the read-only audit did not reproduce them.

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

Retain the 48px bar and separate menu windows so menu expansion does not
change bar reservation. `components/bar/Bar.qml:18` uses Auto exclusion and
line 27 sets implicitHeight to 48. Expanded PopupWindow height depends on
revealedHeight instead (`components/bar/ExpandablePlugin.qml:376`). This
separation is source-confirmed; tiled-window behavior was not retested.

## D002 — Separate menu presentation from plugin content

ExpandablePlugin owns pill expansion, popup geometry and content opacity.
`menuContent` supplies a Component to its Loader (lines 27 and 397).
Commit `e375e5e` records modular expandable content.

Current adoption is limited to inline Settings and Controls test menus in
`components/bar/Bar.qml:162` and `:203`. Wi-Fi, volume and battery still use
their existing implementations. A shared interface for future plugins is
the direction, not a completed migration. Content lifetime, size negotiation,
focus and lifecycle callbacks remain undecided.

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

Current source at `components/bar/ExpandablePlugin.qml:330` watches the
bar contentItem and pill. Anchor x/y bindings read watcher.transform and
round `barWindow.contentItem.mapFromItem(root, 0, root.height)`. The popup
uses anchor.window, with PopupAdjustment.None. The watcher read establishes
reactivity; mapping alone does not. See the
[version-specific reference](quickshell-reference.md#f002--transformwatcher-as-a-binding-dependency).

Earlier notes report that the user stress-tested the two-menu result.
The audit confirms the saved implementation, not a new stress-test result.
Preserve this positioning baseline until a separately reviewed test
supports any replacement, including screen-edge adjustment changes.

## D004 — Retain the current animation baseline

Source: `components/bar/ExpandablePlugin.qml:33` (timings), line 77
(coordination) and lines 170, 199 and 228 (animations).

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

## D005 — Preserve Wi-Fi until its replacement is verified

Historical sessions reported working scanning, connections and password
entry. Current source confirms the implementation, but the audit performed
no network or keyboard test. The password-focus fix is recorded in commit
`12a6d4e`; current password-window code begins at
`plugins/bar/wifi/Wifi.qml:479`.

Retain known/open/PSK connection paths, scanning across both windows,
connection feedback, duplicate-attempt guards, masked input, Enter/Connect,
Cancel and input clearing. Do not replace the flow until equivalent
connection and keyboard tests have been reviewed and passed.

## Open decisions

- Switching coordination, outgoing surface lifetime and instance cleanup.
- Keyboard focus, Escape and outside-click dismissal.
- Screen association, edge adjustment and row collision policy.
- Content sizing/lifecycle and nested Bluetooth/Control Centre navigation.
- Wi-Fi service/UI ownership, pending-operation lifetime and adapter failover.
- Settings validation/persistence and shared theme adoption.

Record source-backed research before resolving these questions. No new
architecture or implementation change is approved by this reconciliation.
