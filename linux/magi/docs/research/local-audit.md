# Initial local codebase audit

Date: **2026-09-24**. Snapshot: `e375e5ee95e82f5609c2aeb4b880b21eb38b1086`.
Scope: `.config/quickshell/magi/`, existing documentation, local Git history
and installed versions. The initial audit was read-only; no UI, radio,
connection or restart tests were performed. This report was subsequently
created during the approved documentation-only reconciliation.

## Evidence and compatibility

Source references below are repository-relative, inspected on 2026-09-24
at the snapshot above. They establish code structure, not live test results.
Installed Quickshell is 0.3.1 (Arch 0.3.1-1; blank binary revision), Hyprland
0.56.2 (Arch 0.56.2-3, commit `efb50993780079460b0cbed1363e2166a2de1d9f`),
Qt base 6.11.2-3 and Qt declarative 6.11.2-2. Existing-process versions were
not established. See [API evidence and URLs](../quickshell-reference.md)
for the limited official-documentation verification performed in the audit.

## Verified source findings

| Source under `.config/quickshell/magi/` | What it demonstrates / relevance |
| --- | --- |
| `shell.qml:6`; `components/bar/Bar.qml:15` | One ShellRoot creates one 48px top bar; no explicit per-screen instantiation. Menus have separate surfaces. |
| `components/bar/Bar.qml:47`, `:107`, `:129`, `:250` | Six explicit registry entries, configurable placement via Repeaters/Loaders; no plugin discovery. |
| `settings.json:3`; `services/Settings.qml:17` | Catppuccin, clock/date left, workspaces centre, Wi-Fi/volume/battery right; JSON watch/reload with no explicit save path. |
| `services/qmldir:1`; `services/Audio.qml:11`; `services/Battery.qml:10` | Five service singletons; PipeWire audio and UPower battery wrappers. |
| `plugins/bar/workspaces/Workspaces.qml:16`, `:83` | UI directly consumes Hyprland workspaces and dispatches focus; service ownership is incomplete by design today. |
| `components/bar/Bar.qml:162`, `:203` | Settings and Controls are unconditional inline test menus, not registry plugins. |
| `services/MenuController.qml:10` | One requested menu ID, no transition queue; Wi-Fi state is separate. |
| `components/bar/ExpandablePlugin.qml:33`, `:77` | Staged and interruptible width/reveal/fade state machine. Opening fade overlaps reveal; closing stages are sequential. |
| `components/bar/ExpandablePlugin.qml:330`, `:346` | Window-relative bottom-left mapping reacts through TransformWatcher; adjustment disabled. Preserve this baseline. |
| `components/bar/ExpandablePlugin.qml:397` | Component/Loader content with fixed host dimensions, padding, opacity and clipping; no explicit unload-on-close or lifecycle contract. |
| `services/Network.qml:69`, `:96`, `:120` | Known/open/PSK connection wrappers, first-adapter selection and connected-network observation. |
| `plugins/bar/wifi/Wifi.qml:47`, `:195`, `:348`, `:479` | UI-owned selection/pending/errors, scan visibility coordination, delegate-owned result listeners and separate focusable password window. |
| `theme/Theme.qml:10`; `components/bar/ExpandablePlugin.qml:71` | Semantic palettes exist, but expandable tests use hardcoded colors; palette persistence comment exceeds implemented saving. |

Full responsibilities and preservation requirements are in
[architecture](../architecture.md). Exact animation timings and historical
commit references are in [decisions](../decisions.md).

## Corrections to the initial documentation

- Clarify explicit registration versus configurable instantiation.
- Distinguish inline test content from migrated production plugins.
- Distinguish requested active menu from visible/animating surfaces.
- Record concurrent opening fade/reveal and the Loader's missing lifecycle
  contract; do not assume hiding destroys loaded content.
- Document Wi-Fi's UI-owned connection state and separate keyboard window.
- Record installed versions and Git references. Historical reports of
  working Wi-Fi and successful stress tests are not newly reproduced tests.

## Unanswered questions and required tests

These are source-derived concerns, not observed failures:

1. Can every animation phase reverse or switch without stale geometry or
   state? How long may outgoing and incoming surfaces overlap?
2. How should content be loaded/unloaded, sized, focused and dismissed?
   How should destruction clear a requested menu ID?
3. What happens on narrow/scaled/multiple outputs, at screen edges, and
   when the separately anchored password window chooses a screen?
4. Do legacy item-anchored popups follow pills moving beside an expansion?
5. Can Wi-Fi pending state become stranded if a delegate disappears or
   radio/device state changes before result delivery? What timeout is needed?
6. How should an already-existing second adapter take over after removal
   of the selected one? Which authentication modes beyond open/PSK are supported?
7. What settings validation, startup ordering and persistence are required?
8. Is the Hyprland dispatch expression compatible in all intended scenarios?
   It was inspected, not invoked during this audit.

Before Wi-Fi migration, review acceptance tests for known/open/PSK paths,
wrong-password/retry, scanning through selection and cancellation, Enter and
button submission, masked/cleared input, pending feedback, radio changes,
network disappearance and keyboard focus. Preserve the existing flow until
equivalence is demonstrated.

## Next step

Research official Quickshell 0.3.1 window/focus/lifecycle contracts first,
then networking lifetime and the [planned reference projects](README.md).
External investigations and runtime tests remain pending approval. No
external-project implementation or license findings are claimed here.
