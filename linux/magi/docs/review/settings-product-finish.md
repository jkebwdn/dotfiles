# Settings product finish — gallery, navigation and editors

2026-10-28. Baseline: `176732a2cbd0ecafed0b867928647a29afa8f2c1`, the accepted,
pushed Phase 16B mask-feedback and Settings-toggle fixes. Settings schema stays 22.
The gallery is accepted. The subsequent authorised navigation/editor/feedback candidate is described in the implementation review below. The earlier proposals are retained as decision context.

The first pass implemented the authorised visual theme gallery. Sidebar, Lock editor,
Bar guidance and feedback were proposals at that gate; their newly authorised
implementation is recorded below. Control Centre interaction remains unchanged.

## Implemented theme gallery

- By default, one row of the current theme's family variants is visible. “Show all
  themes” expands the complete vertical family grid; “Show fewer themes” collapses
  it. There is
  no nested gallery viewport; the Settings page owns vertical scrolling.
- All 26 registry entries remain first-class choices. Family names and light/dark
  classification come from the registry, preserving first-seen family order and
  existing variant order: Catppuccin, Everforest, Rosé Pine, Nord, Tokyo Night,
  Gruvbox, Kanagawa, Dracula, One, Ayu. Stored IDs and defaults are unchanged.
- All / Dark / Light buttons filter locally; All is the initial state. Empty
  families disappear, remaining families stay grouped. Filters do not save Settings.
  No search, family accordions or alternate theme-selection authority were added.
  The gallery disclosure and filter are local view state, not saved preferences.
  Collapsing always shows the current theme even if the browse filter excludes it.
  When a family has more variants than fit, the preview retains nearby variants in
  registry order, always including the selected theme; all remain available expanded.
  Selecting an already-visible variant preserves the row and focus instances.
- Cards show background, surface, elevated tone, primary/muted text, accent,
  secondary accent, blue, success, warning and danger. Labels retain registry names.
  Selected cards have a border and check badge; keyboard focus, hover and pressed
  states remain separate. The current theme name remains visible above the grid
  even when its card is filtered out or below the viewport.
- Cards are 138px high, with a 176px target minimum and 220px maximum width.
  Available page width determines columns: two at 720px Settings width, three at
  1000px and five at 1280px. Appearance's body maximum is widened to 1100px so
  wide windows can use the additional space. Other pages retain their widths.
- Tab follows the normal control order, with one tab stop among the cards.
  Left/Right move through visible choices; Up/Down follow grid rows across family
  boundaries, clamping at incomplete rows. Enter/Space applies through the existing
  Settings setter. Arrow focus alone never selects a theme. Escape remains owned
  by the Settings host. Focused cards and the control reached when tabbing out are
  scrolled into view without introducing another scrolling surface.

## Visual evidence and limits

Synthetic captures cover One Light, Gruvbox Light, Rosé Pine Dawn, Everforest Dark
Hard, Kanagawa Wave and Dracula at normal and compact widths. The representative
Settings set also covers Bar Layout, Bar Appearance, Control Centre, Wallpaper,
Lock Screen and Profile in one dark and one light theme; selected pages have
compact and wide variants. These are isolated fixtures, not native acceptance.
Software rendering does not reproduce every semantic SVG icon. Wallpaper fixtures
are inert, and isolated application-enrollment status does not represent the host.

The previews retain meaningful differences rather than flattening palettes to one
accent: Kanagawa's Wave/Dragon backgrounds and status tones; warm Gruvbox versus
Everforest greens; Dracula purple/pink versus One Dark blue; cool One Light versus
warm Gruvbox Light; and Catppuccin's different surface/foreground levels. Exact
palette roles are used without theme-name-specific rendering branches.

The first native gallery review passed, including keyboard/filter/width checks and
source cleanliness. The operator then requested a collapsible gallery with a row
of theme cards left visible. The authorised refinement restores Icon Pack and
Roundness to the normal first viewport while retaining full visual browsing when
expanded. Captures confirm a single row at compact, normal and wide widths; the
current theme remains present even for larger families and filters that exclude it.
The operator confirmed the refinement works, and its final state check passed.

