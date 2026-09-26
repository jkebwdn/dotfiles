# Shared status surface — structural review checkpoint

Design correction, 2026-09-26. Re-inspected the original
`/home/jkebwdn/Downloads/Magi Quickshell Render.png`, including the detail-view
status/navigation strips and Control Centre's icon-over-slider controls.
The operator's clarification is authoritative: independent compact status
items are the collapsed composition of **one** expanded surface, not four
independent expanding menus. Earlier per-pill interpretations in the gap
analysis and migration documents are superseded for combined production mode.

## Minimum presentation/state refactor

- `SharedStatusSurface.qml` contains the existing configurable right Row and
  owns one silhouette, opening/closing phase, displayed module and view change.
  The actual plugin items remain alive in that Row: it shifts inward as the
  surface widens and individual backgrounds blend into the shared background.
  There is no duplicate status row and no native-window reparenting.
- Registered plugins continue supplying compact visuals, dimensions and body
  Components. Combined mode disables their individual adapters and animation
  drivers. Their bodies stay loaded in the shared surface, including when
  hidden, to preserve state and Wi-Fi connection callbacks.
- Selecting another module leaves the surface open: fade out the old body,
  retarget size from its current geometry, then reveal the selected body.
  Rapid requests target the latest semantic ID. Hidden/outgoing bodies cannot
  receive input. Close still fades, retracts and narrows.
- MenuController retains only IDs and navigation history. Control Centre
  secondary actions navigate within the surface; Back returns to the previous
  ID. Direct status selection resets history. No QML Items enter the singleton.
- Bar retains the native window, exact 48px reservation, Region, consuming
  catcher and OnDemand policy. The Region now follows the shared surface.
  Anchored mode keeps the existing per-plugin PopupWindow/TransformWatcher path.
- Wi-Fi mirrors the shared closing phase before handing focus to its separate
  password window. No Network service or connection operation changes.

## Render constraints for this checkpoint

Volume is icon-only; Battery carries the percentage. Wi-Fi stays compact;
connected Bluetooth may be wide. Shared status items are the expanded header,
with Back where applicable. Detail bodies retain network/device identity.
Control Centre sliders have icons drawn over their tracks, with no Volume/Light
text headings. Services and unimplemented capabilities do not determine new
compact-bar information or justify invented controls.

## Scope and validation

First review: collapsed → Control Centre; collapsed → Wi-Fi; Control Centre →
Bluetooth detail without collapse; Back; close/reopen and interrupted switching.
The configurable default right group is the visual target. Plugins moved to
left/centre remain functional external triggers for this same surface; custom
cross-section visual migration/collision policy is not validated here.
Multi-output, fractional scaling and hotplug remain unverified.

Static checks and compositor/log measurements do not establish visual or
interaction acceptance. Pause for operator screenshots after launch. Do not
polish all detail views before the shared composition is accepted.


## Implementation/startup evidence

Implemented and launched on 2026-09-26 with Quickshell 0.3.1, instance
`pko33ozylt`, PID 171817. Hyprland reports one MAGI layer at (0,0), logical
1920×1080, scale 2, reservation [0,48,0,0]. Runtime startup log is clean.
`qmllint` exits 0 with the installed metadata warning about PanelWindow;
`git diff --check` passes. Closed-state capture confirms icon-only Volume and
Battery percentage. No pointer injection or system-service test actions ran.

The three open/navigation flows, interruption, outside-click/focus behavior,
password handoff and fullscreen restoration still need operator confirmation
for this changed presentation. Prior acceptance does not validate this refactor.


## Collapse/reopen correction — 2026-09-26

Operator screenshots confirmed that the cluster reads as the shared surface,
but showed incomplete collapse and intermittent missing Control Centre content.
This is partial visual confirmation, not complete interaction acceptance.

The windowless real-component regression reproduced stale derived-binding
reads in `onRequestedModuleChanged`: the handler could take the prior open/close
branch, leaving phase 2 with nonzero height and zero content opacity. The same
ordering issue affected `targetWidth` after compact-width changes. Both handlers
now use `Qt.callLater` to act after dependent bindings settle and coalesce
same-turn requests. Phase durations, services and native-host policy are unchanged.

`tests/shared-status-surface/run.py` stages the actual component in an offscreen
disposable Quickshell config with dummy bodies. Initial lifecycle checks failed
before the fix. The final 41-step sequence passes: full close/reopen, switching
without collapse, reversal during phases 1/2/4/5/6, compact-width changes,
same-turn requests and retained bodies. This does not test pointer/focus or
network behavior. `qmllint` for the changed QML/test and `git diff --check` pass.

Reloaded instance `gup3tb0zlt`, PID 173464: clean startup log, one 1920×1080
layer at (0,0), reservation [0,48,0,0]. Operator collapse/reopen and internal
navigation recheck was pending at launch; the result follows below.


## Bounded operator acceptance — 2026-09-26

The operator reported **all checks passed** after the correction:

1. Closing Wi-Fi/Control Centre returns completely to compact status pills.
2. Repeated and rapid Control Centre opening/closing reliably displays content.
3. Control Centre → Bluetooth detail → Back keeps the shared surface open.

Together with the prior confirmation that the status cluster becomes the
surface, this accepts the structural visual model and this bounded interaction
checkpoint. The correlated live log for `gup3tb0zlt` remains clean. No new
compositor measurement is inferred from this report; the latest measured
baseline remains one layer at (0,0), 1920×1080 and 48px reservation.

This report does not claim new full password/network, Bluetooth-device,
keyboard-focus, fullscreen, anchored-fallback, multi-output or fractional-scale
validation. Those remain separate from the 41-step lifecycle regression and
this operator checkpoint. No further visual polishing was performed to record
acceptance.
