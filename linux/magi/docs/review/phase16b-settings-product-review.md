# Phase 16B: lock feedback, Settings toggle and product review

Review date: 2026-10-28. Accepted baseline: `b694da5c32cd34bddb368f11456a8b36bbd21315`.
Schema remains 22. Native fixes accepted by the operator; larger Settings product changes await review.
No broad Settings redesign is approved by this report.

## Corrected lock diagnosis

The operator clarified that password characters are entered correctly and login
works. The defect concerns the alternative **password mask styles**, not Shift,
AltGr or credential input. Investigation of `native/lock/qml/LockCredential.qml`
found that segments, line, ring and minimal deliberately represented only empty
versus nonempty input. The old auxiliary test required identical rendering for
one and 100 characters. Dots already provided bounded per-character feedback.

The candidate uses the same bounded count for every style: one mark per character,
up to 16, followed by the existing overflow indicator. Backspace removes a mark;
clearing input clears the marks. The component receives only the existing count,
never credential text. This exposes no more count information than the existing
dots style. Native input, credential storage, PAM, transport and lock authority
are unchanged. No keyboard layout is hard-coded.

A negative control with the new auxiliary assertions and old QML fails at the
one-versus-two-character image comparison. With the candidate, eight focused
native presentation/input-boundary checks pass, including 1/1.5/2 scale snapshots.
The new test also checks clearing, decrementing and bounded overflow for all five
styles. A separate synthetic GB-layout probe found no text-generation mismatch
in 216 printable base/Shift/AltGr/Shift+AltGr cases; this is diagnostic evidence,
not a claim of complete compose/input-method acceptance.

## Settings toggle

Super+S called `hub open settings`. The existing Hub already implements routed
toggle semantics. The candidate changes only this binding to `hub toggle settings`.
It creates no second host or visibility state. Existing same-output dismissal,
output routing and Escape behaviour remain authoritative.

The keybinding negative control fails against the previous binding. The affected
Hub suite passes with repeated close/reopen operations, retained page instance,
page selection and scroll position, and unchanged Settings data/revision. Native
Super+S/Escape acceptance remains pending.

## Review method and limits

Source inspection and a deterministic Settings fixture cover Kanagawa Wave and
One Light at 1000×720, 720×500 and 1280×900 logical sizes. The fixture captures
Appearance/theme, Bar Layout/Appearance, Control Centre, Transparency, Wallpaper,
Lock Screen and Profile, with compact/wide examples. It checks bounded page/body
widths and verifies navigation/preview modes do not persist preferences.

The 28 captures are temporary review evidence, not runtime dependencies. Wallpaper
uses an inert synthetic service; no real wallpaper or output is changed. Software
rendering does not reproduce all semantic SVG icons. Application enrollment status
in the isolated HOME does not describe the operator's live installation. Neither
limitation is counted as a production defect. Interaction counts below are source
walkthrough estimates from another Settings page, not timed usability measurements.

## Why Settings Still Feels Unfinished

These are ranked product recommendations, not permission to implement a redesign.
No new P0 or security defect was found in this Settings review.

| Rank / severity | Observation and evidence | Likely user perception | Proposed direction / cost and risk |
| --- | --- | --- | --- |
| 1 / P2 | Lock Screen stacks presets, preview-state/aspect controls, a canvas and an inspector. Its grid becomes two columns only at 790px of **body** width. At 1000×720 the content is about 1596px tall; at 720×500 the canvas only begins near the bottom of the first screen. | Selecting an element and finding its controls feel disconnected; the editor seems built around testing its preview. | Review a compact preset strip and a persistent selection/inspector relationship. Medium implementation cost; significant responsive-layout risk. Preserve the native security boundary. |
| 2 / P2 | Sixteen sidebar destinations share one flat list. Appearance, Transparency, Bar, Control Centre and Hub split related visual intentions; at compact height later destinations require sidebar scrolling. | The user must understand ownership before knowing where to start. | Review a few intent-based groups and stronger orientation, without duplicating controls or changing ownership. Medium cost; navigation/context migration needs review. Keep the elevated sidebar. |
| 3 / P2 | Appearance presents 26 palettes in one horizontally scrolling gallery, with roughly four cards visible at normal width. Current selection is revealed and keyboard navigation exists, but the complete choice set is not visible together. | A first-class theme library feels like a narrow carousel; comparison requires remembering off-screen choices. | Review a bounded expanded gallery/comparison mode. Medium cost; do not replace visual selection with a dropdown or invent filters without review. |
| 4 / P2 | Bar Appearance correctly distinguishes family styling from item identity, but the initial inspector offers Bar background and a literal semantic role such as `surface`. Changing pill styling requires first discovering the clickable family in the preview. | The screen exposes renderer concepts before explaining the intended edit. | Review clearer selection guidance and friendly role labels while retaining the full-width preview and exact family/item rule. Small-to-medium cost; role IDs and saved state must remain unchanged. |
| 5 / P2 | Most changes save immediately, while Weather location and Wallpaper source directories use explicit save actions; theme application has a separate activation status. Lock exposes synthetic state selectors alongside composition controls. | Some pages feel like operational/configuration tools with different completion rules. | Review contextual feedback that distinguishes saved preference, explicit draft and applied result; separate diagnostic preview choices from ordinary composition. Medium cost; preserve intentional save/activation boundaries. |

## Common journeys

