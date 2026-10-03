# Notifications/toasts — durable checkpoint

Baseline `d539b9b`, 2026-10-03. No commit/push authorized. User requested GPT-6
Astra High; session model cannot be changed by the agent (client selection needed).

## State and exact resume point

Reconciled after interruption on 2026-10-03 against actual source/diff and the
preceding session's completed tool results. **Do not repeat research or implementation.**
The last `tests/notifications/run.py` exited0 after the timeout/action/replacement
edits, printed PRIVATE BUS PASS, and confirmed that a replaced action with the same
identifier retains its original label in installed Quickshell0.3.1. This result was
not recorded before interruption; it is now recorded from the actual tool output.

**Operator-accepted; stop here.** User reports "all checks passed" and supplied
Notification Centre/toast screenshots on2026-10-03. No further implementation,
test notifications, commit/push or permanent migration is authorized by acceptance.
The user explicitly approved temporary swaync.service stop and live MAGI activation,
with immediate rollback on failure; no permanent migration or startup changes.
MAGI PID1548 owns org.freedesktop.Notifications (:1.12), explicitly verified before
test sends and again after QML reload. SwayNC is not running (now failed/start-limit-hit
after an attempted competing start; unit enablement unchanged). See caveat below.
Live creation, three-toast stack state, expiration, replacement and safe action
delivery observed; operator pointer/motion/fullscreen and visual checks now accepted.

One healthy main1920×1080 layer at(0,0), eDP-1 scale2, reservation `[0,48,0,0]`.
Toast host measures `(1536,62,370,1004)` when mapped, not a new reservation.
Mocha remains selected. No shell process restart was needed for the handoff.
The fresh production log has Configuration Loaded and one Qt host-portal app-ID
registration warning; no QML load/runtime failure. Earlier transient reload errors
while adding the new QML types were resolved before interruption.

Preserve pre-existing and ongoing operator changes in settings.json and unrelated
sibling dotfiles. The live SettingsStore has saved schema5 and operator-selected
appearance values; no test writes to the live configuration were performed.

| Phase | Status | Files / tests / operator checks / unresolved |
| --- | --- | --- |
| Research/design | complete | Official0.3.1/spec checks; private-bus milliseconds confirmed; no broad survey |
| 0 foundations | complete | Bluetooth.qml, Bar.qml, Theme.qml, ActionButton.qml, schema/AppearancePage; connected-only/hidden detail and ten-palette/state resolver tests passed; operator reports all checks passed |
| 1 service/model | complete (isolated integration) | NotificationBackend/Model/Record/Policy/Notifications, qmldir; real private-bus creation/replacement/actions/closure/bounds passed; upstream label limitation below |
| 2 DND | complete (live integration) | QuickActions.qml shares Settings state; operator enabled DND; live ID10 retained in history/unread with no toast or native toast layer; read on opening Centre verified |
| 3 toast host | complete | ToastHost/NotificationCard; entry/exit/reflow and per-card Regions; focused geometry passes plus operator native pointer/motion acceptance and screenshot |
| 4 fullscreen | complete (single output) | live fullscreen2 accepted ID13 into history with no toast/Centre layer and main bar alpha0; exit/history/pointer recovery operator-confirmed; final main alpha1 |
| 5 Centre | complete | NotificationCentre/Indicator, Bar, Legacy bell; history/read/clear tests passed; individual removal/clear/empty and screenshot accepted |
| 6 Settings | complete | schema5/migrations/store, NotificationsPage/window/BarPage/AppearancePage; five real-store fixtures and Settings-window fixture passed; operator reports all checks passed |
| 7 migration | complete (temporary checkpoint only) | temporary stop approved/performed; MAGI PID1548 verified owner; session activation survives QML reload; permanent migration not started/not authorized; competing SwayNC start documented |
| 8 automated/runtime | complete (available environment) | private bus/reload/gate, policy, stacked UI, settings, appearance/modules and48-step lifecycle passed; scoped lint exits0, diff check passes; healthy final runtime; multi-output/fractional unverified |
| 9 operator | complete | all requested checks reported passed; Centre/toast screenshots supplied; current presentation accepted; separate default-body native click not specifically exercised |