[Collapsed dark view](settings-product-finish/gallery-collapsed-dark.png) ·
[Collapsed light view](settings-product-finish/gallery-collapsed-light.png) ·
[Collapsed compact view](settings-product-finish/gallery-collapsed-compact.png)

[Normal dark gallery](settings-product-finish/gallery-dark.png) ·
[Normal light gallery](settings-product-finish/gallery-light.png) ·
[Compact gallery](settings-product-finish/gallery-compact.png) ·
[Current compact Lock editor](settings-product-finish/lock-compact-current.png) ·
[Family comparison and selected state](settings-product-finish/family-comparison-dark.png) ·
[Selected state in One Light](settings-product-finish/selection-light.png)

## Top remaining unfinished-feel issues

| Priority | Finding | Direction / boundary |
| --- | --- | --- |
| P2 | Lock presets and preview-state controls consume the compact first viewport; the selected inspector sits below the canvas at normal widths. | Bring selection, preview and inspector together; composition proposal below, not implemented. |
| P2 | The flat sidebar requires knowledge of subsystem ownership. | Group existing destinations by intent, with no removed pages or duplicate ownership. Requires review. |
| P2 | Bar family styling is correct but its discovery and semantic-role labels require explanation. | Short contextual selection guidance and friendly visible role names; preserve IDs and family/item rule. Proposal only. |
| P2 | Preference-save status and application activation status answer different questions without a consistent presentation pattern. | Preserve distinct authorities; present a coherent quiet status model. Proposal only. |
| Resolved | The full gallery pushed other Appearance controls down the page. | Operator-authorised disclosure now keeps a current-family preview row visible; native review and source-cleanliness verification passed. |

## Sidebar — original proposal

Current visual order: Appearance, Transparency, Bar, Control Centre, Hub, Profile,
Date & time, Notifications, Clipboard, Launcher, Emoji, Wallpaper, Power & Idle,
Displays, Lock Screen, Security.

Proposed compact information architecture:

```text
MAGI
Personalisation
  Appearance · Wallpaper · Transparency · Profile
Desktop
  Bar · Control Centre · Hub · Date & time
Everyday tools
  Launcher · Notifications · Clipboard · Emoji
Session & hardware
  Lock Screen · Security · Power & Idle · Displays
```

The diagram expresses ordering; the actual sidebar would keep one destination per
row, restrained group labels and the elevated background. Personalisation collects
how the desktop looks and identifies the user. Desktop describes the persistent
shell composition. Everyday tools collects launch/history/picker preferences.
Session & hardware keeps lock/security, idle policy and outputs adjacent.

No page is merged, renamed or removed. Internal page IDs, retained loaders and
scroll/context ownership remain unchanged. Four small headings add vertical cost,
so compact geometry needs an explicit prototype review before implementation;
collapsible groups are not assumed. Lock Screen's visual editor remains a destination
here even though it appears beside security, rather than duplicating it under
Personalisation.

## Lock Settings — original proposal

Preserve the native lock and existing canvas/inspector model. Make the selected
preset a compact visual summary with an explicit visual preset chooser, instead
of five full cards permanently preceding the editor. Move synthetic state/aspect
choices into a restrained Preview options disclosure. Keep the canvas and selected
inspector side by side where space permits; at compact widths show a bounded
canvas immediately followed by the selected-element heading and its common controls.
Precision offsets remain secondary. Avoid a second independent scroll area until
keyboard and touch behaviour demonstrate a need.

This changes editor composition and needs approval. A prototype must show that the
preview remains useful, selected controls stay discoverable, and authentication
cannot become hidden or lose prominence. It must not touch native authority, PAM,
credential storage or the accepted per-character mask behaviour.

## Bar guidance — original proposal

