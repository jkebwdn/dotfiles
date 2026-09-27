# Bounded Settings spike: evidence ledger

Inspected **2026-09-26**. Scope: persistence, desktop Settings window, data-driven
themes/configuration and future media. No repository clones, external code/assets
reuse, installations or runtime tests. This is not completion of the deferred
Noctalia v4/Lucid/Caelestia research programme.

The [architecture proposal](../design/settings-architecture.md) separates local
findings from recommendations. Local evidence is pinned to MAGI
`5215bbef5fa3573295c1c1101059d62da502892c`; installed package check this date:
Quickshell 0.3.1-1, Hyprland 0.56.2-3, Qt 6.11.2 packages. Existing runtime acceptance
belongs to earlier records, not this spike.

## Official API evidence

### Q1 — normal desktop window

- URL/version: [FloatingWindow, Quickshell 0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/FloatingWindow/).
- API: `FloatingWindow`, `title`, `minimumSize`, `maximumSize`, `parentWindow`,
  `startSystemMove()`, `startSystemResize()`.
- Documented: a standard top-level window; system move/resize originates during
  a pointer interaction. Parent-window assignment is constrained once visible.
- MAGI proposal: one parentless lazy Settings window, using the existing Settings
  service. No layer-shell role or bar reservation.
- Compatibility/limits: the name does not establish Hyprland floating placement.
  Normal compositor policy still applies. No claim of focus/decoration behavior
  tested on the local session.
- Required tests: open/reuse/close, move/resize, scale 2, focus return from menus,
  password-dialog coexistence, no exclusive-zone change.

### Q2 — file persistence and notifications

- URL/version: [FileView, Quickshell 0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/FileView/).
- API: `atomicWrites`, `setText`, `writeAdapter`, `watchChanges`, `reload`,
  `loaded`, `saved`, `loadFailed`, `saveFailed`.
- Documented: atomic writes default on and replace through a temporary file;
  adapter writes are explicit. Watched changes can include the application's own
  writes. Reload is asynchronous; blockLoading does not make reload synchronous.
- MAGI relevance: current Settings.qml never writes. A sole writer must distinguish
  save acknowledgement from reload, and must not parse stale data after reload().
- Proposal, not API guarantee: debounce/serialize revisions, preserve last-valid
  state, deduplicate identical content, expose conflicts and save failure.
- Required tests: failed/rapid saves, self-notifications, partial external edits,
  read-only paths, symlinks and application exit during a save. Atomic replacement
  is not multi-writer conflict prevention or a guarantee about replacing symlinks.

### Q3 — future real media

- URLs/version: [Mpris](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Mpris/Mpris/)
  and [MprisPlayer](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Mpris/MprisPlayer/), Quickshell 0.3.1.
- API: `Mpris.players`; player identity, `trackTitle`, `trackArtist`,
  `trackArtUrl`, playback state, capability flags, previous/next/togglePlaying.
- Documented: player capabilities vary; callers must check support before using
  controls. The singular artist property is current; the plural form is deprecated.
- MAGI proposal: a small selection facade and CC body section, no independent
  polling backend. No active player means collapse, not mock data.
- Limits/tests: no installed-player interaction was attempted. Verify multiple
  players, disappearing objects, metadata omissions, unsupported controls and
  asynchronous artwork; progress/seek is outside the initial scope.

## Bounded configuration UX comparison

These are **documented product patterns**, not source/runtime audits. Unversioned
pages/branches are explicitly identified; they are not API compatibility evidence.
No source snippets or visual assets are being incorporated into MAGI.

| Reference / exact source | Version and demonstrated behavior | MAGI inference / limits / required test |
| --- | --- | --- |
| [Noctalia configuration](https://docs.noctalia.dev/noctalia/configuration/) | Page explicitly covers **v5+**, not legacy Quickshell v4. Documents default → handwritten TOML → GUI overrides, removal of redundant overrides, watched reload and migration warnings. | Make inherited/default values and resets understandable. MAGI can use one file rather than copying multiple layers. Test Default/reset and external-edit diagnostics. This says nothing about Noctalia v4 implementation or MAGI on Quickshell 0.3.1 compatibility. |
| [Dank Material Shell custom themes](https://danklinux.com/docs/dankmaterialshell/custom-themes) | Official docs labeled **1.6**. JSON semantic colors, dark/light definitions, Settings theme selection and reactive file edits. | Separate palette data from widgets; preview immediately and check light/dark contrast. Do not adopt Material layout, matugen or system-wide application theming. Required MAGI test: theme changes preserve live module instances and readable controls. |
| [Serpantinum README](https://github.com/ilyamiro/serpantinum/blob/master/README.md) | Moving **master**, exact current commit not resolved in this bounded read. Home Manager example gives ordered bar module groups and theme settings. Migration notice says prior v1 config is backed up and unused. | Ordered IDs are a useful configuration boundary. MAGI should preserve recognized old preferences instead of discarding them. This is documented intent/example, not evidence of its GUI save/validation behavior. Test MAGI v0 migration separately. |

The earlier [Serpantinum source report](serpantinum.md) is separately pinned to
`9f0e36bd9199c1d379701d052b884762b0de008b`, version 2.1.9. Do not attribute today's
moving-master README to that commit. Attempts to retrieve that pinned README
for this spike returned a fetch/cache error; no new claims about its contents.
Noctalia's modern configuration documentation is likewise not a substitute for
the still-deferred v4 source investigation.

Licensing boundary: no reference code/assets reused. DMS's
[repository](https://github.com/AvengeMedia/DankMaterialShell) identifies MIT;
Serpantinum's current README identifies AGPL-3.0-or-later. Noctalia code/license
was not audited here, so no reuse is proposed. Any later reuse needs an exact
version and applicable file license check, regardless of architectural inspiration.

## Palette provenance, without importing data yet

- [Catppuccin palette repository](https://github.com/catppuccin/palette): moving
  main page, inspected this date; exposes structured palette data and identifies
  MIT licensing. Proposed source for four flavours. Pin a release/commit and
  retain its license when adding data; this spike does not claim a specific
  bundled release or copy color tables.
- [Everforest](https://github.com/sainnhe/everforest): moving master README,
  inspected this date; documents dark/light and hard/medium/soft variants and
  links its palette; identifies MIT. MAGI role mappings remain proposed and
  need light/dark contrast checks. Pin data and attribution before bundling.
- Existing local `theme/palettes/CatppuccinMocha.qml` and
  `EverforestDarkHard.qml` supply current semantic colors. Their presence does
  not prove every future imported asset or font has the same license.

## Scope conclusion

These targeted references answer the foundation questions sufficiently to
propose implementation. No general external-project report is needed first.
Remaining uncertainty is mostly MAGI-specific persistence, view lifetime,
asset import and desktop-window behavior; use bounded local implementation tests.