## Bounded technical evidence (inspected 2026-10-03)

1. [NotificationServer 0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/),
   installed `/usr/lib/qt6/qml/Quickshell/Services/Notifications/*.qmltypes`:
   first-party tracking and explicit capability flags exist. MAGI must set tracked
   in onNotification. Compatibility pinned to installed0.3.1; private-bus runtime passed.
2. [server.cpp v0.3.1](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/services/notifications/server.cpp),
   `Notify`, `tryRegister`, `deleteNotification`: replacement mutates same object,
   emits notification only for new IDs; registerService attempts ownership and
   retries on service exit. MAGI needs a construction gate during migration and
   changed-property observers. No raw replaces_id or ownership property in QML.
3. [notification.cpp v0.3.1](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/services/notifications/notification.cpp),
   `updateProperties`, `NotificationAction::invoke`, `expire`, `dismiss`:
   timeout assigned directly from wire milliseconds despite header saying seconds;
   actions invoke and auto-dismiss unless resident. Images get provider URLs;
   binary hints removed. Close destroys object after callbacks. Same-identifier
   action text setter has an inverted equality guard; the installed-binary test
   confirmed `Original label` after replacement with `New label` using the same
   identifier. Identical updates can emit no property-change signals, so their
   receipt/timer restart cannot be detected through this API. Do not invent a
   second D-Bus receiver to work around these upstream limitations.
