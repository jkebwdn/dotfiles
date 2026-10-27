# Phase 14A — System Tray: native acceptance

Date: 2026-10-26. Baseline: `1e6b68dd713361c9718d1ab1f282274eee37380c`,
`magi: detach desktop application launches`; verified HEAD/origin/main `0 0` before
creating `/home/jkebwdn/magi-phase14a`. Schema remains **21**.

## Accepted native outcome — 2026-10-27

The operator explicitly accepted Phase 14A and authorized final regression tests,
exact-file staging, `magi: add system tray`, and a normal guarded push. No next
phase is authorized. The following native results supersede the historical review
and intermediate pending checkpoints retained later in this record.

| Gate | Result |
| --- | --- |
| Watcher ownership | Real-host preflight found neither KDE nor freedesktop watcher owned, no conflicting host/Bar process. |
| Placement | Operator placed System Tray first in the right status region. Other modules/styles are unchanged; default migration remains Available only. |
| Empty state | No blank pill when no application is registered. |
| Mullvad | Registers automatically; recognisable untinted icon and useful tooltip; item survives Super+Q; left click restores GUI. |
| Native menu | Right click works after the QApplication startup correction; operator accepted normal native menu behaviour. |
| Second application | Steam tray tested, including exit/removal and restart/reappearance. |
| Keyboard | Tray IPC returned true; operator checked the requested Tab/Enter/Menu or Shift+F10/Escape controls and accepted them. |
| Running-app reload | Same process reloaded at 11:12:32; Mullvad survived with no unexpected behaviour. |
| Launcher | Detached-stream implementation unchanged; full delayed-write regression passed after integration at 127.3 seconds. Final rerun recorded below. |
| Main output | Single attached display passed; physical multi-monitor tray acceptance explicitly deferred. Synthetic hotplug/reselection coverage retained. |
| Overflow/statuses | Synthetic overflow, Passive and NeedsAttention coverage retained; no apps installed or VPN state changed solely to manufacture cases. |
| Icons/background | Application artwork remains untinted/opaque; shared background alpha/blur implementation retained. |
| Persistence | Schema 21; exact Settings comparison shows only deliberate Tray placement. No runtime app IDs/titles/items persisted. |
| Limitations | Legacy XEmbed unsupported; uncommon native statuses, crowded native overflow and physical multi-output remain outside the exercised native gate. |

Native menus require `//@ pragma UseQApplication` at the top of root shell.qml.
The application class changes only on process startup. The initial live failure,
one-time restart correction and recovery from the private restart-helper parsing
error are retained below. No application-specific integration was added.

The 42-path allowlist excludes operator Settings, icon artwork, Hyprland, Ghostty,
GTK, Yazi, lock/runtime state and generated application themes. The application
launcher backend is byte-identical to the accepted baseline.

## Historical architecture review and implementation record

The initial isolated-pass sections and intermediate checkpoints below record what
was known at each stage. Their pending/native-gate wording is historical; the
accepted outcome above is current. Physical multi-monitor testing stays deferred.

## Motivation and boundaries

Background applications need a visible StatusNotifier/AppIndicator interaction
point after their ordinary window closes. Mullvad motivated this work but is not
part of the implementation. The already accepted launcher stream-lifetime fix is
byte-identical to the baseline. No VPN CLI, daemon API or application-specific
logic is involved. A tray cannot promise to restore an application's window.

## Capability and watcher audit

Installed `quickshell --version` reports 0.3.2. Inspected local
`/usr/lib/qt6/qml/Quickshell/Services/SystemTray/quickshell-service-statusnotifier.qmltypes`
and `Quickshell/quickshell-core.qmltypes` on 2026-10-26. These installed metadata
files expose `SystemTray.items`, reactive id/title/icon/status/category/tooltip
properties, hasMenu/menu/onlyMenu, activate, secondaryActivate, scroll(int,bool),
and display(QObject,int,int). The enum order is Passive=0, Active=1,
NeedsAttention=2. `QsMenuAnchor` exposes open/close, visible, a PopupAnchor, and a
menu-destruction handler. Metadata establishes API availability, not native safety.

