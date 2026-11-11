# Control Centre Settings workflow — pass 1 accepted

Baseline: `87b21fd9525221c142e0c23364fcbc3e231718a3`, verified synchronized,
clean tree and empty index on 2026-11-11. The operator accepted the live workflow
and subsequent refinements, then authorized one focused commit. Acceptance is
operator-reported; no completed six-case native helper receipt is inferred. Push
requires separate approval. No second refinement pass is authorized.
Schema **22**, defaults, migrations and runtime preferences are unchanged.

## Page and ownership

`ControlCentrePage` is one retained `SettingsPage`. Layout/Appearance tabs and
the textual Sections list are removed. The preview is first/left; Reset composition
sits directly below it. The settings column is:

1. **Available controls**, expanded initially and collapsible, with its own semantic Settings card and a short
   add/remove/reorder description.
2. **Selected module/control**, only while selected, one card with subordinate
   disclosures. Profile, Primary Controls, Sliders, Secondary Controls and Media
   each retain their old appearance/spacing editors. Individual primary/secondary
   controls retain Accent. Primary-button selection shows only that button’s options;
   primary-group options belong to selecting the Primary Controls module.
3. **Global controls**, initially collapsed: surface background, expanded status-row
   foreground/shade/sample/reset, shared menu border role/width and CC border toggle inside a Border disclosure.
   Reset Control Centre appearance remains here with its existing scope.
4. **Roundness**, always showing its subgroup headings: Controls (primary, secondary, sliders),
   Artwork & identity (media artwork, avatar), Shared buttons & switches. The six
   existing multiplier fields, range 0–2, step .05 and nullable base inheritance
   are retained. Native-lock avatar masks and shared action ownership are unchanged.
5. **Decorative image**, the existing component/importer, last. PNG/GIF, height,
   overlap, vertical offset, flip and reveal duration are unchanged.

The [complete 75-row editor ownership table](controlcentre-settings-ownership.csv)
records labels, persisted paths, old/new cards, scope and consumers. Every former
Appearance editor is retained; only redundant workflow controls are replaced.
No shared field is copied into a parallel persistence model.

## Direct manipulation and geometry

The existing `SettingsReorderBoard` retains stable catalogue keys and pointer grabs.
`ControlCentrePreview` adapts its section board to real `SectionLayout.geometry`
bounds instead of a text list. Section handles occupy the leading gutter; simple
module clicks select, individual control clicks retain item customization, and a
threshold-crossing drag arranges composition. Empty panel/background space clears
selection. Selection and disclosure are view-local and never save Settings.

`Settings.placeCCSection` remains the sole section placement writer for
`controlCentre.layout`. `Settings.placeCCModule` remains the atomic control placement
writer, preserving supported presentations, single-instance identity and section
routing. Profile/Sliders/Media retain their existing optional-section semantics;
Primary/Secondary required sections cannot be removed. There is no new arbitrary
position, count, ordering array or runtime editing mode.

The Available card is the shared control/optional-section removal destination;
there is no separate trash target or “Drag here to remove” area. Its rows map into
reserved card content using the same boards, avoiding duplicate delegates/grab
handoffs. Invalid destinations retain valid Settings and expose quiet feedback.
Valid removal highlights the card; reordering uses a narrow insertion marker.
An empty runtime group gets an editor-only insertion strip during a compatible
control drag, entirely inside the panel. Targets never extend over unrelated cards.
Suspend remains optional and is never invoked by these tests or review fixtures.

Keyboard conventions remain Tab, Enter/Space selection, Alt+Up/Down movement,
Alt+Home/End endpoints, Alt+Left/Right region movement and Escape drag cancellation.
Reset composition stays a separate explicit action. Mouse dragging is not required.

Preview layout still uses production `SectionLayout.geometry`, runtime presenters,
module spans, measured profile/media heights and actual output limits. Decoration
is included in the editor view, using the existing overlay component with animation
suppressed only in the static preview. At narrow widths the card column stacks below
the full-aspect preview; at body widths >=680 it sits alongside. No 380px approximate
layout or extra wrapping algorithm is introduced. The unified page scrolls vertically.