4. [Desktop Notifications1.3 protocol](https://specifications.freedesktop.org/notification/latest/protocol.html)
   and [hints](https://specifications.freedesktop.org/notification/latest/hints.html):
   IDs/actions/close reasons1–3, timeout -1/default and0/no-expiry, resident and
   transient semantics. Quickshell reports spec1.2; no1.3 activation-token support
   claimed. Capability checks passed for body/actions/icon-static, excluding
   persistence/markup. Actual ActionInvoked/default-action and close signals were
   observed on the private bus; live desktop integration still pending.
5. Local baseline source inspected: Settings schema/store/migrations, Theme and
   registry, IconState/VisualState, Bluetooth service/module, QuickActions/Caffeine,
   Bar/ModuleRegistry, compositor-owned top-layer fullscreen behavior. Render exists
   at supplied Downloads path and was visually inspected as composition reference;
   no sampled colors will enter production.
6. Targeted reflow verification after resume (same inspection date/version):
   [region.cpp](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/core/region.cpp)
   `setItem/build` maps Item geometry to scene coordinates but subscribes only to
   the immediate Item's geometry. Ancestor reflow therefore needs its own dependency.
   ToastHost now uses explicit wrapper/card coordinates, rounded card bounds and
   zero-sized suppressed/exiting Regions. Three-card removal/update test passes;
   native pointer validation pending.
7. [qml.cpp](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/services/notifications/qml.cpp)
   `NotificationServerQml::onPostReload` applies capabilities, connects reception and
   switches native generations. A private-bus production-singleton test confirms
   late activation works and no name is owned before activation. Reload restoration
   keeps returned IDs, suppresses initial restored toasts, and permits later updates.

No external project survey or copied source/assets. Official APIs used as dependency;
new implementation is MAGI-owned. Multi-output and fractional-scale remain untested.

## Completed test evidence (before interruption)

- `python3 tests/notifications/run.py`: final exit0,8.47s. Private dbus-run-session,
  copied config and offscreen shell only. Creation,1234ms sender timeout, replacement
  identity/no duplicates, stable stack cap/order, individual dismiss, DND retaining
  history, critical bypass, fullscreen suppression/no replay, centre read/clear,
  hover pause, nonresident/default/resident actions, client CloseNotification,
  transient no-history,20-message bounded burst, disabled acceptance, advertised
  capabilities, and real QuickActions/Settings DND source all passed. Shell log
  contained Configuration Loaded only. Signal monitor observed actions and closure;
  model asserted Expired=1. Native real-card click routing is not proved by this test.
- `python3 tests/settings/run.py`: five copied real-store fixtures passed, including
  notification setting edits/save/reload/reset, migration and atomic I/O.
- `python3 tests/settings/appearance.py`: ten palettes plus primary/secondary
  shade endpoints/strength and unchanged primary accent pipeline passed.
- `python3 tests/settings/modules.py`: Bluetooth off/on-disconnected/connected/
  last-disconnect and retained hidden detail/navigation/inline-auth ownership passed.
- `python3 tests/settings/modules.py window.qml`: existing Settings integration passed.
- `python3 tests/shared-status-surface/run.py`:48 steps passed.
- `python3 tests/notifications/presentation.py`: real toast/centre content and
  Region bindings passed; only PanelWindow wrapper replaced by FloatingWindow
  because Qt offscreen has no layer-shell backend. Expected offscreen mask warnings
  and sandbox IPC-socket warnings were filtered explicitly; no native input claim.

## Files in scope

Production paths below are relative to `.config/quickshell/magi/`:

- New `services/Notification{Backend,Model,Record}.qml`, `NotificationPolicy.js`,
  `Notifications.qml`; changed `QuickActions.qml`, `qmldir`.
- New `components/notifications/{FullscreenMonitor,ToastHost,NotificationCard,
  NotificationCentre,NotificationIndicator}.qml`; changed `shell.qml`, `components/bar/Bar.qml`.
- Changed Bluetooth plugin, Control Centre ActionButton, Theme, Legacy icon registry.
- Changed SettingsSchema/Migrations/Store, SettingsWindow, AppearancePage, BarPage;
  new NotificationsPage. Live `settings.json` includes operator edits and migration.
- New `tests/notifications/{policy.cjs,integration.qml,activation.qml,run.py,presentation.qml,presentation.py}`;
  changed existing settings schema/store/run/appearance/modules fixtures.
- Design/checkpoint plus status/architecture/API/decision documentation.

## Handoff and rollback procedure — temporary approval granted

1. Approval received and executed: prior owner SwayNC PID1651, unit swaync.service.
   Do not repeat the handoff. Current owner MAGI PID1548 (:1.12).
2. `quickshell ipc -c magi call notifications activate` constructs the server;
   ShellRoot PersistentProperties preserves approval across QML reload only.
   `systemctl --user stop swaync.service` released the name; verified MAGI owner.
   GetServerInformation reports quickshell/quickshell/spec1.2; capabilities are
   body/actions/icon-static. No source flag or saved activation preference remains.
3. Send only a handful of safe local tests, not the private-bus burst suite.
   Recheck logs, layer count/names and exact48px reservation while toasts/centre
   are visible, then after they close. Get screenshots/motion/pointer feedback.
4. Quickshell's backend server is process-global: changing an activation flag back to false
   does **not** release an already-owned name. A rollback therefore requires an
   MAGI restart (session approval resets), then `systemctl --user start swaync.service`
   and verification of ownership. User explicitly requires immediate rollback if
   MAGI acquisition fails, errors or becomes unusable. Kill only the verified MAGI
   instance, start SwayNC, relaunch MAGI and verify both shell and SwayNC ownership.
   If its unit still has start-limit-hit, `systemctl --user reset-failed swaync.service`
   may be required before starting it; this resets failure state, not enablement.
5. No service disable/uninstall/config deletion or startup edits in this sprint.
   After acceptance, separately review SwayNC user-unit enablement and any Hyprland
   startup command/DBus activation to prevent competing owners on later logins.

Remaining operator checks: normal toast;2nd/3rd stack/reflow; timeout/dismiss;
replacement; safe action click; DND/history; Centre history; individual dismiss;
clear all; fullscreen hidden/pass-through; exit/history; connected-only Bluetooth;
secondary ON/OFF palette styling. Screenshots and motion feedback required before
declaring presentation accepted. Clipboard remains out of scope.

## Resume follow-up — completed before requesting handoff

Preserved completed work and used focused tests only. No repeated broad research
or full-suite run. Two implementation corrections arose from unfinished lifecycle
review: explicit toast mask geometry follows ancestor reflow; restored native
notifications suppress only their initial re-emission, not subsequent replacements.
Centre header buttons now explicitly inherit palette text; its DND button cannot
control SwayNC before activation. Collapsed Bluetooth row movement does not apply
another move animation during the accepted shared-surface morph.

Final `tests/notifications/run.py` **exit0**, including the production-singleton
activation fixture, exact `(notificationID, closeReason)` wire pairs for expiry,
user dismiss and client close, actual QML hot reload, stable ID restoration and
later replacement toast. Offscreen reload uses `QS_NO_RELOAD_POPUP=1`; the initial
reload-test failure was an unsupported offscreen native reload popup and a transient
missing IPC target, corrected in the harness. A too-tight300ms hover deadline also
caused a test race;800ms test deadline now allows bounded IPC latency. No product
timeout was lengthened to satisfy tests. Final private-shell logs contain only
Configuration Loaded/Reloading INFO, no WARN/ERROR. The upstream stale action-label
result remains explicitly reported, not disguised as a fixed MAGI behavior.

Expanded `presentation.py` **passes**: three-card input union; immediate loss of
input on exit; surviving delegate identity; mask tracking after removal and body
growth; excluded stack gaps; bounded long body; fullscreen zero input; Centre read
behavior. Native compositor mask acceptance remains pending. `policy.cjs` passes
with positive critical sender timeouts honored and negative critical fallback
remaining non-expiring.

Scoped qmllint exits0. Documented tooling warnings: dynamic created record inferred
as QObject, PanelWindow backend/margins metadata (also present for existing Bar),
unused import. Real production configuration loads; native mapping tests follow
handoff. `git diff --check` passes. Main docs/index/design now match implementation.

The above pre-handoff follow-up is complete. See the current live section below;
do not repeat daemon handoff or run the20-message private-bus suite on the desktop.

## Approved temporary live checkpoint — 2026-10-03

Before stopping SwayNC, changed activation to process-session approval rather than
a permanent `ownershipApproved:true` source switch. Initial private tests exposed
that PersistentProperties inside a singleton did not restore approval; moved it to
ShellRoot. Final `python3 tests/notifications/run.py` exited0, including activation,
QML reload preserving approval and successful reception after reload. These failed
intermediate fixtures were isolated; they did not stop the production daemon.

Live handoff succeeded. Initial pre-release registration warnings are expected;
after release, no notification/QML runtime errors. Existing Qt portal app-ID warning
is unrelated. Activation has since survived a real production QML reload without a
process restart or ownership loss. Reload cleared expired in-memory history as
documented; this is not disk-persistent history.

Small deliberate live tests, not a spam suite:

- IDs1/2/3: three normal toasts, status confirmed3 entries/3 toast delegates.
  Sender timeouts expired with reason1 and retained history. Screenshot captured
  entry in progress, not proof of settled opacity or motion acceptance.
- An attempted late replacement of ID1 returned5 because1 had already expired.
  This is NOT a replacement pass. Subsequent persistent test ID8 returned8 on
  update, with count1/toasts1 and visibly updated title/body: live replacement pass.
- ID9 safe action: notify-send with default and ack descriptors; clicking the
  action produced stdout `ack`, exit0, and removed9. No external action executed.
  Body/default click is independently covered on private bus, not yet native.
- Native host initially measured y110: both exclusiveZone:0 and exclusionMode:Ignore
  were set. Official0.3.1 PanelWindow docs state the former resets mode to Normal.
  Removed exclusiveZone from ToastHost and NotificationCentre. Settled host now
  measures y62 with14px right/bottom clearance and no added reservation.
  Focused presentation.py/policy.cjs pass; scoped qmllint exits0 with documented
  PanelWindow/margins metadata warnings. No native pointer pass inferred from this.
- Local cropped captures: `/tmp/magi-notifications-stack.png`,
  `/tmp/magi-notifications-updated.png`, `/tmp/magi-notifications-settled.png`.
  Settled replacement card inspected; operator aesthetic acceptance still required.
- Live Settings schema5 reports saved/no errors/no diagnostics, Mocha selected.
  Operator preferences preserved. Not a substitute for Settings interaction review.
- Operator reported toast ×, ack action and outside-card desktop interaction worked.
  ID8 nevertheless remained live in history at the next read, so asked for a direct
  Centre dismiss/Clear all check rather than treating that discrepancy as resolved.
  After the operator's Centre interaction, status confirmed count0/unread0/toasts0.
  Operator subsequently explicitly confirmed each Centre removal, Clear all and
  empty state worked, then turned DND off and closed the Centre for fullscreen.
- DND enabled via live UI: ID10 accepted, history2/unread1/toasts0; no toast layer.
  Opening Centre changed unread to0; its native geometry `(1496,62,410,640)` was
  correct. Subsequent clear left empty history. Captured Centre region only after
  it had already been closed for fullscreen, so no aesthetic acceptance from it.
- Fullscreen test ID13: before send, DNDfalse/fullscreentrue/centreclosed. After
  send, count1/unread1/toasts0. Hyprland active client fullscreen2; no toast/Centre
  native layers, main1920×1080 layer alpha0, matching accepted shell behavior.
  Operator was asked to exit and verify bar/history/pointer recovery.
- Final daemon audit found SwayNC no longer merely inactive: an attempted start at
  13:09BST failed to acquire the notification name, retried and hit start-limit-hit.
  Source of that start is not established. No SwayNC config/startup changes were
  made here. `busctl --user status org.freedesktop.Notifications` again proves
  MAGI PID1548/:1.12 remains owner and healthy; this is not a MAGI acquisition failure.
  UnitFileState remains disabled as before the handoff. Do not reset/enable/mask it
  just to hide this evidence; investigate competing activation during a separately
  reviewed permanent migration. Rollback needs failure-reset if rate limit persists.

Extra bounded API evidence: inspected2026-10-03, Quickshell0.3.1
[PanelWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/) and
[ExclusionMode](https://quickshell.org/docs/v0.3.1/types/Quickshell/ExclusionMode/).
Setter coupling explains native offset; Ignore alone cannot reserve space. Relevant
components ToastHost/NotificationCentre; fixed position verified on installed
single-output scale2 environment. Multi-output/fractional-scale unverified.

## Final operator acceptance and exact stop point

User reports **all checks passed**, supplying Centre and toast screenshots:
`/tmp/codex-clipboard-Gq7Z6L.png` and `/tmp/codex-clipboard-aECfiM.png` (temporary
attachments, not durable repo assets). First screenshot visibly shows the restored
bar and the fullscreen test in history; second shows a normal Hyprshot toast below
the bar. Record native motion/input/Settings/Bluetooth/state-style passes as operator
reports, not measurements inferred from static images. All13 required operator
checkpoint items are accepted. No further visual redesign is requested.

Final read-only snapshot: MAGI1548 owns :1.12; fullscreenfalse, DNDfalse, Centreclosed,
toasts0, history5/unread2; ID13 read/live and four expired snapshots. One main
1920×1080 layer at(0,0), alpha1, no toast/Centre idle layer, exact `[0,48,0,0]`
reservation, eDP-1 scale2. Logs end in successful reload; historical ownership-retry
and portal warnings documented above, no new QML runtime failure. SwayNC remains
failed/start-limit-hit, not running, UnitFileState disabled unchanged.

Known limits/follow-ups: memory-only history; identical updates and changed action
labels limited by Quickshell0.3.1; native default-body click not separately tested
(private-bus semantics pass); literal sender markup visible under PlainText; Legacy
bell fallback; multi-output/fractional-scale unverified. No remaining requested
aesthetic blocker. Safe markup normalization and custom bell are optional polish.

**Stop after this accepted checkpoint.** No additional notifications or full-suite
rerun is needed for documentation-only close-out. No commit/push. No Clipboard.
Recommended next milestone is separately reviewed production activation/startup
migration, investigating the competing SwayNC activation and providing rollback.
Session activation currently survives QML reload only, not MAGI process restart;
acceptance does not silently authorize permanent activation. The model/history
design and full changed-file index remain above. Preserve unrelated dirty files.
