# Control Centre action catalogue — 2026-10-10

Baseline: `b32b88a4cfb68755f00eb1a25148892cc4319cea`, `main`, upstream
`origin/main`, zero divergence. Existing operator settings and untracked local
Hypridle/Hyprlock configurations are excluded from this milestone. No commit,
push, compositor configuration change or shell restart is authorized here.

## Pre-edit audit

Inspected local source at the baseline above on 2026-10-10. Source references
below are repository-relative links; no external implementation is copied.

- [ControlCatalog](../../.config/quickshell/magi/modules/ControlCatalog.qml)
  already owns definitions, presentation eligibility, state and dispatch.
  Primary: Wi-Fi, Bluetooth, Low Power, Airplane, Battery, Settings, VPN, DND,
  Caffeine. Sliders: Volume, Brightness. Secondary: Settings, VPN, DND,
  Caffeine, Lock, Hibernate, Shutdown. There are 14 distinct stable IDs.
- [Settings schema](../../.config/quickshell/magi/settings/SettingsSchema.js)
  separately lists valid presentations; **Settings is missing from its secondary
  allowlist**, despite being offered by the catalogue. This is a verified bug.
  Schema 9 defaults: primary Wi-Fi/Bluetooth/Low Power/Airplane, two sliders,
  secondary VPN/DND/Caffeine/Lock/Hibernate/Shutdown. Columns default to 4 and 6
  independently; these are preferences, not fixed slots.
- [Settings page](../../.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml)
  enumerates the catalogue and supports add, enable, replace, reorder, remove,
  reset and independent columns. Slider order is persisted; its current page
  offers enable/disable only. No Settings redesign is needed.
- [ControlCentre](../../.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml)
  renders ordered entries through ControlTile, ActionButton and IconSlider.
  Separate toggle state, momentary actions and sliders already exist.
- [QuickActions](../../.config/quickshell/magi/services/QuickActions.qml) and
  [system adapter](../../.config/quickshell/magi/services/system_actions.py)
  provide power profiles, VPN, DND and session commands. Lock uses the accepted
  `loginctl lock-session` path; local Hypridle invokes Hyprlock. Hibernate and
  Shutdown use logind capability checks and systemctl, guarded by
  ActionConfirmation's second activation within five seconds. Leaving CC cancels.
- [Hub](../../.config/quickshell/magi/services/Hub.qml) `open(mode)` closes the
  MenuController; ShellRoot's HubWindow waits for `Bar.settingsReady` (both
  anchored surfaces collapsed, no busy interaction). HubWindow/HubContent handle
  destination focus; layer dismissal restores compositor-managed app focus.
  There is no need for new windows or duplicate mode logic.
- IconRegistry already supplies semantic roles for all four Hub modes; Apps and
  Emoji use custom SVGs while Notifications/Clipboard inherit registered legacy
  icons. New assets will use the existing semantic SVG mechanism.
- Local Hyprland configuration has Hyprshot region/output/window shortcuts and
  Lua session exit. Screenshot needs collapse/capture coordination; Logout needs
  a deliberate session-exit adapter. Both are deferred; existing shortcuts remain.

## Implementation scope

Extend existing architecture with optional Apps, Notifications, Emoji, Clipboard
and confirmed Reboot. Share definition data with schema validation. Preserve all
current defaults, layout/order keys and schema version. No migration is needed;
new entries must not be inserted into operator layouts. Calendar stays separate.
Settings drag/drop, visual redesign and all other named non-goals remain deferred.

## Final catalogue and behaviour

`SettingsSchema.controlDefinitions()` supplies one pure definition list to schema
validation and ControlCatalog. The latter still owns reactive state and existing
toggle adapters; `route: hub/settings/system` handles momentary actions centrally.
New Hub routes need one definition, not new Control Centre delegate conditionals.
Unknown or unavailable IDs are rejected at invocation as well as disabled in UI.
Availability never removes a saved entry. Hub availability follows its controller;
power availability follows logind and installed executables. No packages installed.