Catalogue loaders explicitly receive row size so initial zero-height Loader layout
cannot paint icons/labels over the description. Mapped palette bounds react to layout
and scaling, without a polling timer. Negative mapped coordinates caused by the
left decoration allowance remain valid during dragging. Shared board defaults preserve
Bar/Hub behavior; affected suites cover those callers.

## Evidence and review gate

Durable evidence:
`~/.local/state/magi/audits/controlcentre-settings-er4wj2qn/`.
Candidate source: `/tmp/magi-controlcentre-settings-saol9lis`.

- `settings/controlcentre-workflow`: real private Settings UI; passive byte/revision
  preservation, all section selection/reorder, keyboard movement, required-section
  rejection, supported/unsupported drops, Suspend add/remove, Media remove/re-add,
  save/reload and six owned roundness roles. Nord/One Light at 720/1000/1400.
- Existing `settings/refinement` retains exact live/preview geometry comparisons
  for empty/two/four/six controls, media, decoration and output widths.
- `runtime-equivalence/result.json`: **423 runtime/schema/native files unchanged**;
  **28 before/after render pairs pixel-identical**, using the operator's saved
  roundness values. Editor selection/handles are intentionally not runtime artwork.
- `captures-final/`: responsive none/profile/primary/Wi-Fi/media selections, global,
  roundness, decoration and drag states. Private review additionally loads copied
  operator assets. Offscreen captures are not native Wayland acceptance; the
  software renderer omits MultiEffect-tinted SVG/artwork pixels (the existing
  [renderer limitation](../quickshell-reference.md)). Geometry assertions remain
  valid; native icon/mask appearance must be checked by the operator.
- `review-guards-result.json`: private fake-repository deployment/rollback,
  concurrent Settings preservation, foreign source and corrupt-backup rejection,
  and interrupted-deployment recovery. No live deployment occurred in these tests.
- Full regression and final protected-state results are recorded in the audit receipt;
  final totals must be read there, not inferred from intermediate progress logs.
- The old Tray designer fixture also failed against unchanged `87b21fd`: its
  hardcoded y+50 drop lay outside the accepted compact 40px Available row.
  It now derives the destination from real geometry and verifies the target before
  release. Both baseline/candidate diagnostic logs are retained.

The initial protected-state comparison found only a concurrent
`controlCentre.actions` change: Suspend enabled and Hibernate disabled. No live
source deployment or Settings write was performed by this phase. The current file
was retained and the operator confirmed this deliberate adjustment; all other 700
protected entries match. Native deployment takes a fresh invocation-time snapshot, never an obsolete
phase-start requirement. This difference must not be reported as byte-identical
phase-start Settings.

`native-review.py` snapshots current Settings/protected state at invocation, checks
baseline/source/test hashes, deploys only the seven reviewed editor source paths,
and provides guarded source-only rollback. Private windows use copied Settings/assets,
disable power actions and application activation, and support Ctrl+R reload and
Ctrl+Shift+R original-value restoration. Six width/palette cases precede a passive
live geometry/selection check. Live history is never rewound from an old snapshot.
No service restart, compositor edit or actual Suspend is part of the helper.

The helper's six-case offscreen self-test uses the current operator Settings and
copied assets; `self-test-ob0nusgq/result.json` records unchanged Settings and all
701 protected entries during that review. `gallery.html` combines those six cases
with 64 interaction captures. Subsequent live acceptance was confirmed by the
operator after the refinements below.

Run the current guarded host review in a normal Hyprland terminal:

```sh
python3 /home/jkebwdn/.local/state/magi/audits/controlcentre-settings-er4wj2qn/native-review.py
```

Use the same command with `--rollback` to restore baseline source while preserving
whatever Settings are current at rollback time. Do not run this historical helper
once the baseline changes.

The operator accepted the live refinements and authorized this exact-path commit:
`magi: simplify control centre settings workflow`.

## Final automated gate