Keep the full-width preview above controls and the current selection model. Suggested
context headings are “Bar background”, “Status pills” and “Workspace pills”, with a
single hint such as “Select a group to change its style”. Individual items retain
identity/options only. Precision role selectors could display “Surface”, “Raised
surface” or “Accent” while preserving stored role IDs and actual palette previews.
Do not add tutorial panels or turn shared family controls into per-item styling.

## Feedback model — original proposal

| Question | Quiet healthy state | Actionable exception |
| --- | --- | --- |
| Is my preference saved? | Existing global “All changes saved” | Saving / could not save; preserve the actual error and recovery action. |
| Is it active in MAGI? | Immediate selected state on the visual choice | A local activation error near the affected choice. |
| Is it active in another application? | Compact existing per-application result | Applied / next launch / new shell / restart required / apply failed. |
| Is this still a draft? | Explicit Save only for deliberately staged input | “Not saved” beside Weather location or directory draft until its Save action succeeds. |

Persistence and activation must not be collapsed into a misleading single success
indicator. Healthy application details can remain disclosed; errors and required
manual actions should be visible without exposing journals, generations or internal
target names. This is a presentation proposal, not a change to transaction semantics.

## First-viewport and density review

| Page | Current conclusion |
| --- | --- |
| Appearance / theme gallery | A current-family row appears immediately, followed by Icon Pack and Roundness. Expanding reveals filters and all family groups for vertical browsing. |
| Bar Layout / Appearance | Preserve full-width preview above controls. Improve selection guidance only after review. |
| Control Centre | Preserve vertical composition and existing family/item semantics; no editor change is justified here. |
| Wallpaper | Image-first browsing is appropriate; directory setup remains explicitly saved and secondary. |
| Lock Screen | Strongest remaining composition issue, especially compact; see proposal. |
| Profile | Compact identity, aligned fields and secondary avatar actions are a good pattern; no restructuring proposed. |

## Validation and acceptance

Focused gallery coverage verifies all themes/families, metadata filtering, stable
ordering, selected state, keyboard traversal/activation, responsive columns, no
horizontal overflow, focus visibility on leaving the gallery and restoration of
the original theme. Filters do not increment Settings revision; theme round-trip
restores effective preferences. Object comparison is semantic: JSON property order
may change when Settings writes a preference, without changing its values.

The Phase 12F test now scrolls to controls that follow the expanded gallery rather
than assuming their old viewport position. Its horizontal Shift-wheel/trackpad
coverage remains on a generic SettingsGallery fixture; the new theme grid is tested
for vertical page scrolling. Existing palette/adapter/ownership tests remain intact.

Full canonical regression completed: **90 commands, 86 PASS, 0 FAIL,
4 ENVIRONMENT, 0 SKIPPED**, with no unknown failures. Limits are the existing
private-bus Bluetooth/Notifications, Clipboard image decoding and native-lock
socket restrictions. Focused Settings presentation, Phase 12F and gallery checks
also pass after the keyboard focus-reveal adjustment. Link sanity and
`git diff --check` pass. The initial gallery passed native appearance, filter, keyboard and width review;
its source-cleanliness check passed with original effective Settings restored and
no new theme errors. The collapsible refinement also passed the reconciled full regression and native acceptance recorded below.
No live Settings or tracked workstation configuration has been edited by this pass. No broad sidebar, Lock, Bar, Control Centre or navigation redesign has
been applied. The related refinements are focus reveal when tabbing out of the
longer gallery and the explicitly authorised gallery disclosure. Stop for operator review before further product restructuring.

### Disclosure regression

The focused fixture additionally covers default collapsed state, keyboard activation
of the disclosure, one-row bounds at three widths, every registry theme remaining
visible in its family preview, preservation of card instances when selecting within
the row, hidden filters when collapsed, filter retention on reopen, and no Settings
revision change from expansion/collapse. Historical full-gallery tests explicitly
expand before asserting all themes. Initial gallery native acceptance remains valid
for the underlying cards; the disclosure also passed its subsequent native check.


