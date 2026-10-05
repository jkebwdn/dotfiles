# First-party Emoji Picker — uncommitted review checkpoint

Baseline verified 2026-10-05: `4f4205dd021a44ce88acad3869799edfcc243ab2`
(`magi: add calendar date surface`). The pre-existing modified `settings.json`
and untracked Hypridle/Hyprlock operator files are excluded from the allowlist.
No commit/push, package changes, shell restart or Hub consolidation.

## Experience and architecture

`SUPER+.` toggles a compact centred Emoji grid. Search is focused when the surface
appears. Type to filter; arrows move one cell/row, PageUp/PageDown move five rows,
Enter copies, Escape closes. Ctrl+Left/Right cycles categories; selecting a
category clears the query. Mouse click selects; hover tooltip and footer name
identify entries. An outside click is consumed and closes the surface.

- `data/emoji/emoji.json`: generated Unicode Emoji 17.0 metadata, 3,944 entries.
- `EmojiSearch.js`: pure preparation/validation, normalization, ranking,
  categories, exact selection and Recents ordering.
- `Emoji.qml`: data lifetime, query/category/selection state, Settings access,
  copy completion and stable `emoji.open/close/toggle/status` IPC endpoint.
- `EmojiContent.qml`: reusable themed search/category/grid presentation; consumes
  a service interface with no dependency on a window or Application Launcher.
- `EmojiWindow.qml`: temporary full-output transparent overlay carrying the
  compact content and outside-click catcher, with exclusive focus only while
  visible and `ExclusionMode.Ignore`. It reserves no space.
- `shell.qml`: closes Emoji when Launcher, Clipboard, Notifications, Settings or
  an anchored menu opens; Emoji open closes the other utility surfaces and
  MenuController. Fullscreen suppresses/closes Emoji. Existing bar code and the
  Calendar/Control Centre animation system are unchanged.

The dedicated Emoji host is intentionally temporary. Future **MAGI Hub** will
host Apps, Notifications, Emoji and Clipboard as separate subsystems; each direct
shortcut opens its requested mode. `emoji toggle` can later route to Hub's Emoji
mode while retaining model/content. Control Centre and Calendar remain separate
anchored surfaces. No extraction or Hub implementation occurs in this milestone.

## Dataset, search and variants

Source and license: [Unicode 17.0 provenance/update instructions](../../.config/quickshell/magi/data/emoji/README.md)
and [technical evidence](../research/emoji-picker-apis.md). Uses fully-qualified
sequences only, omitting qualification duplicates and standalone components.
Names are authoritative English emoji labels from Unicode's file. Useful metadata
includes group, subgroup and per-entry emoji introduction version.

Search normalizes NFKD accents, case, punctuation separators and whitespace.
Every query token must match; exact full-name match receives a bonus, followed by
name exact/prefix/word/substring matches. Category/subgroup matches have lower
weight. Unicode source order resolves ties deterministically. Literal emoji can
also be searched. No fuzzy search, learned ranking, external requests or invented
aliases. `laugh` finds rolling-on-the-floor-laughing; `fire` ranks🔥 first;
`thumb`, `heart` and `cat` find name/metadata matches. Node measured about 1.3–1.5ms
per search over all entries here; that is a local measurement, not a latency SLA.

The restrained category selector contains All, Recently Used and all nine Unicode
groups: Smileys & Emotion, People & Body, Animals & Nature, Food & Drink,
Travel & Places, Activities, Objects, Symbols and Flags. **Nonempty search spans
all categories.** Clearing it returns to the selected category.

Complete VS16, skin-tone, ZWJ, flag and tag sequences are stored/rendered/copied as
strings without splitting. Skin tones are separate searchable results; a dedicated
variant chooser is deferred. Newer glyphs may be missing or decomposed with older
fonts even though copied data is exact. No fonts or third-party artwork bundled.

## Selection, history and Settings

Copy uses MAGI's existing `wl-copy` handoff, now shared through
`clipboard_backend.py:copy_payload`. It passes the exact UTF-8 sequence with
`text/plain;charset=utf-8`. No shell command interpolation. Clipboard Manager's
existing capture/privacy policy still applies, so selected emoji may enter its
history. Copy success closes by default; failure stays open with a retry message
and does not add a recent. Completion from an earlier closed/open session cannot
close a newly reopened picker. Direct insertion is deliberately unavailable;
**choose → copied → close → paste normally**. Existing Hyprland key synthesis
is not a reliable universal insertion API; no injection package was added.

Schema 9 migrates schema 8 additively. The Emoji Settings page provides enabled,
grid columns 4–12 (default 8), size 20–48px (default 28), category selector visibility,
close-after-copy (default true), recent limit 0–60 (default 24), clear history and
reset section. Palette and roundness remain global.

Recents persist as deduplicated sequence IDs through the existing Settings writer.
A successful copy promotes an entry; reopening shows Recently Used when nonempty,
otherwise All. Unknown IDs are ignored by presentation. Reducing the limit
atomically discards older history; 0 erases/disables it. Clear removes history only;
reset Emoji/all Settings resets preferences and history. Recents are ordinary
local Settings data, independent of Clipboard's opt-in history persistence.
Settings read-only/conflict/storage failures retain the standard Settings error
handling; copying itself does not depend on history being saved.