The final full canonical matrix (`full-verified/summary.json`) completed with
**111 PASS, 4 ENVIRONMENT, 0 FAIL, 0 UNKNOWN**. The four established environment
limits are Bluetooth private D-Bus, clipboard PNG transport/private D-Bus,
notifications private D-Bus and native-lock SOCK_SEQPACKET/private-bus restrictions.
No new skip or broad warning exemption was added. The preceding full run's one
Tray fixture failure is preserved, independently reproduced on baseline, corrected
and passed in this complete final rerun. `git diff --check` and allocated-file
whitespace checks pass. Schema22, defaults and migrations remain byte-identical.

At the initial automated review gate, production was synchronized/clean at
`87b21fd`, index empty. The candidate
worktree contains only the allocation below, with empty index. Live Settings stay
ignored/untracked. The operator-confirmed Suspend/Hibernate adjustment is preserved;
all other 700 phase-start protected entries match, and the six-case private review
preserved its fresh invocation snapshot of all 701 entries. This historical gate
preceded live deployment and the acceptance recorded below. No Settings values
were written by deployment or source refresh.

## Native review refinements — 2026-11-11

The operator accepted the initial direction and requested these follow-ups:

- Selecting the Primary Controls module shows its family options. Selecting an
  individual primary tile shows only that tile’s Accent editor, without a second
  Primary Controls disclosure. Secondary and slider scope behavior is unchanged.
- Available controls can collapse. Both control and optional-module delegates
  become invisible/non-interactive with it. Dragging a placed item over the
  collapsed card opens it as the removal destination, without an extra Settings write.
- Global controls → Border is a disclosure.
- The outer Roundness card stays open. Controls, Artwork & identity and Shared
  buttons & switches headings always remain visible; each heading expands its own options.

Seven affected suites pass after these changes (`refinements-1` and
`refinements-visuals-1`), plus the refreshed 66-capture workflow fixture. The earlier
complete 111 PASS / 4 ENVIRONMENT matrix predates these presentation follow-ups;
no second full run is claimed. Guarded source refresh and interrupted-refresh
rollback passed private tests. The live review is refreshed using invocation-time
Settings/protected-state checks; `native-refresh-*/result.json` records the result.
The guarded live refresh preserved current Settings exactly with no unexpected
protected-state changes (`native-refresh-1xzh7goa/result.json`). The operator then
accepted the refinements and authorized the focused commit. Settings semantics
remain unchanged; pushing still requires separate approval.

## Approved exact commit allocation

One focused commit, authorized after native review. No live Settings, generated
state, assets or audit output is included.

### Editor source

- `linux/magi/.config/quickshell/magi/components/settings/CCAvailableControls.qml`
- `linux/magi/.config/quickshell/magi/components/settings/CCGlobalSettings.qml`
- `linux/magi/.config/quickshell/magi/components/settings/CCInspector.qml`
- `linux/magi/.config/quickshell/magi/components/settings/ControlCentrePreview.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsReorderBoard.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/qmldir`

### Tests

- `linux/magi/tests/appearance/roundness-equivalence.py`
- `linux/magi/tests/appearance/roundness.qml`
- `linux/magi/tests/phase12a/presentation.qml`
- `linux/magi/tests/phase12d/presentation.qml`
- `linux/magi/tests/phase12f/presentation.qml`
- `linux/magi/tests/phase14a/designer.qml`
- `linux/magi/tests/run-all.py`
- `linux/magi/tests/runtime-visual/appearance.qml`
- `linux/magi/tests/runtime-visual/controlcentre-image.qml`
- `linux/magi/tests/runtime-visual/feedback.qml`
- `linux/magi/tests/settings/cards.qml`
- `linux/magi/tests/settings/controlcentre-workflow.py`
- `linux/magi/tests/settings/controlcentre-workflow.qml`
- `linux/magi/tests/settings/native-controlcentre-workflow.qml`
- `linux/magi/tests/settings/presentation.qml`

### Documentation

- `linux/magi/docs/README.md`
- `linux/magi/docs/architecture.md`
- `linux/magi/docs/architecture/current-system.md`
- `linux/magi/docs/current-roadmap.md`
- `linux/magi/docs/decisions.md`
- `linux/magi/docs/review/controlcentre-settings-ownership.csv`
- `linux/magi/docs/review/controlcentre-settings-workflow.md`
- `linux/magi/docs/technical-debt.md`
- `linux/magi/docs/testing.md`
