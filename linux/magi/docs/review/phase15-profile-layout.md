# Profile Settings recursive-layout investigation

Reviewed 2026-10-27 against accepted `4a26d6232c97266f011355b8fb932f8e0436c0e6`.
Classification: **baseline production layout defect**, exposed by the strict
Phase 15 regression runner. Not an environment limitation or a new Phase 15 regression.

## Exact warning and chain

Qt reports:

```text
QML SettingsRow at @components/settings/pages/ProfilePage.qml[54:5]:
Qt Quick Layouts: Detected recursive rearrange. Aborting after two iterations.
QML SettingsRow at @components/settings/pages/ProfilePage.qml[38:5]:
Qt Quick Layouts: Detected recursive rearrange. Aborting after two iterations.
```

Rows 54/38 own Personal message and Display name respectively. Instrumenting a
**disposable copy** of SettingsRow shows the parent remains 520px wide while the
row's provisional width alternates:

| Field | Unconstrained text implicit width | Two-column constrained row width | Result |
| --- | ---: | ---: | --- |
| Personal message |731.75px (row732) |319px |732→two columns→240px field cap→319→one column→cap removed→732 |
| Display name |565.6875px (row566) |349px |566→two columns→240px field cap→349→one column→cap removed→566 |

The old `columns: width < 420 ? 1 : 2` reads the same row's provisional width
that the column-specific preferred/maximum field constraints change. Qt's parent
layout is still measuring the row, not yet assigning its final 520px width.
The loop occurs before final geometry settles. `Layout.minimumWidth: 0` on the
text field alone did not break it. A fixed field implicit width or unconditional
field hints also stopped it, but would alter natural sizing or stacked-row policy.

## Minimal correction

Only production file changed:
`.config/quickshell/magi/components/settings/SettingsRow.qml`.

```qml
// The parent owns available width. Our provisional implicit width changes
// when the trailing field constraints switch, so it cannot choose columns.
columns: (!parent || parent.width < 420) ? 1 : 2
```

The parent allocates available row space; the row selects the responsive column
count from that independent input. Existing fieldWidth 240, compact steppers,
trailing alignment and stacked fields are unchanged. Explicit `columns` on
multi-cell rows continue to override this default. No Profile-specific string
special case, deferred timer, warning filter or preview-architecture change.

## Profile and host audit

Display name and Personal message are the two SettingsRow/TextField pairs.
The conditional message row participates only when custom text is enabled.
Weather units use a selector; Weather location is a direct field inside a
ColumnLayout. Avatar actions use RowLayout/ColumnLayout with explicit artwork
size. Neither uses the self-width column selector. Launcher header-path fields
also use direct ColumnLayout sizing. Date/time rows use bounded selectors and
Security rows use toggles/labels: those children do not have the same long-text
implicit-width trigger. The shared-row fix prevents the same measurement cycle
for any conventional two-field row rather than changing Profile text handling.

The reliable trigger is first creation of Profile with long persisted identity
values in the full Settings host, reached while the Control Centre preview is
pinned. Short initial values can hide it by allowing stable geometry before later
text edits. A standalone, already-sized Profile page does not reproduce it.
The parent stays 520px in the traced full host; preview width is not oscillating.
The reproduction uses actual accepted Hub/Settings components and normal output
geometry, with only native window wrappers and external services replaced.

## Regression and visual evidence

`tests/runtime-visual/profile.qml` seeds long values before first page creation,
opens Settings and pins the preview, navigates through Appearance to Profile,
then covers short/long display names and empty/long messages at 800,1280,1920px
host widths in Mocha and Rosé Pine Dawn. It checks visible positive geometry,
row/field bounds, alignment, 240px trailing fields where two-column, conditional
message visibility, and preview retention. The harness rejects every recursive
warning even if assertions emit PASS. The new command is included in run-all.

Negative control: same fixture with only SettingsRow restored from accepted HEAD
emits four recursive warnings (`/tmp/magi-phase15-profile-negative3.log`). Fixed
focused captures preserve the compact identity composition, secondary Choose
avatar, quieter Clear avatar and conditional Weather controls. Gallery:
`/tmp/magi-phase15-profile-previews`. These are offscreen software-rendered
geometry captures, not native renderer quality claims.

Focused/full results are recorded in the regression reconciliation report.

The operator confirmed the native smoke check passes: long Profile identity text
with the preview pinned, plus Bar, Apps, Audio, Bluetooth, Tray and Settings.
The live shell reloaded cleanly in the same process.