The disclosure full run exposed one stale palette-composition assertion: it treated
the selected card index as a global registry index. Collapsed cards are a subset,
so the enduring invariant is that the visible selected card has the requested
registry ID. The fixture now checks that ID and retains its selected-state check.
Its composite preview also places the other surfaces below the gallery's implicit
height rather than the former 160px carousel box. No production code was changed
for this fixture correction; the palette suite passed its separate focused rerun.

The older Phase 10A icon/Settings fixture likewise assumed all registry cards were
visible on initial opening. It now explicitly expands the gallery before its
wide/narrow full-library checks. Icon resolution, application-icon boundaries and
all other assertions remain unchanged. These are fixture-contract corrections,
not suppressed failures or production workarounds.


Disclosure validation is reconciled: **90 commands, 86 PASS, 0 FAIL,
4 ENVIRONMENT, 0 SKIPPED**, with no unknown failures. The initial refinement run
reported 84 PASS and the two stale fixture failures above; both corrected suites
pass their focused canonical reruns. The original run and indexed reconciliation were checked during closeout. All production source was unchanged by these two
fixture corrections. Focused disclosure/context tests, affected Settings tests and
`git diff --check` pass. The guarded native update was applied and accepted by the operator.


## Final native acceptance and review gate

The operator applied the disclosure refinement and confirmed “all working”. The
subsequent guarded check passed: only the two intended gallery source files differ
in the production checkout; all other tracked/protected configuration is unchanged;
the index is empty; original effective Settings, including Catppuccin Mocha, are
restored; and no new Theme Orchestrator/application errors were reported. Live
Settings remains ignored and operator-local.

Gallery browsing, disclosure, keyboard controls, filters and compact/normal widths
are natively accepted. The operator authorised closeout after native acceptance. Sidebar,
Lock composition, Bar guidance and feedback-model proposals remain unimplemented;
no further product restructuring is authorised by this acceptance.

### Closeout verification

Accepted production hashes matched both checkouts. Final canonical focused checks
passed: Theme gallery, Settings presentation and Phase 12F presentation (**3 PASS,
0 FAIL**). The already reconciled 90-command matrix was not repeated; production
bytes remained unchanged after native acceptance. Schema remains **22**.


## Navigation, editor and feedback implementation review — 2026-10-28

Baseline: `abb032855bc300e5212c337c241ec02127f81f2e`. Candidate is isolated in a
temporary worktree. The operator approved the grouped sidebar and editor
composition for native review, then confirmed native interaction acceptance.
This work was explicitly authorised after the gallery closeout. Earlier “not
implemented” and review gates above describe that earlier point in time.

### Source audit and final sidebar order

The actual destinations come from `SettingsContent.qml`, with retained loaders and
`SettingsWindowState` owning selection. The displayed Transparency destination keeps
its **Applications** internal ID. No routes, page ownership or persisted data change.
Group headings are non-focusable; Tab retains ordinary button traversal, arrows
move between destinations, Enter/Space select. Focus and direct-route selection
reveal the destination within the existing scrolling sidebar. Resizing reveals
keyboard focus first, or the selected page when focus is outside navigation; it
does not steal focus or change the page.

