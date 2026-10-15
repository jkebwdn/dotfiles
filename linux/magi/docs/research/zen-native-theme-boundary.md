# Zen native theme colour boundary

Investigated 2026-10-15, read-only browser investigation. This supplements, and
does not replace, [the authoritative coverage audit](theme-orchestrator-coverage.md).
The recommendations below are not implemented by this investigation.

## Outcome

Use a hybrid integration: Zen owns its native workspace theme; MAGI supplies only
semantic aliases needed by the existing custom CSS. Do not expand sidebar CSS
specificity. No supported narrow external update boundary for the native custom
base colour was found in the inspected installed source and public APIs.
For v1, recommend the explicit status **Native Zen base colour requires manual
selection**, with the current palette's base hex exposed to the operator.
Restarting after CSS generation alone must not imply the native base was applied.

## Evidence and scope

Installed build metadata: Zen **1.23b**, BuildID `20261002114451`, Gecko 157.0,
from `/opt/zen-browser-bin/application.ini`. Its SourceRepository is
<https://github.com/zen-browser/desktop> and SourceStamp is
`c6acdfeef8e60fe8856f2cb2007299c7241aab98`; that stamp was not independently
matched to an upstream desktop commit. Findings below describe the packaged
source, not a hypothetical newer upstream implementation.

Operator-confirmed profile: `/home/jkebwdn/.zen/0rzna1o3.Default (release)`.
The installation-specific registration in both profiles.ini and installs.ini
agrees. A different profile's generic Default flag must not override this.

Only relevant preference lines, registration metadata and userChrome.css were
inspected. The existence/size of `zen-sessions.jsonlz4` was checked; its contents
were **not read or decompressed**. No history, cookies, passwords, sessions,
bookmarks, workspace contents or other browser data were inspected or changed.
No browser restart or live before/after picker experiment was performed.
The current `#1e1e2e` picker value is operator-reported evidence; it was not
independently read back from running Zen or its persisted session container.

Public primary references, inspected 2026-10-15:

