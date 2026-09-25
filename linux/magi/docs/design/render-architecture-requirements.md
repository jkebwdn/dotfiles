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

## Expansion and visual continuity

- An expanded menu visually originates from the pill that opened it. Its
  horizontal origin follows the pill, including when configured placement or
  neighbouring pill widths move that pill.
- The collapsed pill and the expanded menu read as one transition. The plugin
  icon or header remains visually continuous while the pill widens and the
  menu reveals below it; the host must not replace it with an unrelated,
  host-owned header.
- Different plugins may request different collapsed widths, expanded widths
  and menu heights while using the same transition and host lifecycle.
- The established motion order remains widen, reveal with content fade, then
  open; closure remains content fade, vertical retract, then horizontal
  narrowing. Styling work may refine presentation later without changing this
  lifecycle implicitly.

## Menu families and content

- Wi-Fi, Bluetooth and Volume use dedicated transient menus opened from their
  respective status pills.
- Control Centre is a larger modular composition, but it uses the same menu
  request, geometry, focus, dismissal and host contract as the smaller
  transient menus. Its internal grid/modules do not justify a second window
  architecture.
- Wi-Fi and Bluetooth network/device lists have bounded menu heights and
  scroll within that bound. List growth must not grow the native window or
  exclusive zone without limit.
- Menu content remains plugin-owned. The common host supplies geometry,
  clipping, lifecycle, focus routing and dismissal, while each plugin supplies
  its header/content and its own size requirements.

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
3. one selected menu host and one interactive menu at a time;
4. a plugin-owned pill/header visual that can remain above the shared menu
   reveal rather than being duplicated by a generic frame;
5. a native input Region that follows the bar, selected menu and consuming
   catcher state; and
6. bounded content scrolling inside the plugin, independent of exclusive-zone
   geometry.

The render does not resolve service ownership, QML object lifetime, fallback
window geometry, multi-output routing or animation interruption. Those remain
implementation and validation concerns covered by the migration plan.
