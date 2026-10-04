# Calendar API evidence — 2026-10-04

Target installed runtime: Quickshell 0.3.1, Qt 6.11.2 and Hyprland 0.56.2.
No third-party implementation or artwork was copied; the references below inform
API usage only. The implementation reuses MAGI's existing shared surface.

| Source, inspected 2026-10-04 | What it demonstrates | MAGI use / compatibility / remaining checks |
| --- | --- | --- |
| [SystemClock, Quickshell 0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/SystemClock/) | `date` exposes clock time; `precision` controls update frequency, including `Minutes`. | `services/ClockState.qml` supplies one clock to both bar pills and Calendar. Installed-runtime formatting and live clock tested. No independent Calendar timer. |
| [TransformWatcher, Quickshell 0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/TransformWatcher/) | Watches transforms between items `a` and `b`; reading `transform` establishes a reactive dependency. | `CalendarSurface.qml` reads the dependency before `mapToItem`, so its origin follows left/centre/right bar arrangement. All three tested with the real Bar content. Multi-output/fractional-scale remain broader shell checks. |
| [Date, Qt 6.11](https://doc.qt.io/qt-6.11/qml-qtqml-date.html) (page reports 6.11.1) | QML Date adds locale-aware formatting; `timeZoneUpdated()` informs the JS engine of external timezone changes. | `ClockState`/`CalendarModel` format local dates via Qt; civil arithmetic uses local noon, without parsing UTC date strings. Month lengths, leap years, DST-weekend navigation and year boundaries tested. There is no timezone-change watcher in this milestone; reload after changing the system timezone/locale externally. |
| [Locale, Qt online documentation](https://doc.qt.io/qt-6/qml-qtqml-locale.html) (page served 6.12) | QML locale supplies `firstDayOfWeek`, standalone weekday/month names and format enums. QML weekday indices are Sunday=0; month indices are January=0. | These are established APIs, verified on installed Qt 6.11.2 with en_GB, en_US and de_DE production-model fixtures. Avoid confusing QML indices with C++ QLocale's weekday enum. Non-Gregorian calendars/RTL layout remain unsupported. |

The new surface inherits `components/bar/SharedStatusSurface.qml`, including its
existing width/height/reveal lifecycle, focus hook, clipping and theme bindings.
Only a default-preserving `headerAlignment` property extends that component.
The native PanelWindow, top layer, mask, OnDemand keyboard focus, outside-click
catcher and 48px reservation remain owned by `Bar.qml`; Calendar creates no window.
These are existing MAGI patterns, confirmed by production code inspection and
live Hyprland layer/monitor queries, rather than inferred from reference images.

The offscreen Bar fixture substitutes a FloatingWindow wrapper because Qt's
headless plugin has no PanelWindow backend. It tests the real layout and lifecycle,
not compositor reservation or stacking. Those were checked separately on eDP-1
at scale 2. See the [milestone checkpoint](../design/calendar-date-surface.md).