- [Zen about:config flags](https://docs.zen-browser.app/guides/about-config-flags):
  documents the accent preference and custom-colour picker availability flag.
  It does not document an external workspace-theme writer.
- [Mozilla browserSettings API](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/browserSettings):
  exposes a defined set of settings, not an arbitrary `zen.*` preference setter.
- [Mozilla theme.update API](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/theme/update):
  supports extension browser/window themes. It does not specify the Zen workspace
  gradient object traced below. Treating it as a native picker API is unsupported.

## Native picker save path

The following file paths are entries in
`/opt/zen-browser-bin/browser/omni.ja`, unless stated otherwise. Source was read
with `unzip -p`, without extracting files into the profile.

`modules/zen/ZenGradientGenerator.mjs` (SHA-256
`7194ddca9c3b1ef991681c77415f9b66308d1b7795dabff4a887153594832892`):

- `addCustomColor`, around lines 658–697, reads the custom input, optionally
  appends alpha, and stores it on a custom picker dot.
- `getTheme`, lines 1433–1439, constructs
  `{type: "gradient", gradientColors, opacity, texture}`.
- `workspaceBeingEdited`, lines 1903–1907, resolves the explicitly edited workspace,
  falling back to the active workspace. Editing need not target the active one.
- `updateCurrentWorkspace`, lines 1927–1978, constructs each colour entry with
  `c` (custom colour string or numeric colour array), `isCustom`, `algorithm`,
  `isPrimary`, `lightness`, `position` and `type`. It assigns the resulting object
  to `workspace.theme`. `handlePanelClose`, lines 1983–1991, saves changed state
  through `gZenWorkspaces.saveWorkspace`.
- `onWorkspaceChange`, around lines 1745–1803, applies native background and
  primary-colour variables and contrast attributes to the browser/toolbox.

`modules/zen/ZenSpaceManager.mjs`, `saveWorkspace` around lines 1355–1375,
updates the matching workspace cache entry. Propagation around lines 1431–1440
emits `ZenWorkspaceDataChanged` and synchronizes workspace data across windows
through `modules/zen/ZenWindowSync.sys.mjs` (around lines 1327–1330).

In the root archive `/opt/zen-browser-bin/omni.ja`,
`moz-src/browser/components/sessionstore/SessionStore.sys.mjs` handles that event
with delayed saving (around lines 1399–1400), and collects activeZenSpace and
spaces from the workspace manager (around lines 5678–5679).

`modules/zen/ZenSessionManager.sys.mjs` uses `zen-sessions.jsonlz4` (line 48),
compressed JSONFile storage (around line 107), and `saveState` (around lines
600–625). Its collected sidebar/session object includes spaces and groups
(around lines 790–791). This is shared session storage, not a dedicated colour
preference file. References to old Places `zen_workspaces` SQL tables in this
module belong to migration code and are not a recommended write route.

**Conclusion:** the picker base/gradient is **workspace-specific**, synchronized
across windows, and persisted with wider Zen session state. Changing it externally
would require touching a shared container and competing with in-memory state and
save/backup machinery. Even offline replacement is not a narrow owned integration.

## Accent preference and observed preferences

Filtered persisted preferences contain:

```text
toolkit.legacyUserProfileCustomizations.stylesheets = true
zen.theme.gradient.show-custom-colors = true
zen.themes.disable-all = false
```

No persisted override was found for `zen.theme.accent-color`,
`zen.theme.disable-lightweight` or `zen.theme.use-system-colors` in this snapshot.
Packaged `defaults/preferences/firefox.js` defaults those respectively to
`"AccentColor"`, `true` and `false`; the custom-colour availability flag defaults
to false. These are persisted/default observations, not live preference readback.
The availability flag does not store the selected custom colour.

`ZenGradientGenerator.mjs:getNativeAccentColor` (around lines 1834–1856) reads
`zen.theme.accent-color`: the default uses the system accent, while a hex value
is parsed as a colour. Dark-mode blending may transform the displayed result.
`getMostDominantColor` (around lines 1495–1501) falls back to that native accent
when a custom primary colour is a string. Thus a custom base and a distinct
profile-wide accent are compatible; setting accent alone does not set the base.

The native preference can be changed through Zen's own preference UI. No supported
live external arbitrary preference setter was established. Internal privileged
`Services.prefs`/workspace objects are implementation details, not an external
adapter contract. Extension theme.update does not establish such a contract;
privileged injection, experimental extensions or debugging bridges would add a
new invasive integration. A startup preference hook could at most address accent,
would need separate ownership/restart review, and would not solve workspace base.
Do not edit prefs.js while Zen runs or introduce user.js as an assumed solution.

## Recommended MAGI mapping and integration

Use resolved semantic roles, without theme-name conditionals:

| Native input | MAGI role | Catppuccin Mocha | Everforest Dark Hard |
| --- | --- | --- | --- |
| Custom native base colour | `roles.background` | `#1e1e2e` | `#272e33` |
| Native accent preference input | `roles.accent` | `#b4befe` | `#a7c080` |
| Existing menu surface alias | `roles.surface` | `#313244` | `#2e383c` |

The reported Catppuccin picker value matches background exactly, not surface.
Zen's opacity, texture, gradients and accent blending can affect displayed colour;
these controls should remain operator-owned.

Current userChrome.css contains a MAGI import of
`file:///home/jkebwdn/.local/share/magi/theme-orchestrator/zen/current/chrome.css`
inside the MAGI markers, followed by the operator's existing Catppuccin aliases
and small menu/popup customizations. No changes were made to either layer.

Recommended next implementation, subject to review:

1. Retain the existing reversible import, changed-hook protection and confirmed
   profile handling. Preserve all existing userChrome rules and Zen Mods.
2. Reduce generated CSS to the `ctp-*` semantic aliases the existing user rules
   consume. The present adapter also generates broad native variables and
   toolbox/sidebar/tab selectors; this investigation recommends removing those
   generated overrides rather than strengthening them. This has not been done yet.
3. Show native base manual-selection status and the palette background hex.
   Let the operator select the intended workspace in Zen and set its custom
   colour. Do not enumerate or recolour all workspaces implicitly.
4. Keep native accent operator-controlled for v1 unless a separate, supported
   narrow write boundary is established. Show the suggested semantic accent
   value without claiming it was applied.
5. Report CSS restart requirements separately from native manual selection.
   Disabling MAGI removes only its owned import/output under existing ownership
   rules; it must not reset operator-selected native colours.

## Validation limits and next acceptance

Static source tracing establishes the write path and field shape, not an observed
runtime differential. A controlled operator picker change and restoration could
confirm immediate visual behaviour without reading private session contents.
Native acceptance should check both palettes in the deliberately selected
workspace, unchanged other workspaces, menus, expanded sidebar and toolbox, and
CSS restart behaviour. No native success is claimed here.

No source code or assets were copied into the implementation; source inspection
only. This document and its index entry are the only changes made during this
investigation. Browser files, adapter code and generated output remain untouched;
no tests of unchanged application code were rerun, and no commit or push was made.
