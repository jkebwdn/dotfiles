# Calendar / Date surface — operator review checkpoint

2026-10-04. Baseline: `b8954987f785c0f9e9cf35f69c980a3980f6a389`
(`magi: add first-party application launcher`). Implementation is uncommitted;
no commit or push is authorized for this milestone. Operator live interaction
checks passed; this document records the final review scope.

## Interaction and shared object

Click either bar time or date to expand a compact Calendar from that area.
The original pills become transparent for the entire expansion/closing lifecycle,
retaining their slots and toggle targets. The expanded header uses the same pill
component and the same clock data; there is no second timer or visible duplicate.
The originals return only when the surface has finished closing. Other bar items
keep their layout positions. Header click, original time/date click, Escape or an
outside click closes it. Outside dismissal consumes that click, like the existing
shared status surface. Reopening resets selection and displayed month to today.

Adjacent time/date pills share the leftmost origin; when separated, the clicked
pill is the origin and both originals are suppressed. Horizontal bounds constrain
the expanded surface near the right edge. Bar placements left/centre/right are
supported. MAGI currently has a top bar only: no bottom-bar setting exists, so no
new bottom placement or speculative expansion-direction setting is introduced.

The 344px-wide surface contains time/date, selected weekday and date, month/year,
previous/next month buttons, Today, localized weekday labels and a stable six-row
grid. Today has an accent outline; selection uses an elevated fill. Adjacent-month
days are subdued and selectable, or hidden while preserving their grid slots.
Arrows move one day/week, PageUp/PageDown move a month (clamping the selected day),
and Home selects today. Selecting a day has no event-creation side effect; Enter
has no extra action. No redundant Calendar title or application window chrome.

## Architecture and window behaviour

- `ClockState.qml`: one minute-precision SystemClock and shared bar/header formats.
- `CalendarMath.js`: pure local civil dates, grid generation, clamped navigation and ISO weeks.
- `CalendarModel.qml`: today/selection, derived grid, locale labels and navigation.
- `Calendar.qml`: MenuController-backed open/close/toggle, reset-on-open and fullscreen suppression.
- `TimeDatePill.qml`: common compact and expanded time/date presentation.
- `CalendarSurface.qml`: anchoring plus reuse of SharedStatusSurface's existing lifecycle.
- `CalendarContent.qml`: small grid/navigation view consuming the model.

Bar owns the only native surface: the existing top-layer PanelWindow. Calendar
adds its geometry to the existing input mask and enables the existing outside
catcher and OnDemand keyboard focus while open. Reservation remains exactly48px.
The legacy anchored host temporarily expands the same bar window for Calendar,
then returns to48px height; this path has an isolated lifecycle test, not a new
live deployment. No Calendar PopupWindow or FloatingWindow is added to production.

Calendar participates in MenuController exclusivity, including Control Centre;
existing shell coordination dismisses it for Launcher, Clipboard, Notifications
and Settings. FullscreenMonitor closes/suppresses Calendar and never reopens it
on fullscreen exit. Bar rearrangement waits for the closing lifecycle to finish.
The only shared-status primitive change is optional left header alignment, with
right alignment retained as the existing default. Status model/lifecycle and
Wi-Fi backend are unchanged. IPC diagnostics: `magi open calendar`, `magi close`
and the `calendar` object within `magi status`.

## Settings and local dates

Schema8 adds Settings → **Date & time**, through the existing atomic writer:

| Preference | Choices / default |
| --- | --- |
| First day | System locale (default), Monday, Sunday |
| ISO week numbers | Off by default |
| Adjacent-month days | On by default |
| Calendar spacing | Comfortable (default), compact |
| Time format | 24-hour (default), 12-hour, system locale |
| Bar date format | Day/month/year (default), ISO year-month-day, system locale |

Time/date formatting is shared by the bar and expanded header. Default HH:mm and
dd/MM/yy preserve the previous appearance. Reset restores these six preferences
only; launcher hidden IDs and other sections are preserved. Version7 migrates
additively to8 without changing existing saved preferences or unknown fields.
No browsing/selection state is persisted. All settings tests use temporary files.
Operator-local `settings.json` remains outside the intended Git allowlist.

Date arithmetic uses local civil fields at noon, avoiding UTC-string and fixed
24-hour-day mistakes around DST. Leap/century rules and year boundaries are
covered. Selection is bounded to years1–9999. Week numbers are ISO week/year for
the Thursday in each displayed row, including Sunday-first layouts; this policy
is stated in Settings. Qt supplies localized month/day names and locale week
start. The grid remains Gregorian. Midnight updates today's highlight; an active
browsing selection remains until Today/Home/reopen. System timezone/locale changes
outside MAGI may require a shell reload; no timezone-management feature is added.