| Group / displayed destination | Icon role | Component | Intent / existing owner |
| --- | --- | --- | --- |
| Personalisation / Appearance | settings | AppearancePage | Theme, icons, shell styling; Settings + Theme Orchestrator |
| Personalisation / Wallpaper | image | WallpaperPage | Choose backgrounds; Wallpaper service |
| Personalisation / Transparency | apps | ApplicationsPage | Shared background alpha/blur; appearance and blur services |
| Personalisation / Profile | profile | ProfilePage | Identity/weather preferences; Settings, AssetManager, Weather |
| Desktop / Bar | menu | BarPage | Layout and shared styling; Settings Bar model |
| Desktop / Control Centre | settings | ControlCentrePage | Visual contents/style; existing CC editor |
| Desktop / Hub | hub | HubPage | Utility surface styling; Settings/Hub |
| Desktop / Date & time | calendar | CalendarPage | Clock/calendar presentation; Settings/Calendar |
| Everyday tools / Launcher | apps | LauncherPage | Application catalogue preferences; Launcher |
| Everyday tools / Notifications | notifications | NotificationsPage | Notification policy; Notifications |
| Everyday tools / Clipboard | clipboard | ClipboardPage | History/privacy; Clipboard |
| Everyday tools / Emoji | emoji | EmojiPage | Picker preferences; Emoji |
| Session & hardware / Lock Screen | lock | LockScreenPage | Visual lock layout; existing saved lock model |
| Session & hardware / Security | lock | SecurityPage | Existing security preferences; native lock authority unchanged |
| Session & hardware / Power & Idle | power | PowerIdlePage | Idle/session policy; existing Settings/native policy |
| Session & hardware / Displays | settings | DisplaysPage | Output configuration; existing display policy |

Four restrained headings preserve shallow navigation and the elevated sidebar.
The native review must confirm that the extra scrolling at short heights feels
comfortable; no accordion or page merger was introduced.

### Lock composition

The current preset stays visible as a compact “Layout · …” disclosure; opening it
reveals the same five **visual** preset cards. Synthetic state/aspect/depth options
move below the editor into Preview options. All disclosure state is view-local.
At content widths of at least 650 logical pixels, the canvas and inspector share a
row. Narrower content uses a bounded, aspect-correct canvas immediately followed by
“Edit Time/Identity/Authentication/Weather/Media” and the element selector/size.
The short nearby hint is “Select an element to edit · drag to arrange”; full keyboard
instructions remain in Preview options. Fine tune retains anchors/offsets and the
unavailable depth explanation. No canvas transform, lock model, native lock or
credential code changed. Drag, nudge, snapping, z-order and authentication safety
remain owned by the existing canvas/model.

Rejected: clipping a full-width canvas to a shorter rectangle, shrinking controls,
text-only preset selection, a second scrolling inspector, and native lock changes.
The canvas keeps its aspect ratio by bounding width as well as height. Long style
inspectors still require page scrolling; a sticky inspector is deliberately deferred.

### Bar guidance

A quiet context line distinguishes “Selected item · identity and options” from
“Shared style · changes affect the whole group”. Background selection names the
Bar background and invites selection in the preview. Individual selections retain
the collapsed shared-style section, now explicitly described as shared with other
items. “Background role” becomes “Background colour”; exact palette role values
remain unchanged for precision. The full-width preview, hit regions, drag/reorder,
Left/Centre/Right/Available model and family/item ownership are untouched.

### Feedback presentation

`SettingsFeedback.js` is a presentation-only mapper over existing state. It does
not write Settings, invoke activation, retry automatically or infer activation from
persistence. The global indicator remains subtle “All changes saved” / “Saving…”.
Conflict, invalid, future-version and save-error states use plain language; original
diagnostics remain in the status tooltip and existing reload action is retained.

Appearance shows pending application work, restart/reload/manual steps or failures
next to theme selection, with a Review application themes action that opens and
reveals existing details. It says “Your choice is saved” **only** when persistence
reports saved. Healthy live activation adds no banner; next-launch counts remain
in the application section, with zero counts omitted. Per-target failure text is
plain and actionable; raw diagnostics remain available in expanded details. Global
failure diagnostics remain in the error tooltip. Adapter status labels, capability
boundaries and retry operations remain unchanged.

Transparency uses the same presentation vocabulary, removes the stale “native
review pending” message and quiets successful global blur feedback. Global blur
errors retain expandable diagnostics. Wallpaper explicit directory saves, lock
layout edits and Profile drafts keep their distinct semantics; there is no generic
“Applied” claim for a merely persisted choice.

