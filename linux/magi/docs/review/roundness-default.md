# Appearance roundness: the default MAGI UI shape

Approved methodology, 2026-11-11; accepted implementation from synchronized
`93ef0da`. Appearance keeps one authoritative editor for
`appearance.roundness.roles.surface`. Generic buttons, inputs, results, switches,
hover/focus surfaces, popup/menu controls and ValueSlider now follow it, alongside
the existing shared surfaces/cards. The description is “Default roundness for
MAGI controls and shared UI.” Reference pixel radii and half-size clamps remain.

The [complete binding/alias map](roundness-default-consumers.csv) records 47 sites
in 35 files. Theme.radiusSmall is surface-derived. Generic ValueSlider no longer
reads CC slider roundness; CC IconSlider still uses RenderTokens.sliderRadius.

The old action field remains parseable compatibility state, default null, with
unchanged historical migrations; it has no normal editor or production QML
consumer. Master remains hidden but continues to supply nullable fallbacks.
All twelve fields are retained; there are eight multiplier sliders and one
Launcher pixel stepper. No schema bump, migration, saved-value normalization or
change to the three shape selectors.

Feature overrides remain Bar barPill (Workspace null follows Bar), Hub hubSelector,
CC controlTile/secondaryControl/slider/albumArt/avatar and Launcher headerRadius.
Avatar/native-lock masks, media crops/borders, connected Bar joins and header
pixels keep their original ownership. Null feature overrides retain their master
fallback; they do not acquire new surface inheritance. Existing inheritance toggles
still name the base value and discard/reseed overrides as before.

The operator snapshot resolves surface to 1× and stored action to
1.2000000000000002. Generic 8px references therefore become 8px instead of 9.6px;
Hub search 10px instead of 12px; result cards 12px instead of 14.4px. No live Settings
are rewritten to make them equal. Saturated pill geometry may remain identical.
46 private Nord/One Light comparisons against production record ten intentional
generic differences and 36 identical images, with all feature comparisons identical.
Changing deprecated action values has no effect; Appearance min/current/max changes
generic controls while feature tokens remain invariant. Schema and native source
are unchanged. Native acceptance was operator-confirmed on 2026-11-11; the latest live
Appearance value is retained after operator adjustment during review.

The paired Control Centre pass 2 review changes inspector scrolling and preview
composition separately. Neither change authorizes another feature or Pass 3.