## Validation

Automated passing checks:

- `node tests/calendar/math.cjs`:28/29/30/31-day months, offsets, leap/century years,
  December/January both directions, day clamps, DST civil navigation, adjacent
  visibility, today/selection and ISO week-year boundaries. Also run in Europe/London.
- `node tests/calendar/schema.cjs`:v7→v8, preserved Launcher preferences, defaults,
  enums and booleans.
- `python tests/calendar/presentation.py`: real content, focus/navigation, locale
  en_GB/en_US/de_DE, today rollover, density/week geometry; actual Settings window,
  all preferences, shared formatting, persistence/reload, invalid input and reset isolation.
- `python tests/calendar/bar.py`: real Bar content and shared lifecycle with
  isolated system adapters and an offscreen native-window substitution; trigger
  clicks, stable slots, original suppression/restoration, left/centre/right,
  reset-on-open, outside-close route, CC handoff, fullscreen state, rapid toggles
  and legacy anchored-host lifecycle. This is not a compositor simulation.
- Existing shared-status48-step lifecycle; Settings store/migrations and module
  integration; Launcher backend/search/schema/presentation including hidden apps;
  Clipboard schema/presentation; Notifications presentation.
- `git diff --check` and exact path reconciliation before final review.

Live validation on eDP-1, logical1920×1080 at scale2:

- Operator answered **All checks passed** for time/date click open/close,
  navigation, Escape, outside click, absorption and clean restoration.
- Open diagnostics: Calendar phase3 at(14,10),344×406; original clock/date opacity0;
  keyboard and outside catcher enabled. Closed: phase0, both opacity1, input released.
- Screenshot inspection confirms compact integrated header/grid and no duplicated
  bar clock/date. Screenshot remains in `/tmp`, not source control.
- Hyprland reports reserved `[0,48,0,0]` closed and open; the same1920×1080 main
  Quickshell top layer remains. No Calendar layer/window is created.
- `hyprctl configerrors` is empty. No shell restart or Hyprland edit was performed.
  Calendar loads cleanly; earlier unrelated launcher-image warnings in the
  long-lived process log are not represented as new Calendar warnings.

## Limits and follow-ups

No events, agenda, accounts, reminders, external providers, weather or event
creation. Future event data can be keyed by civil date beside CalendarModel;
it should not own the clock or shared-surface lifecycle. Google, Outlook and
CalDAV need separate consent, storage and provider design in later milestones.
No provider framework is introduced here. Non-Gregorian/RTL presentation,
multi-output/fractional-scale testing and further animation/composition polish
remain future work. Existing top-only bar support is unchanged. The accepted
launcher/grid, Rofi fallback, Clipboard and notification ownership remain intact.

## Exact intended Git path allowlist

Paths below are repository-root relative. Exclude operator-local settings,
all runtime/cache/history files, screenshots, Hypridle and Hyprlock. No staging,
commit or push has been performed. The allowlist is the complete intended source,
test and documentation change set for this milestone.

39 paths:

```text
linux/magi/.config/quickshell/magi/components/bar/Bar.qml
linux/magi/.config/quickshell/magi/components/bar/SharedStatusSurface.qml
linux/magi/.config/quickshell/magi/components/calendar/CalendarContent.qml
linux/magi/.config/quickshell/magi/components/calendar/CalendarSurface.qml
linux/magi/.config/quickshell/magi/components/calendar/TimeDatePill.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsApplication.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsWindow.qml
linux/magi/.config/quickshell/magi/components/settings/pages/CalendarPage.qml
linux/magi/.config/quickshell/magi/plugins/bar/clock/Clock.qml
linux/magi/.config/quickshell/magi/plugins/bar/date/CalendarDate.qml
linux/magi/.config/quickshell/magi/services/Calendar.qml
linux/magi/.config/quickshell/magi/services/CalendarMath.js
linux/magi/.config/quickshell/magi/services/CalendarModel.qml
linux/magi/.config/quickshell/magi/services/ClockState.qml
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/shell.qml
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/calendar-date-surface.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/README.md
linux/magi/docs/research/calendar-apis.md
linux/magi/tests/calendar/bar.py
linux/magi/tests/calendar/bar.qml
linux/magi/tests/calendar/content.qml
linux/magi/tests/calendar/math.cjs
linux/magi/tests/calendar/presentation.py
linux/magi/tests/calendar/schema.cjs
linux/magi/tests/calendar/settings.qml
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/launcher/schema.cjs
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
```