Cross-checked the official [SystemTray](https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.SystemTray/SystemTray/)
and [SystemTrayItem](https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.SystemTray/SystemTrayItem/)
reference (0.3.0 documentation, checked against installed 0.3.2 metadata).
The singleton is the tracking entry point; icon is already an Image-compatible
source. [QsMenuAnchor](https://quickshell.org/docs/v0.3.0/types/Quickshell/QsMenuAnchor/)
positions native platform menus. [PopupAnchor](https://quickshell.org/docs/v0.3.0/types/Quickshell/PopupAnchor/)
can derive the parent window and rectangle from an item. Its position is sampled
when opening, not continuously tracked. [QsMenuOpener](https://quickshell.org/docs/v0.3.0/types/Quickshell/QsMenuOpener/)
exposes menu children; MAGI deliberately does not use it to rebuild app menus.
Upstream v0.3.2 source fetches failed, so no source-level destruction guarantee is
claimed. No third-party implementation or artwork was copied.

The [StatusNotifier specification](https://specifications.freedesktop.org/status-notifier-item/latest-single/)
separates applications, watcher and visual hosts. Multiple visual hosts are not
inherently a protocol conflict; MAGI still uses exactly one tracking singleton.
No custom watcher or raw D-Bus menu/action implementation is added. This phase
supports the built-in StatusNotifier/AppIndicator path, **not legacy XEmbed**.

**Host ownership remains unknown.** `busctl --user list --no-pager` returned
`Operation not permitted`. `ps` exposes only sandbox processes, so no conclusion
about stale Waybar or a host outside this namespace is valid. Before native
integration, inspect the real session's `org.kde.StatusNotifierWatcher` (and the
freedesktop equivalent if present), registered hosts and owning PID. Stop if there
is a conflicting owner; do not kill or replace another host speculatively.

## Shared model and lifecycle

`TrayService.qml` is the only reference to `SystemTray.items.values`. It subclasses
`TrayModel.qml`; per-output Bars consume that one engine-wide singleton. The
model holds live QObject references, not copies of title/icon/menu properties.
It reacts to source-list changes without polling and retains surviving items in
order. Simultaneous new arrivals are sorted by id/title; later arrivals append.
Status/title changes never reorder survivors. Restarted items join as new arrivals.
No process, activation or menu action is triggered by model construction/reload.

All statuses remain available. Passive items are visible while their stable slot
fits and otherwise enter overflow like any other item. NeedsAttention adds a
small semantic yellow indicator; it does not flash, reorder or tint artwork.
Unknown statuses also remain accessible. Category is not exposed as configuration.

Removal removes delegates/spacing. Delegate disappearance, visibility loss and
menu availability loss close an open QsMenuAnchor. A repeated open/close is guarded
because the installed anchor logs errors for invalid repeated operations. Output
loss closes overflow; the shared service remains independent of Bar instances.
Actual removal of a D-Bus menu handle while a platform popup is open is a **native
gate**, not established by the fake action test.

## Composition, migration and multiple outputs

The module ID is `tray`, labelled **System Tray** in Settings → Bar. It is added
to the existing known-module catalogue; the existing schema-wide `seen` filter
and `Settings.placeBar` enforce singleton placement across Left/Centre/Right.
Available is derived from unplaced known IDs, not separately persisted.

**Recommendation for review: Available only.** Default arrays and migrations are
unchanged. A private copy of current operator Settings passed exact full-document
migration equality, including every Bar placement. No tray runtime data, per-app
preferences, new global appearance settings or new schema fields are introduced.

**Recommendation for review: main-output only.** `BarFleet` retains its established
main-screen selection; `SurfaceOrigin.mainScreen` controls tray visibility. Other
Bars have no visible tray group. Hotplug/reselection moves presentation without
restarting the service. Originating-item anchors derive their own window rather
than using monitor 0. There is no all-output toggle in this first pass.

The existing Bar IPC `open("tray")` / `toggle("tray")` route to the main Bar,
regardless of focused secondary output, and expose all items for keyboard access.
The existing `close()` entry point also dismisses tray overflow. No operator
shortcut was added. Native keyboard acquisition through layer-shell remains in
the acceptance checklist.

## Icons, actions and accessibility

`TrayItem.qml` feeds the item's icon string directly to Qt Image, allowing the
Quickshell-resolved URL/provider format without filename assumptions. It never
uses MAGI's semantic icon mapper or applies a tint/opacity effect. Image failure
or an empty source shows a small outlined generic application placeholder.
Identity remains available through accessible name and tooltip.

Synthetic rendering covers data-URL SVG and file-URL PNG plus runtime source
updates. A theme-name provider test could not resolve its icon in the isolated
offscreen environment and was not counted as native provider validation.
Actual app theme, symbolic and pixmap-backed provider sources must be checked
with real items later; MAGI delegates those representations to Quickshell.

- Left click / Return / Enter / Space: activate, or native menu for onlyMenu.
- Right click / Menu key / Shift+F10: native menu when hasMenu and menu exist.
- Middle click: secondaryActivate; unsupported methods are harmless.
- Wheel inside the icon target: forward integer Qt angle deltas on each nonzero
  axis with the horizontal flag. No invented degrees conversion. Outside icon
  targets, the overflow list retains its normal scrolling.
- Tooltip: title and description, falling back to title/id; plain text, bounded
  content and wrapping to 320px, no blank shell. Application labels are not markup.
- Accessible name: title, id, then “Background application”. Tab focus and visible
  focus border are provided. The keyboard IPC surface includes all items.

The minimum horizontal target is 30px (36px in overflow), with the existing 28px
Bar pill height; glyph size follows the shared status-icon setting. Tooltips use
normal Qt Controls timing with MAGI palette/roundness. Native app menu contents
remain owned/rendered by Quickshell's platform menu abstraction.

## Geometry, surfaces and native menu anchors

One status-family pill encloses the compact group. System Tray selection opens
shared Status pill controls in the Bar Designer; no application item exposes
invented per-app colour/accent controls. The preview is deterministic synthetic
VPN/sync/utility/attention artwork and overflow, never the operator's real list.

The width budget is 18% of output width minus configured horizontal insets, capped
at 240px and floored at one target plus padding. Slot count follows current target
size; an overflow slot is reserved when needed. This is a bounded width-aware
budget, not a global Bar packing algorithm. Existing Bar collision policy remains
unchanged. Extremely crowded layouts may still hide existing sections according
to that policy; tray never grows the reservation or Bar vertically.

Overflow reuses the full-window Bar host, outside-click catcher, Escape handling,
keyboard-focus policy, rounded surface palette and painted blur regions. It uses
shared background-only alpha, semantic border role/width and a scrolling list.
Foreground icons/text remain opaque. Width/height are bounded to the output.
Its position derives from the originating tray group and Top/Bottom Bar geometry.
The reservation remains **48 logical px + edge offset**.

Each item owns a QsMenuAnchor with the actual item.menu, anchor.item pointing to
the originating control, and Top/Bottom edges and gravity. This handles the
parent-output origin and inset/offset naturally. Geometry moves while a native
menu is already open remain a platform acceptance concern because anchors are
snapshots. Native placement and menu-handle destruction must pass before live
acceptance; do not replace the application menu if the platform path fails.

## Validation and honest limits

Commands run from `linux/magi`, all under temporary config/state and offscreen
rendering. Phase14A explicitly substitutes the protocol source with synthetic
items. The private operator fixture remains under `/tmp`, outside this inventory.

- `tests/phase14a/run.py`: action/model/schema tests, real pointer and keyboard
  dispatch to fake items, image/title/status changes, empty/malformed/long data,
  arrival/removal/restart, overflow, actual Designer drag/drop into all regions,
  singleton/family controls, synthetic hard reload and captured previews.
- `tests/phase14a/fleet.py`: reuses Phase10B isolated native-window/service adapters
  with production Bar/BarFleet; main/secondary visibility, placement, shared source,
  output removal/reappearance, keyboard route, overflow dismissal and reservation.
- Phase12C Bar, Phase10B multi-output, Settings store/schema and presentation,
  Phase12F, Phase12G backend/presentation/lifecycle/global-blur, Phase12H backend
  and presentation, Phase13A/B model/backend and presentation, runtime visuals.
- Launcher lifecycle/backend/presentation/search/schema. The old path reproduces
  EPIPE. The accepted path survives Hub/content teardown, hard reload, shell exit
  and a healthy delayed write at **127.3 seconds**. Launcher source is unchanged.
- `git diff --check`; exact protected-file content/symlink snapshot comparison.

Existing Phase10B/12C schema assertions incorrectly expected 18/19 on baseline
schema 21. Only those stale assertions were corrected; production migrations were
not changed. Offscreen harnesses allow their established unavailable IPC/window-mask
warnings. The reload harness additionally identifies Quickshell's own unavailable
layer-shell reload-toast warning; the tray rebuild and no-action assertions pass.

Synthetic menu tests record requests; they do not create an application D-Bus menu.
No claim is made about a live watcher, real pixmap icon decoding, real tray-app
rediscovery after shell reload, compositor menu positioning, native focus or
Mullvad restoration. Those are pending native acceptance, not silent successes.

## Native acceptance gate, after architecture approval

1. Read the actual session bus watcher ownership/registered hosts and process list.
   Resolve any conflict before MAGI is allowed to reference SystemTray live.
2. Deliberately place System Tray through Bar Settings; check native Top/Bottom,
   inset/offset, focus, outside/Escape, and main-output routing.
3. Launch Mullvad through MAGI. Verify GUI and tray item; close GUI with Super+Q;
   verify process and tray remain. Try primary activation, native context menu,
   status/connect/disconnect entries if provided, and no delayed EPIPE.
4. If activation does not restore Mullvad, check generic dispatch/log evidence and
   another installed tray application. Record application/Wayland behaviour; do
   not add VPN-specific control. The current API's activate returns no result, so
   absence of a local error alone is not proof the application restored a window.
5. Test one or two additional already-installed tray applications, including icon
   source updates, passive/attention, secondary action and scrolling where supported.
6. Remove an item/menu while its native menu is open; remove the originating output;
   change main output; restart the app; reload MAGI with apps alive. Check no crash,
   stale popup, spurious activation or state loss. Verify theme and pixmap providers.
7. Stop for architecture review if native layer-shell menu anchoring/destruction
   is unsafe. Do not substitute custom menu parsing or application hacks.

The operator decisions are the two recommended defaults (Available only,
main-output only) and authorization for a later native gate. **Do not integrate,
stage, commit or push this first-pass candidate.**

[Preview gallery](phase14a-previews/index.html). All images are synthetic; the
main-output gallery pair illustrates policy, while fleet assertions exercise
actual production selection and lifetime logic.

## Final Phase 14A inventory

42 paths: **27 A / 15 M / 0 D**, including 11 PNG captures and their HTML gallery.
The allowlist excludes operator Settings and unrelated local state. Final protected
checks permit only the approved source changes and deliberate Tray placement.
The initial isolated pass preserved its entire 974-path snapshot; native integration
and final pre-staging checks are recorded separately below.

```text
M linux/magi/.config/quickshell/magi/components/bar/Bar.qml
M linux/magi/.config/quickshell/magi/components/bar/BarFleet.qml
M linux/magi/.config/quickshell/magi/components/settings/BarCanvas.qml
M linux/magi/.config/quickshell/magi/components/settings/BarInspector.qml
M linux/magi/.config/quickshell/magi/components/settings/BarModulePreview.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/BarPage.qml
M linux/magi/.config/quickshell/magi/services/qmldir
M linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
M linux/magi/.config/quickshell/magi/shell.qml
M linux/magi/docs/README.md
M linux/magi/docs/architecture.md
M linux/magi/docs/decisions.md
M linux/magi/docs/quickshell-reference.md
M linux/magi/tests/phase10b/policy.cjs
M linux/magi/tests/phase12c/schema.cjs
A linux/magi/.config/quickshell/magi/components/tray/TrayActions.js
A linux/magi/.config/quickshell/magi/components/tray/TrayGroup.qml
A linux/magi/.config/quickshell/magi/components/tray/TrayItem.qml
A linux/magi/.config/quickshell/magi/components/tray/TrayOverflow.qml
A linux/magi/.config/quickshell/magi/components/tray/TrayPreviewModel.qml
A linux/magi/.config/quickshell/magi/services/TrayModel.qml
A linux/magi/.config/quickshell/magi/services/TrayService.qml
A linux/magi/docs/design/phase14a-previews/attention.png
A linux/magi/docs/design/phase14a-previews/bottom.png
A linux/magi/docs/design/phase14a-previews/compact.png
A linux/magi/docs/design/phase14a-previews/dawn.png
A linux/magi/docs/design/phase14a-previews/designer.png
A linux/magi/docs/design/phase14a-previews/empty.png
A linux/magi/docs/design/phase14a-previews/index.html
A linux/magi/docs/design/phase14a-previews/main-output.png
A linux/magi/docs/design/phase14a-previews/overflow.png
A linux/magi/docs/design/phase14a-previews/secondary-output.png
A linux/magi/docs/design/phase14a-previews/three-items.png
A linux/magi/docs/design/phase14a-previews/top.png
A linux/magi/docs/design/phase14a-system-tray.md
A linux/magi/tests/phase14a/designer.qml
A linux/magi/tests/phase14a/fleet.py
A linux/magi/tests/phase14a/fleet.qml
A linux/magi/tests/phase14a/model.cjs
A linux/magi/tests/phase14a/presentation.qml
A linux/magi/tests/phase14a/reload.qml
A linux/magi/tests/phase14a/run.py
```

## Native acceptance checkpoint — 2026-10-27 (in progress)

The operator approved the architecture and confirmed “All changes saved” before
integration. The supplied real-host audit reported no owner for either
`org.kde.StatusNotifierWatcher` or `org.freedesktop.StatusNotifierWatcher`, no
StatusNotifier-related bus names and no competing Waybar/Plasma/Xfce panel. The
relevant processes were MAGI Quickshell PID 1627 and mullvad-daemon PID 1146; no
Mullvad GUI process appeared in that audit. This clears the pre-integration watcher
gate at the time of observation, superseding the earlier sandbox-only unknown.

The exact reviewed 41 paths were copied into the live checkout, unstaged, with
new dependencies installed before consumers. The existing instance
`791r93jnt` recorded `Reloading configuration` at 10:56:39 and
`Configuration Loaded` at 10:56:40 with no new warnings/errors. Settings bytes
were unchanged, the index remained empty, and 960 unrelated checkout paths
matched their immediate pre-integration hashes/symlink targets. The broader
preflight snapshot contains 1,873 configuration/state/cache entries and is
private under `/tmp/magi-phase14a-native-20261027`. Runtime state may naturally
change while MAGI runs; no runtime files were part of the installation allowlist.

Native Designer placement, application registration/interaction, real menus,
keyboard focus and the app-running reload gate are still pending. Neither this
integration nor the architecture approval constitutes native acceptance. No
staging, commit or push is authorized until explicit operator native acceptance.

### First native results and QApplication correction

Operator reports one attached display, deliberate System Tray placement in the
right status region, correct empty-state hiding, automatic Mullvad registration,
tray persistence after Super+Q, and successful window restoration on primary
click. The operator also reported the prompted icon/tooltip/no-EPIPE checks passed.
Exact Settings comparison shows only `tray` prepended to the existing right-side
array; schema remains 21 and no application runtime items were saved. Physical
external-monitor presentation is deferred.

Despite the broad user report that tests passed, live log evidence at 11:00 and
11:02 shows native menu calls were rejected because Quickshell was not started in
QApplication mode. Native menu acceptance is therefore NOT recorded as passed.
The correction adds `//@ pragma UseQApplication` at the start of shell.qml, as
required by the runtime diagnostic and the official
[instance pragma reference](https://quickshell.org/docs/v0.3.0/guide/advanced/)
(inspected 2026-10-27). This requires a process restart, not just a QML reload.
The isolated regression reproduces the old mode rejection and proves the same
menu API reaches its missing-menu check under the production pragma. Existing
Phase14A presentation/Designer/reload tests also pass with that startup pragma.
This checks the application mode prerequisite; actual app menu rendering remains
pending after restart. Candidate inventory is now 42 paths (27 A / 15 M / 0 D).

The post-integration launcher lifecycle regression passed again, including the
old-path EPIPE negative control and healthy delayed output at 127.3 seconds after
Hub/content destruction, hard reload and shell exit. Existing launcher source is
unchanged. Live logs also show Mullvad's IconName Get calls briefly failing during
registration; the operator reports the resulting icon is correct. Observe whether
these remain transient rather than suppressing them or adding application hacks.

### Restart-helper interruption

The first operator-run restart helper stopped the old MAGI instance, then failed
while parsing `quickshell list --json`: with no running instance, this installed
version returns a human-readable “No running instances” message rather than JSON
(and an empty response must also be handled). The new shell was not started.
The operator was immediately given the normal guarded startup command
`quickshell -c magi --daemonize --no-duplicate`. The private helper now accepts both
no-instance representations and can recover from an already-stopped shell. Mocked
parser tests cover empty, human-readable, empty-array, populated-array and malformed
responses without executing host commands. Recovery and native menu retesting
remain pending operator confirmation; this is not a native acceptance pass.

### QApplication recovery and native menus confirmed

The new MAGI instance is `u0417bcknt`, PID 51870, started at 11:09:07 on
2026-10-27. It loaded cleanly. The operator explicitly confirmed that right-click
and left-click now work as intended, establishing native-menu functionality after
the QApplication correction and continued Mullvad restoration. There are no
QApplication menu-mode errors in the new instance log. Existing Wayland text-input
focus warnings are present; no tray QML error was observed.

The running-app reload and keyboard gate are being checked separately. A timestamp
touch alone did not trigger a recorded reload; the root startup explanation comment
was added to cause a content change. Physical multi-monitor testing remains
deferred (only one display attached). Steam is installed and has been offered as
a second native target without installing anything or altering VPN state.

### Native reload, keyboard and second application results

The operator confirmed Mullvad survived the normal config reload with no
unexpected behaviour. The same Quickshell PID 51870 logged a reload at 11:12:32.517
and Configuration Loaded at 11:12:32.736. The operator ran the tray IPC entry point
and checked the requested keyboard controls, reporting they work. The supplied
screenshot shows the IPC call returning true and both Mullvad and Steam tray
icons. Steam's tray was tested, including normal exit and restart, and the operator
reported the test passed. No new software was installed.

Native checks now reported passed: deliberate Bar placement, clean empty state,
Mullvad registration/icon/tooltip, close-window persistence, primary restoration,
application context menu after QApplication startup, reload preservation, keyboard
entry/actions/dismissal, and a second application's exit/restart lifecycle. Only
one display is attached, so physical multi-output testing remains deferred.
Overflow and uncommon status permutations retain synthetic coverage; VPN state was
not manipulated to manufacture icon changes. Legacy XEmbed remains unsupported.
The new shell log contains Wayland text-input focus warnings also seen before the
tray gate, but no new tray QML or QApplication menu-mode error.

Final explicit acceptance has been requested; staging/commit/push remain blocked
until that response. The candidate has 42 paths (27 added, 15 modified, no deleted),
including the necessary root shell.qml startup pragma. Settings remains schema 21,
protected and unstaged; an exact comparison still shows only deliberate Tray
placement. Both native apps' runtime identity/state are absent from Settings.

### Explicit final acceptance

The operator explicitly accepted and authorized finalization on 2026-10-27:
“Accept and finalize Phase 14A.” Physical multi-monitor tray acceptance is
explicitly deferred. Finalization is limited to this phase's exact allowlist;
Settings and all unrelated local/operator changes remain unstaged.

### Final post-acceptance regression results — 2026-10-27

All 23 final commands passed after explicit native acceptance: Phase14A component,
Designer, startup-mode, synthetic reload and fleet tests; Phase12C; Phase10B;
Settings store/schema and presentation; Phase12F; Phase12G backend, presentation,
lifecycle and global blur; Phase12H backend/presentation; Phase13A and Phase13B
backend/model and presentation; launcher lifecycle/backend/presentation/search/
schema; runtime visuals. The final full launcher lifecycle run again reproduced
EPIPE with the old mechanism and completed healthy delayed writes at 127.3 seconds
with the accepted implementation. No launcher production source changed.

`git diff --check` passed. The 42-path live source/fixture/documentation inventory
matched the isolated candidate before precise staging. Protected-file checks
passed, including the Yazi symlink; Settings remained schema 21 with only the
deliberate singleton Tray placement. No runtime application state is in the
allowlist. Native acceptance does not extend to physical multi-monitor hardware,
which the operator explicitly deferred.