## Validation

Passed on 2026-10-05:

- `node tests/emoji/model.cjs`: data load/count, no duplicates, malformed rejection,
  normalized deterministic ranking, all categories, exact single/VS16/modifier/
  ZWJ-family/profession/regional/tag sequences, selection bounds and Recents.
- `node tests/emoji/schema.cjs`, `python3 tests/emoji/backend.py`: schema 8→9,
  preservation/validation/ranges, bounded history, parser/checksum rejection,
  exact clipboard argv/bytes, timeout/error and input bounds.
- `python3 tests/emoji/presentation.py`: real service/content and Settings page;
  search focus, filter, arrows, Enter, Escape, reopen, categories, exact process
  stdin bytes, copy success/failure, keep-open, Recents dedup/persist/reload/reset,
  disable/fullscreen suppression, atomic history-limit erasure and in-flight
  selection/reopen race protection. The race fixture exposed an asynchronous
  Process.running transition; an immediate service busy guard fixes same-turn
  double selection. The final fixture passes.
- Calendar math/schema/content/Settings/real Bar fixtures, including CC handoff,
  fullscreen, rapid toggle and anchored fallback.
- Launcher search/schema/content/service/hidden-app/Settings fixtures.
- Clipboard schema, 10 model tests, content/service/window fixtures. Two image
  model tests failed inside the sandbox; all 10 passed outside it. No source fix
  was needed. Existing GLib deprecation diagnostic remains.
- Settings schema/atomic writer and five store fixtures; shared-status lifecycle
  all 48 steps; Notification policy and real toast/centre presentation fixture.
- Rendered EmojiContent was visually inspected in an offscreen screenshot.
- Live Emoji IPC reports 3,944 entries without errors; SUPER+period registration
  is present; monitor reservation is exactly `[0,48,0,0]`; Hyprland configerrors
  is empty. Quickshell loaded changes through its existing reload behavior; no
  explicit restart was performed.

- `python3 tests/emoji/live.py` (approved live checkpoint): production overlay,
  typing/filtering, arrows, Escape, reopen focus, previous-app restoration,
  Calendar/Control Centre handoff in both directions, 48px reservation and empty
  Hyprland configuration errors all passed. No clipboard or Settings edits.
- Operator confirmed **all requested checks pass**: physical SUPER+., search,
  Enter/mouse selection, paste into an app, Escape, outside-click dismissal,
  reopening and returning focus to the previous app.
- Regenerating the dataset from the pinned source produced identical bytes.
- Final live status: closed, 3,944 entries, not busy, no Emoji error; Hyprland
  configerrors empty. The log tail has successful configuration reloads and a
  Qt host-portal app-ID registration warning before those reloads. No Emoji
  runtime warning was reported. `git diff --check` passes; HEAD remains the
  verified Calendar commit.

Offscreen runs filter only the existing unsupported-window-mask and sandbox IPC
socket diagnostics; live evidence above is recorded separately. Multi-output,
fractional scaling and newest-glyph coverage remain unverified. Fullscreen
suppression has automated fixture coverage; no new live fullscreen session test
is claimed. There is no automatic insertion mode to test.

## Exact intended Git allowlist

Paths below are relative to the dotfiles repository root. Keep this milestone
uncommitted for operator review. Do not stage `settings.json`, any runtime files,
Hypridle/Hyprlock operator files, or other paths.

```text
linux/magi/.config/quickshell/magi/components/emoji/EmojiContent.qml
linux/magi/.config/quickshell/magi/components/emoji/EmojiWindow.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsApplication.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsWindow.qml
linux/magi/.config/quickshell/magi/components/settings/pages/EmojiPage.qml
linux/magi/.config/quickshell/magi/data/emoji/LICENSE.txt
linux/magi/.config/quickshell/magi/data/emoji/README.md
linux/magi/.config/quickshell/magi/data/emoji/emoji.json
linux/magi/.config/quickshell/magi/services/Emoji.qml
linux/magi/.config/quickshell/magi/services/EmojiSearch.js
linux/magi/.config/quickshell/magi/services/clipboard_backend.py
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/shell.qml
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/emoji-picker.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/README.md
linux/magi/docs/research/emoji-picker-apis.md
linux/magi/tests/calendar/schema.cjs
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/emoji/backend.py
linux/magi/tests/emoji/content.qml
linux/magi/tests/emoji/failure.qml
linux/magi/tests/emoji/live.py
linux/magi/tests/emoji/model.cjs
linux/magi/tests/emoji/presentation.py
linux/magi/tests/emoji/race.qml
linux/magi/tests/emoji/schema.cjs
linux/magi/tests/emoji/settings.qml
linux/magi/tests/launcher/schema.cjs
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/magi/tools/generate_emoji.py
linux/t15g/hypr/.config/hypr/hyprland.lua
```