| Stable ID | Presentations | Default selection |
| --- | --- | --- |
| `wifi` | Primary toggle, detail | Primary |
| `bluetooth` | Primary toggle, detail | Primary |
| `power-saver` | Primary toggle | Primary |
| `airplane-mode` | Primary toggle | Primary |
| `battery` | Primary readout | Optional |
| `settings` | Primary or secondary action | Optional; secondary validation fixed |
| `volume` | Slider | Slider |
| `brightness` | Slider | Slider |
| `vpn` | Primary or secondary toggle | Secondary |
| `dnd` | Primary or secondary toggle | Secondary |
| `caffeine` | Primary or secondary toggle | Secondary |
| `lock` | Secondary action | Secondary |
| `hibernate` | Confirmed secondary action | Secondary |
| `shutdown` | Confirmed secondary action | Secondary |
| `reboot` | Confirmed secondary action | **New, optional** |
| `apps` | Secondary navigation → Hub Apps | **New, optional** |
| `notifications` | Secondary navigation → Hub Notifications | **New, optional** |
| `emoji` | Secondary navigation → Hub Emoji | **New, optional** |
| `clipboard` | Secondary navigation → Hub Clipboard | **New, optional** |

Settings → Control Centre → Secondary actions → Add action exposes all options.
Existing checkboxes, replacement selection, earlier/later arrows and Remove remain
the editor. Reset restores exactly the prior defaults, including independent
primary4 / secondary6 column preferences. No schema bump, migration or runtime
settings write; current custom orders, disabled entries and slider order survive.
The operator's actual secondary lineup omits VPN; that customization is preserved.
No new permanent bar icon, native host or Calendar mode is introduced.

Hub mode entries call only `Hub.open(mode)`. The host waits for the existing
collapse gate; Apps/Emoji/Clipboard focus search and Notifications focuses its
content. No new focus cache replaces the compositor's previous-app target.
Notification ownership and clipboard capture remain independent of navigation.

Reboot adds `CanReboot` capability probing and `systemctl reboot` to the existing
adapter. Reboot/Hibernate/Shutdown require two activations of the same action
within five seconds; leaving CC cancels. A tooltip exposes the action name and
“Click again to confirm” while armed. No power operation was executed in tests.
Lock keeps `loginctl lock-session`; local Hypridle/Hyprlock files are untouched.
Power actions start unavailable until the first capability result arrives.

One original24×24 semantic `reboot.svg` is registered in the fallback pack and
inherited by magi-default. Existing Apps/Emoji SVGs and registered Notifications/
Clipboard roles are reused. No third-party asset or code was copied; no new
license dependency. Semantic tint and existing icon size remain intact.

## API evidence and compatibility

Inspected2026-10-10: Quickshell0.3.1, Hyprland0.56.2 at
`efb50993780079460b0cbed1363e2166a2de1d9f`, systemd262-1.

- [Quickshell0.3.1 WlrKeyboardFocus](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlrKeyboardFocus/)
  documents Exclusive keyboard ownership and None. HubWindow already uses these;
  this milestone does not alter them. Native previous-app restoration still
  depends on the compositor, tested below rather than inferred from this API.
