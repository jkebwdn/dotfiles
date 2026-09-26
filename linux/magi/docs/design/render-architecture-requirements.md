# MAGI render: architecture requirements

Status: **design direction**, extracted 2026-09-25 from the user-supplied
`/home/jkebwdn/Downloads/Magi Quickshell Render.png`. The render has not been
copied into the repository or converted into a styling specification, and this
document does not claim that its colours, spacing, type, radii, icons or exact
dimensions are approved implementation values.

The current implementation and validated host experiment are described in
[architecture.md](../architecture.md) and
[architecture-experiment.md](../research/architecture-experiment.md). The
production migration proposal is in
[combined-surface-migration-plan.md](../research/combined-surface-migration-plan.md).

## Bar composition

- The bar is composed from compact, independent pills rather than one
  monolithic visual block. Placement remains configurable through MAGI's
  left, centre and right plugin lists.
- The right side supports status modules including Volume, Wi-Fi, Battery and
  Control Centre. Bluetooth may also have a compact bar representation.
- A collapsed pill's width belongs to the plugin. A simple icon-only state can
  remain narrow; a richer state, such as a connected Bluetooth device with
  status or battery information, can use a wider pill. The host must lay out
  either form without changing its window model.
- The bar reserves a fixed 48 logical pixels. A pill may change its horizontal
  size, but an expanded menu must not increase the desktop reservation.

## Shared expansion and internal navigation

Clarified by the operator on 2026-09-26 after re-inspecting the original render:
independent compact status items form the collapsed state of **one** shared
expanded surface. Earlier per-pill expansion interpretations are superseded.

- The right status cluster becomes the surface's header/status composition;
  it must not remain untouched above a duplicate set of controls.
- Volume is icon-only in the bar. Battery carries the percentage. Bluetooth
  can show its connected name at a wider collapsed width; no fake battery.
- Wi-Fi, Bluetooth, Volume and Control Centre are internal views of this
  surface. Selecting another view keeps the surface open and transforms its
  dimensions/content. Control Centre detail navigation does not return to the
  bar or locate another pill. Back navigation should return within the surface.
- Prefer actual persistent plugin visuals. Coordinated equivalent visuals are
  acceptable only without visible duplication or jumps.
- Opening widens then reveals/fades; closing fades, retracts, narrows. Internal
  view changes have their own interruption-safe fade/reflow without collapse.
- Bodies remain plugin-owned with content-specific dimensions and bounded
  Wi-Fi/Bluetooth lists. Control Centre is a modular view of the same surface.
- Control Centre Volume/Brightness controls use integrated icons on sliders,
  without textual Volume/Light headers. Fewer labels and softly grouped
  surfaces should follow the render's spatial hierarchy.

See [shared-status-surface.md](shared-status-surface.md) for the current
implementation proposal/checkpoint and its unverified cases.

## Window, input and fullscreen behavior

- Expanded UI paints over application windows. Only the fixed top bar strip
  reserves desktop work area, regardless of menu size or dismissal state.
- Clicking outside an open transient Control Centre, Wi-Fi, Bluetooth or
  Volume menu closes it once and consumes that click. It must not also focus,
  activate, scroll or otherwise operate the client below.
- A sibling pill remains above the dismissal catcher so one direct click can
  switch menus.
- Compositor fullscreen hides the shell surfaces. Hidden shell regions do not
  receive pointer or keyboard input. Leaving fullscreen restores coherent
  geometry, menu state and focus behavior; a menu may retain its internal
  state while hidden.

## Architectural acceptance conditions

The production design therefore needs all of the following:

1. one top-edge surface that owns the bar's exact 48px reservation;
2. plugin-configurable placement and collapsed/expanded dimensions;
3. one shared expanded composition and one interactive body at a time;
4. persistent plugin-owned status visuals recomposed into the shared header;
5. a native input Region that follows the bar, selected menu and consuming
   catcher state; and
6. bounded content scrolling inside the plugin, independent of exclusive-zone
   geometry.

The render does not resolve service ownership, QML object lifetime, fallback
window geometry, multi-output routing or animation interruption. Those remain
implementation and validation concerns covered by the migration plan.