Counts include selecting the sidebar destination and the decisive control, excluding
text entry and optional fine tuning. Scroll distances vary with current selection,
content, aspect ratio and window size.

| Workflow | Approximate interactions | Navigation / scroll / feedback |
| --- | --- | --- |
| Change theme | 2 plus gallery scrolling | Appearance → visual card; saved selection and application activation are distinct. Current card auto-reveals. |
| Change wallpaper | 2 once sources exist | Wallpaper → image; setup additionally requires opening source configuration and saving directories. Fixture grid is synthetic. |
| Modify Bar layout | 3+ | Bar → Layout → item/drag; full-width composition stays above controls. |
| Modify Bar appearance | 4+ | Bar → Appearance → family/region → control; discoverability of the selection-to-inspector link is the main concern. |
| Edit Control Centre | 3+ | Control Centre → visual family/item → inspector; vertical composition and shared-family semantics are intentional. |
| Change transparency/blur | 2–4 | Transparency → shared controls/disclosure; does not belong to whole-window opacity. |
| Configure lock | 3+ plus substantial scroll at normal/compact width | Lock Screen → preset/element → inspector; selection and controls separate when the grid stacks. |
| Edit profile | 2–3 | Profile → aligned field; compact identity composition, conditional message/weather and secondary avatar actions are good patterns to retain. |
| Inspect behaviour/options | 2+ | Destination → Behaviour/disclosure where present; mode names and ownership require familiarity. |

Normal-width measured content heights were Appearance 780px, Bar Layout 358px,
Transparency 680px, Wallpaper 945px, Lock Screen 1596px and Profile 430px against
720px page height. These are fixture measurements, not universal sizing targets.
Do not mechanically equalize densities or fill deliberate whitespace.

## Quick wins versus product changes

Implemented candidates are limited to password-mask feedback and the Super+S
binding, with regression coverage. No general Settings layout, sidebar, theme
picker, preview architecture or persistence behaviour has been changed.

The five recommendations above require operator review. Existing Phase 16 debt
(Bar focus handoff, truncated-label tooltips, palette contrast, reduced motion,
Brightness/QuickActions polling and Clipboard queue behaviour) is not reclassified
as newly discovered work here; see the Phase 16 audit and technical-debt register.

Keep visual choices visual, common intent before precision, background-only
transparency, system-owned application icons, full-width Bar preview, vertical
Control Centre composition, retained page/scroll context and compact Profile
identity. Lock credentials and authentication remain native authority.

## Native acceptance and review gate

On 2026-10-28 the operator confirmed the requested native interaction tests passed:
non-dot masks provide incremental feedback, Backspace and normal authentication
work; Super+S opens/closes/reopens Settings and Escape closes it. The guarded
post-integration check passed: exact installed package and candidate source files,
protected configuration, original effective Settings and byte-identical Settings
file; Hyprland reported no configuration errors.

The host native-lock suite passed a clean build, 21/21 CTest and 18/18 Rust checks.
The full offline regression and native environment reconciliation are detailed below.
No credential/PAM/input implementation was changed. Schema remains 22.

The two fixes are installed for native acceptance. The operator accepted the fixes and explicitly authorised committing and pushing
them before the next Settings product pass. The temporary worktree is retained
only until synchronized closeout. Broader Settings changes require
operator review; none has been implemented.

## Regression reconciliation

The first full run completed all 89 commands: 85 PASS, 1 FAIL, 3 ENVIRONMENT.
The sole failure was native_lock: the same audited socket-denial failures and an
independent SOCK_SEQPACKET EPERM, but its original whole-directory baseline check
rejected the intentional mask/test delta. The host run of that exact delta passes
all 39 native/Rust tests. The harness now accepts only the exact SHA256 hashes of
the two host-tested presentation files, with every other native file unchanged
from the audited baseline. Failure-set/signature and independent EPERM gates
remain intact; future edits do not inherit the exception. The focused rerun is
recorded separately from the original full-run evidence.

The release package build also succeeds, but its install audit cannot complete
`systemd-analyze --user verify` in this sandbox: SO_PASSCRED is denied with
Operation not permitted. The operator subsequently completed that validation on the host before installation,
as recorded below.

The focused rerun classifies native_lock as ENVIRONMENT with no unknown failures.
Combining the unchanged full-run results with that rerun gives **89 commands:
85 PASS, 0 FAIL, 4 ENVIRONMENT, 0 SKIPPED**. Native host evidence additionally
passes all 21 CTest and 18 Rust checks. The other limits are private-bus Bluetooth,
Notifications and Clipboard image decoding; none is represented as an offline pass.
The original full result and separately indexed reconciliation remain available in
the task log directory. `git diff --check` passes.

The operator also completed the release package check on the host: all five
artifacts pass mode, PAM policy, production-feature, ELF-hardening, unit and offline
CLI checks. The package was created successfully; no-debug-symbol indexing warnings
for the Rust worker were non-fatal. The audited package was installed and the
operator confirmed native UI acceptance. Review documentation was updated afterward;
no tested production source changed.

At the final review-gate check, the operator-local Settings file contained newer
avatar and lock-element offset edits relative to the earlier passing native check.
Those edits were preserved without normalization or staging. All other protected
entries still matched, allowing only the intended Super+S binding; installed
package hashes also matched. HEAD remained synchronized with origin/main and the
index was empty. Only the intended 12 Phase16B source/test/documentation paths
were dirty/untracked. The operator subsequently authorised commit/push of these accepted paths.
