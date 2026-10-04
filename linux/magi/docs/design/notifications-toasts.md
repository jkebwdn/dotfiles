# Notifications and toasts

Milestone baseline: `d539b9b`. Started 2026-10-03. Implementation and operator
acceptance are tracked in [the checkpoint](../research/notifications-toasts-checkpoint.md).
Operator accepted the bounded live checks and supplied toast/Centre screenshots on
2026-10-03. Permanent daemon/startup ownership is now implemented and recorded in
[its close-out checkpoint](../research/permanent-notification-ownership-checkpoint.md).

## Ownership and model

Use Quickshell 0.3.1 `NotificationServer`, never a second handwritten D-Bus server.
One service owns live notification objects and bounded plain-data history;
presentation never owns sender lifetimes. Keep returned ID, application name/icon,
summary/body, urgency, sender timeout, action descriptors, image, desktop entry,
resident/transient flags, MAGI receipt/update time, read state and close reason.
Receipt time is local, not a fabricated sender timestamp. Stable ID is replacement
identity; Quickshell does not expose the original replaces_id separately.

Observe changed properties on tracked objects, coalescing one replacement into
one snapshot. Close signals invalidate actions immediately. Never retain deleted
action objects. Invoke by resolving the identifier against the current live object.
Default card click invokes only an actual `default` action. Clear/dismiss never
invoke application actions. Nonresident action closure is Quickshell-owned.
Quickshell0.3.1 limitations: identical updates may emit no observable change;
same-identifier action-label replacements remain stale (installed test confirmed).

History defaults to 100 entries (configurable 10–500), newest receipt/update first,
evicting oldest deterministically. Bound live entries too, including transients.
Snapshot text is bounded. Image payloads are never serialized; live provider images
are dropped on closure. No disk history in this milestone: avoid fragile sensitive
payload persistence. History resets on process restart and QML reload; tracked
notifications can be recovered on reload without replaying their toasts.
Only the restored emission is quiet; a later sender replacement may show a toast.
Original pre-reload receipt time is not recoverable through the native API, so
restored records receive the new local receipt time.
Transient-hint notifications skip history, including during DND.

## Toast presentation and lifecycle

Separate top-layer, zero-reservation host below the 48px bar, top-right with 14px
edge clearance. One stack host, stable keyed entries, animated entry/exit/reflow.
Explicit native input region combines visible cards only; gaps and the rest of the
desktop pass through. Geometry binds to both card slide and wrapper reflow because
Region.item alone does not observe ancestor motion. No keyboard grab. Default cap
three (1–4 configurable, further capped by available output height at300px/card);
overflow goes to history rather than a delayed flood. Hover pauses expiry.
Expiry sends reason Expired; user dismiss sends Dismissed; client close remains
CloseRequested. Timeout -1 uses 5s fallback, 0 stays until dismissed; critical
defaults stay until dismissed. Positive sender values are milliseconds.
Normal previews are bounded plain text. No markup, hyperlinks, sound or inline
reply capabilities. Semantic palette roles, radius and shared state resolver
provide colors; critical urgency uses palette danger for the rim. App imagery is supplied
by the sender/backend, not inferred. Compact card has app identity, title, preview,
optional image and bounded action area.
Toast action rows show at most three actions; history shows up to sixteen. Text
snapshot bounds are app256/title1024/body8192/action label128 characters. Transient
previews use two title lines and three body lines. Unused provider images are not
cached to disk. Suppressed/overflow notifications still expire from receipt time;
expired ordinary history retains the snapshot with actions unavailable.
Accepted screenshots expose sender markup such as Hyprshot's `<i>` literally.
Safe markup/plain-text normalization is a possible later polish task; do not
enable unrestricted rich text or advertise support without implementation/tests.

## DND, fullscreen and disabled preferences

QuickActions remains the public DND action, backed by Settings as the sole state.
There is no legacy SwayNC query/set fallback after permanent ownership migration.
DND accepts/history-records ordinary notifications but suppresses their toasts.
Critical bypass of DND defaults on, configurable. No fullscreen bypass, including
critical. Hidden notifications are not replayed on leaving fullscreen or DND.
Fullscreen policy is output-local and must check true compositor fullscreen,
not maximized or client-requested pseudo-fullscreen. Entering suppression removes
toast input immediately; timers/model continue. Centre closes on fullscreen.
Notifications enabled controls acceptance/history; disabling closes live entries
without invoking actions. Toasts enabled controls only transient presentation.

## Notification Centre and input

Distinct surface, separate from SharedStatusSurface/MenuController. Configurable
icon-only bell bar entry with restrained unread dot; Legacy fallback allowed.
Bounded scrolling recent history, actual valid actions, dismiss, clear all, DND,
timestamp, empty state. Opening marks existing history read; incoming items while
open are read too. It closes existing status menus when opened. Centre uses its
own bounded native panel/input geometry and Escape/explicit close; no full-output
dismissal catcher. Service survives centre/toast visibility and bar placement.

## Settings and foundations

Keep current SettingsStore, schema migrations, palette roles and primary accents.
Primary/secondary state groups each expose ON role, OFF role, signed OFF shade
and OFF strength. Existing primary preferences migrate intact. Bluetooth compact
visibility follows connectedCount only; registry/service/detail lifetime is stable.
Notification preferences: enabled, toastsEnabled, dnd, fallbackTimeout (ms),
maxVisible, historyLimit, showBody, criticalBypassDnd. No per-app rules.

## Output and migration intent

Host receives an explicit screen; initial presentation follows the existing bar's
output. Model has no window ownership, allowing output routing later without
duplicating the notification server. Multi-output/fractional scaling unverified.
MAGI is the startup owner. Server construction automatically attempts ownership
and retries when an existing owner exits. Production ShellRoot constructs it on
completion. The 2026-10-04 retirement removes SwayNC and its activation/mask/
greeting infrastructure. Test protocol changes on a private bus first.
The server backend remains process-global once constructed; unloading QML alone
does not release the name. The earlier package-preserving rollback procedure in
the permanent-ownership checkpoint is historical and now requires reinstalling
and configuring SwayNC before a separately reviewed ownership handoff.
See the [retirement checkpoint](../research/legacy-shell-retirement-checkpoint.md).
