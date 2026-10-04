# Clipboard Manager — durable checkpoint

Baseline `1598e12`. Started 2026-10-03; final resume audit 2026-10-04.
Implementation and operator interaction/focus checks are complete. Ready for final
milestone review; nothing staged, committed or pushed.

## Bounded findings

- Quickshell0.3.1-1 installed metadata: `/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes`,
  clipboardText only. [Official docs](https://quickshell.org/docs/v0.3.0/types/Quickshell/Quickshell/)
  and [v0.3.1 header](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/core/qmlglobal.hpp)
  inspected2026-10-03: QString clipboard, focus caveat, no MIME/background manager.
  Relevance: native QML API insufficient. No upstream implementation copied.
- Installed wl-clipboard2.3.0, cliphist0.7.0. Local wl-clipboard(1) documents
  watch initial/current capture, single-format restore, sensitive KDE hint.
  [Upstream2.3 release](https://github.com/bugaevc/wl-clipboard/releases/tag/v2.3.0)
  inspected2026-10-03, commit67a7b93: ext-data-control and sensitive support.
- Installed `/usr/share/wayland-protocols/staging/ext-data-control/ext-data-control-v1.xml`
  inspected2026-10-03. [Official protocol](https://gitlab.freedesktop.org/wayland/wayland-protocols/-/blob/main/staging/ext-data-control/ext-data-control-v1.xml):
  data_offer MIME events precede selection; initial selection delivered on bind;
  receive targets exact offer, primary separate, no application identity. XML
  permissive license inspected; generated bindings retain its license locally.
  Registry-only live probe (no selection access) verified ext manager v1,
  wlroots manager v2 and wl_seat v9. Single seat/output validated so far.
- cc, wayland-scanner, wayland-client1.26 headers and Python gi/GdkPixbuf available.
- Initial Hyprland startup contained `wl-paste --watch cliphist store`.
  **Correction:** the initial sandboxed process inspection could not see the host
  watcher. The later host audit found PID1547 still running from login. It was
  identity-checked and sent SIGTERM before interruption; the 2026-10-04 resume
  verifies it is gone. SUPER+V floats; SHIFT+SUPER+V was free before this milestone.
- Existing dirty SwayNC config, untracked Hypridle/Hyprlock and stray file are out
  of scope. Current clipboard payload was not inspected or read.

## Ledger

| Phase | State | Tests / resume point |
| --- | --- | --- |
| Architecture | complete | Installed API/protocol checks above; design recorded |
| Service/model | complete | Native helper, Python model; ten synthetic tests pass |
| UI | complete | FloatingWindow; search/navigation/restore/pins/clear; isolated content/service/window tests pass |
| Settings | complete | Schema6, Clipboard page; migration/validation/atomic store tests pass |
| Runtime | complete | Prior harmless protocol checks; final host audit below |
| Operator interaction/focus | complete | Operator twice reported checks passed, including corrected nonmodal focus |
| Final milestone review | awaiting review | Documentation and exact path list reconciled; no further implementation scheduled |

Exact resume point: review this checkpoint and current diff. Do not repeat the
architecture/research or reimplement Clipboard. No commit/push is authorized.

## Final architecture and behavior

`ShellRoot` activates `Services.Clipboard` after Settings readiness. One long-lived
Python worker owns history independently of its window. One child C helper uses
the installed ext-data-control-v1 protocol and requests bytes from the exact offer.
No cliphist dependency/database import, QML command chains, or native Quickshell
MIME API is assumed. wl-copy is only the restore transport, using explicit MIME and
stdin bytes. A per-runtime lock prevents duplicate MAGI workers. The helper is
built with installed cc/wayland-scanner and cached by source/protocol hash.

- Content: UTF-8/plain text; HTML-only offers converted to plain text; PNG/JPEG;
  `text/uri-list`. One preferred representation per copy. Actual plain alternatives
  take precedence over HTML. wl-copy's HTML fixture also advertises plain aliases,
  so its markup is safely literal; HTML-only conversion is separately model-tested.
- Model: UUID, MIME/category, timestamp, preview, private payload, pin, SHA256
  deduplication, image dimensions/thumbnail reference. Recopy promotes the same ID;
  pins survive normal clear. Search covers full stored text, beyond the excerpt.
- Limits: default100 entries, configurable10–200; at most50 pins within the entry
  limit;8MiB payload/item;256KiB text;64MiB total;16MP image limit;1.5s transfer
  deadline. Oldest unpinned evicts first. Reducing limits may unpin excess entries.
- Privacy: initial offer skipped on connection/re-enable; KDE password-manager and
  conservative KeePassXC MIME hints rejected before requesting bytes. Primary
  selection is ignored. No sender/app identity is invented. Unmarked secrets
  cannot be detected reliably; pause collection before copying them.
- Persistence: OFF by default, including pins. Session payloads remain in memory;
  bounded thumbnails live in private `$XDG_RUNTIME_DIR/magi-clipboard` and are
  removed on normal worker exit/deletion/eviction and cleaned on the next locked
  startup after a crash. QML reload/process restart clears memory-only history.
  Opt-in SQLite format1 lives at `$XDG_DATA_HOME/magi/clipboard/history.sqlite3`
  (usual fallback `~/.local/share`), directory0700/file0600. Disabling persistence
  deletes MAGI's database; it does not erase backups/storage remnants.
- Clear unpinned preserves favourites. Confirmed erase-all also removes pins.
  Neither action clears the current system clipboard or another manager's database.
  No payload, URI, preview or hash is printed by diagnostic IPC or production logs.

## Accepted window, keyboard and Settings integration

The initial Exclusive-keyboard PanelWindow was rejected by the operator because
typing in other applications was blocked until Clipboard closed. The final
`ClipboardWindow.qml` is a normal **FloatingWindow**, title `MAGI Clipboard`, with
a narrowly matched class+title Hyprland float/centre/540×660 rule. This rule is part
of the accepted Clipboard integration, alongside the keybind/startup change.
Do not revert it to a modal layer. Clicking another app transfers keyboard focus
while Clipboard may remain visible. Reopening focuses search. The operator
explicitly passed that correction.

`SUPER+SHIFT+V` toggles; `SUPER+V` still toggles floating. Up/Down selects, Enter
restores/closes on success, Escape closes, Ctrl+P pins/unpins, Ctrl+Delete deletes,
Ctrl+L focuses search. Restore/pin/delete wait for the current search result set,
so a fast query change cannot operate on an older result. Native close reconciles
service state asynchronously to avoid a visibility/fullscreen binding loop.

The existing fullscreen monitor closes/suppresses Clipboard; no new output-sized
input catcher or layer exists. Opening shared menus, Centre or Settings closes it.
Theme, semantic icons/Legacy fallback and radius settings are reused. No fixed
Control Centre row/column assumptions were introduced.

Settings schema6 adds `clipboard.enabled`, `historyLimit`, `persistHistory`,
`includeImages`, `includeFiles`; the page includes pause, clear-unpinned, confirmed
erase-all and reset through the existing SettingsStore. Clear operations are not
stored preferences. No unrelated Settings/theming architecture changes.

## Legacy watcher and startup audit — 2026-10-04

- Prior final host inspection found **PID1547**, exact argv
  `wl-paste --watch cliphist store`. The previous turn checked `/proc/1547/cmdline`
  and sent SIGTERM. This resume confirms **no wl-paste or cliphist process** remains.
- The live `~/.config/hypr/hyprland.lua` resolves to the tracked t15g file. Its
  legacy watcher startup line is removed; MAGI activation is in ShellRoot.
- Installed `/usr/lib/systemd/user/cliphist.service` remains installed, **disabled
  and inactive**, with `WantedBy=`, `RequiredBy=`, `TriggeredBy=` empty in live state.
  No cliphist enablement symlinks exist under user/system user-unit configuration.
  The package's `[Install] WantedBy=graphical-session.target` is an enable-time
  instruction, not an active dependency; its PartOf/Requisite/After relationships
  do not start it. No additional service masking was needed or performed.
- Scoped searches of current Hyprland/MAGI, user systemd, desktop autostart and
  tracked t15g startup files found no remaining launch route. The packaged disabled
  unit is the only remaining command definition. An explicit future manual start
  or enable could still launch it; no claim is made to prohibit user actions.
- MAGI is the only intended active history monitor: Python PID166067, parent
  Quickshell PID143717; capture PID166080, parent166067 at audit time.
- **Existing cliphist history/database was not read, imported, deleted or modified
  by our tools.** The old watcher could itself record copies before it was stopped;
  MAGI's settings do not retroactively remove those records. Package retained.

## Validation evidence

Re-run successfully on 2026-10-04:

- `python3 tests/clipboard/model.py`: **10 PASS**, text/identity/search, bounds,
  pins/clear/delete, HTML/URI handling, invalid/disabled input, image cleanup,
  image eviction, opt-in persistence/reload/off cleanup, settings bounds and
  explicit-stdin restore boundary. GdkPixbuf needs host image-service access;
  one installed PyGI deprecation warning is unrelated to payloads/functionality.
- `python3 tests/clipboard/presentation.py`: **3 fixtures PASS**, actual content
  navigation/selection/empty state, singleton import isolation/search guard/
  fullscreen state, actual FloatingWindow visibility/fullscreen/native close.
- `node tests/clipboard/schema.cjs`: **PASS**, v5→v6, defaults, validation.
- `python3 tests/settings/run.py`: **PASS**, chained schema, atomic persistence,
  backups/conflicts/symlinks, missing/legacy/current/invalid/partial store fixtures.
- `node tests/notifications/policy.cjs`: **PASS**.
- `python3 tests/notifications/run.py`: **PASS on private D-Bus**, including
  replacement/actions/DND/history/fullscreen/close reasons and automatic ownership
  across reload. No desktop notifications sent by this run.
- Scoped `/usr/lib/qt6/bin/qmllint`: exit0; only the known `QProcess::ExitStatus`
  metadata warning at Clipboard's onExited. `luac -p`: PASS. `git diff --check`: PASS.

Offscreen fixtures filter only their known unsupported-window-mask warning and
sandbox IPC socket error. These are not production warnings; the final full
production log audit found **0 warning/error lines** across16 log lines.

Previously completed live protocol test (retained, not unnecessarily repeated):
`python3 tests/clipboard/live.py --replace-clipboard` passed initial selection skip,
text/promotion, sensitive-hint suppression, HTML/plain alternative, PNG, URI,
pin/clear, explicit restore, pause/re-enable, runtime thumbnail cleanup and absence
of a MAGI history database with persistence disabled. It used synthetic samples
and isolated storage. This resume did not replace/read the current clipboard or
erase current history to repeat those checks.

Final live audit (2026-10-04):

- Clipboard ready/monitoring, persistence false, error empty. Six entries present
  at resume; only counts/status read, no contents. Existing history preserved.
- Toggle opened `org.quickshell` / `MAGI Clipboard` as floating540×660 at(690,234).
  Toggle closed it; original closed state restored. Operator already passed focus
  switching and reopening; no new typing injected into other applications.
- While Clipboard was open: **one** main1920×1080 MAGI layer, **no Clipboard layer**.
  eDP-1 scale2 and reservation exactly `[0,48,0,0]`.
- SUPER+SHIFT+V modifier mask65 and preserved SUPER+V mask64 registered. Lua
  callbacks appear as `__lua` IDs in hyprctl, so command-string filtering is not
  a valid runtime test; commands verified in live/tracked configuration instead.
- Notification name still owned by Quickshell **PID143717**; SwayNC **masked/inactive**.
  Hyprland configuration errors empty; production logs clean. No shell restart or
  Hyprland reload was required during this resume.

## Known limitations / later composition pass

No reliable per-app exclusions or detection of unmarked secrets; no encryption or
secure-erasure guarantee. One preferred MIME per copy; HTML restored as text;
no primary selection, arbitrary MIME, file reading/copying or rich-format bundle
restoration. PNG was live-tested; JPEG follows the supported decoder path but has
no separate live sender acceptance. Build/runtime dependencies are listed in the
design. Backend failures surface a generic unavailable state; re-enable/reopen
retries where applicable. Memory-only history does not survive QML/process reload.

Multi-output, multi-seat, hotplug and fractional scale are not validated. Clipboard
fullscreen close/recovery is covered by service/window fixtures using the accepted
monitor integration; no new operator-driven true-fullscreen cycle was performed in
this resume. Broad whole-shell visual acceptance is not claimed. Spacing/density,
thumbnail composition, bespoke Clipboard SVG artwork (currently Legacy fallback)
and motion/cohesion are intentionally left to the later whole-shell visual pass.

## Exact intended Git paths

Final Git reconciliation passed on2026-10-04: exactly32 intended paths plus the four
excluded entries below; no extra or missing paths, index empty, HEAD still1598e12.
Tracked `git diff --check` and individual untracked-file whitespace checks pass.

32 paths, relative to repository root. Nothing is staged. This is the future
Clipboard milestone allowlist, not permission to stage or commit:

```text
linux/magi/.config/quickshell/magi/components/clipboard/ClipboardContent.qml
linux/magi/.config/quickshell/magi/components/clipboard/ClipboardIconButton.qml
linux/magi/.config/quickshell/magi/components/clipboard/ClipboardWindow.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsWindow.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ClipboardPage.qml
linux/magi/.config/quickshell/magi/icons/packs/registry.json
linux/magi/.config/quickshell/magi/services/Clipboard.qml
linux/magi/.config/quickshell/magi/services/clipboard_backend.py
linux/magi/.config/quickshell/magi/services/clipboard_capture.c
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/shell.qml
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/clipboard-manager.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/README.md
linux/magi/docs/research/clipboard-manager-checkpoint.md
linux/magi/tests/clipboard/content.qml
linux/magi/tests/clipboard/live.py
linux/magi/tests/clipboard/model.py
linux/magi/tests/clipboard/presentation.py
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/clipboard/service.qml
linux/magi/tests/clipboard/window.qml
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/t15g/hypr/.config/hypr/hyprland.lua
```

Explicitly excluded, untouched pre-existing entries:

```text
linux/t15g/swaync/.config/swaync/config.json
linux/t15g/hypr/.config/hypr/hypridle.conf
linux/t15g/hypr/.config/hypr/hyprlock.conf
urface architecture"
```

The last filename contains a literal trailing double quote (Git escapes it when
printing status). No cleanup, overwrite, staging or inclusion of these paths.