### First-viewport and remaining concerns

Appearance retains the accepted gallery. Bar and Control Centre retain their
visual editors. Wallpaper stays image-first and Profile keeps its compact identity
composition. No additional density changes were justified on those pages. The Lock
page now exposes the selected element and size in the compact first viewport.
In the matched 1000×720 synthetic captures, initial Lock content height falls from
1596 to 651 logical pixels (both tested themes); this measures layout/disclosure,
not rendering performance. Controls remain reachable by opening disclosures.

Existing Phase 16 palette contrast/reduced-motion/tooltip debt is not reclassified
as a new discovery. Preview captures use the software renderer and synthetic data;
some semantic icons are absent there. Native review remains required for real icon
rendering, sidebar scrolling, lock editing, activation feedback, gallery behaviour
and Super+S. No schema bump: **22**.


### Additional bounded navigation correction

A focused negative control reproduced the selected destination falling below the
viewport when Settings was shortened. The resize reveal now preserves keyboard
focus preferentially (focus and selected page can differ). The first attempt
revealed only selection and failed the established focus-visibility assertion;
that attempt was corrected, not waived. The existing presentation suite and the
new compact resize regression both pass. Section headings are accessible headings,
not Tab stops; destinations now explicitly expose their displayed accessible name.

### Validation plan and review boundary

Focused Settings presentation, Phase 12F, application-theme QML integration and
new product-finish checks pass. The final full matrix runs against a frozen source
and test hash manifest after the resize correction. The operator approved native review after inspecting the candidate, then confirmed
all requested native interactions passed. Only the six reviewed presentation files
were integrated; no preferences or workstation configuration were changed.


### Candidate visual evidence

| Task | Before | Candidate |
| --- | --- | --- |
| Compact Lock | [Before](settings-product-finish/refinement/lock-compact-before.png) | [After](settings-product-finish/refinement/lock-compact-after.png) |
| Normal Lock | [Before](settings-product-finish/refinement/lock-normal-before.png) | [After](settings-product-finish/refinement/lock-normal-after.png) |
| Light compact Lock, 16:9 preview | — | [Selected controls](settings-product-finish/refinement/lock-compact-light.png) |
| Bar shared group | — | [Group context](settings-product-finish/refinement/bar-group.png) |
| Bar individual item | — | [Item context](settings-product-finish/refinement/bar-item.png) |
| Sidebar / saved versus restart | — | [Light gallery and restart](settings-product-finish/refinement/feedback-restart.png) |
| Application failure | — | [Saved preference and actionable error](settings-product-finish/refinement/feedback-error.png) |

Before/after Lock pairs use the same offscreen display aspect and synthetic state.
The additional light compact capture explicitly selects 16:9; no host display or
operator preference is changed by captures. Healthy save feedback appears subtly
at the bottom of the sidebar in each image.


### Final offline result

Final frozen-candidate run: **91 commands, 87 PASS, 0 FAIL, 4 ENVIRONMENT,
0 SKIPPED, 0 UNKNOWN**. The four limits remain private D-Bus creation for
Bluetooth/Notifications, the independently identified Clipboard PNG/D-Bus issue,
and unchanged native-lock SOCK_SEQPACKET restrictions. The clean native build
succeeded. The earlier exploratory full run also completed with 87/0/4; final
acceptance uses the second complete run after the sidebar resize correction.

Production/test hashes were rechecked after the final run and native acceptance.
Focused checks, review links and `git diff --check` pass. The guarded integration
applied only the six reviewed presentation files. Its final check verified an empty
index, protected local files, original effective Settings, byte-identical live
Settings, no new theme errors and empty Hyprland configuration errors. The operator
separately confirmed sidebar navigation, Lock editing, Bar guidance, feedback,
the theme gallery and Super+S interactions passed.

Native acceptance is complete. No native lock/security code, theme authority,
stable page IDs or schema changed. Further product work is outside this closeout.