- [Quickshell0.3.1 ExclusionMode](https://quickshell.org/docs/v0.3.1/types/Quickshell/ExclusionMode/)
  documents Ignore as incapable of setting an exclusion zone. HubWindow reuses
  that mode; the main Bar owns the48px reservation.
- [logind interface documentation](https://www.freedesktop.org/software/systemd/man/latest/org.freedesktop.login1.html)
  could not be fetched (403); verified instead against installed version262
  `/usr/share/man/man5/org.freedesktop.login1.5.gz`, `CanReboot` and capability
  response documentation. `system_actions.action_status()` accepts yes/challenge
  through the existing helper. A challenge may still need authorization and a
  subsequent execution may fail; capability detection is not an execution promise.
  Native power/authentication execution deliberately remains untested.

## Validation performed

All final commands below passed; fixtures stage disposable copies, never write
operator settings. Offscreen runners permit only their documented native-mask
and sandbox IPC-socket messages. No other warning/error was accepted.

```sh
node tests/settings/catalogue.cjs
python3 tests/settings/actions.py
python3 tests/settings/modules.py actions.qml
python3 tests/settings/modules.py catalogue-layout.qml
python3 tests/settings/modules.py catalogue
python3 tests/settings/modules.py action-layout.qml
python3 tests/settings/modules.py control-layout.qml
python3 tests/settings/modules.py window.qml
python3 tests/settings/modules.py modules.qml
node tests/settings/icons.cjs .config/quickshell/magi/icons
python3 tests/settings/run.py
python3 tests/shared-status-surface/run.py
python3 tests/hub/run.py
python3 tests/calendar/presentation.py
python3 tests/calendar/bar.py
python3 tests/notifications/presentation.py
python3 tests/clipboard/presentation.py
python3 tests/hub/live.py
git diff --check
hyprctl configerrors
```

Coverage:19 unique/stable IDs and all baseline entries; new routes; every
presentation accepted by schema; duplicate rejection; unchanged defaults and
migrations; optional add/disable/reorder/remove/save/reload/reset; independent
columns; real CC reflow and48-step shared lifecycle; existing module ownership
and inline authentication; icon resolution; unknown/unavailable invocation;
Reboot first-click arm and confirmed mocked dispatch; missing executable and
capability rejection; dry-run system argv. The catalogue fixture loads real CC,
SharedStatusSurface and Hub content with isolated device adapters, invokes all
four optional routes, waits for real collapse, checks focus and reopens CC.

The first catalogue fixture attempt passed its assertions but failed its strict
log check because it loaded device backends without a session bus. It now uses
the existing module runner's device stubs; an end-of-loop undefined label was
also corrected. Final runs pass without masking those device warnings.

Live Hub regression: one stable native utility host, four modes, focused search,
keyboard selector, Escape/toggle dismissal, restored original app focus,
CC/Calendar handoffs, unchanged notification/capture state and no duplicate hosts.
This tests the existing live controller path; physical clicks on the newly
configured optional buttons remain operator acceptance. No temporary actions
were inserted in the operator's configuration to perform that test.

Final live Settings state: saved, empty error, no diagnostics. `hyprctl
configerrors` is empty; eDP-1 scale2 reserves `[0,48,0,0]`, and the main shell
layer remains1920×1080. No shell restart or compositor configuration edit.
The settings and local Hypridle/Hyprlock SHA256 hashes match the initial audit.
One generated Python bytecode directory was moved to
`/tmp/magi-catalogue-test-artifacts-y2MX26/`; the adapter test now suppresses it.

## Limitations / review

- Operator visual/pointer acceptance of optional actions and hover prompts remains.
- No destructive live operation, radio disruption or lock was performed.
- Screenshot and Logout remain deferred; Calendar remains a separate surface.
- No drag/drop editor, new slider-order UI, redesign or broader backend testing.
- Multi-output and fractional-scale acceptance remains outside this checkpoint.
- Existing system-command errors remain exposed by QuickActions.error; this
  milestone does not introduce a new error-dialog subsystem.

## Exact intended Git allowlist

Paths relative to the MAGI project root. Leave all changes uncommitted.

```text
.config/quickshell/magi/settings/SettingsSchema.js
.config/quickshell/magi/modules/ControlCatalog.qml
.config/quickshell/magi/services/QuickActions.qml
.config/quickshell/magi/services/system_actions.py
.config/quickshell/magi/plugins/bar/controlcentre/ActionButton.qml
.config/quickshell/magi/icons/packs/registry.json
.config/quickshell/magi/icons/packs/magi-default/reboot.svg
tests/settings/actions.py
tests/settings/actions.qml
tests/settings/modules.py
tests/settings/catalogue.cjs
tests/settings/catalogue-layout.qml
tests/hub/catalogue.qml
docs/design/control-centre-action-catalogue.md
docs/README.md
docs/architecture.md
docs/quickshell-reference.md
docs/decisions.md
```

Exclude `.config/quickshell/magi/settings.json`, all runtime files and the
operator-local `../t15g/hypr/.config/hypr/{hypridle,hyprlock}.conf`. No staging,
commit, push, cleanup of user files or package operation was performed.
