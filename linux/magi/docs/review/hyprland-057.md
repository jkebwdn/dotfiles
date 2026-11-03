# Hyprland 0.57 theme adapter audit — 2026-11-03

Candidate based on `18b06f54c361983a95155b41840b4a42aa2ffd6a`.
Production HEAD and origin/main matched (0/0); working tree/index were empty.
Implementation is isolated in `/tmp/magi-hyprland-057-MjrhH5`. The operator ran
a temporary Python-only candidate deployment and native palette round trip;
production source was restored afterward. **Native acceptance passed; the operator approved closeout.** Settings schema remains 22.

## Proven diagnosis and limits

`adapters/desktop.py:Hyprland.activate` accepted any version output containing
`0.56.` and raised before `hyprctl eval` otherwise. The saved host activation
receipt has `publication.hyprland = published`, phase `activation_error`, and
that exact version-gate diagnostic. Its generic exception became `status=error`,
label `Apply failed`. The generated `current/colors.lua` exists and contains Nord.
The selected Settings theme is also `nord`. Generation/publication succeeded;
the rejected activation never attempted to load the file into the compositor.

Installed package: `hyprland 0.57.0-1`; installed header identifies release commit
`0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`. The session log under the matching
instance signature records the regular configuration path
`/home/jkebwdn/.config/hypr/hyprland.lua` and Lua ConfigManager initialization.
`~/.config/hypr` is a symlink to the tracked t15g Stow directory; the file itself
is regular source, not generated. The bootstrap is at lines 534–540, after base
border definitions and before optional hyprmon/application-background setup.
No later border assignment occurs in this entry point.

Both requested live queries (`hyprctl version`, `hyprctl systeminfo`) fail in the agent environment
with `Couldn't set socket timeout (2)`. Package/header/log evidence is not a
substitute for live queries. The operator supplied those live queries and ran the native acceptance below.
Native evidence is explicitly distinguished from agent-side parser/fixture checks.

The operator subsequently supplied native terminal output confirming release 0.57.0
at the expected commit, Arch Linux, and `configProvider: lua` / DRM. Actual borders:
active `ee89b4fa eeb4befe 45deg`, inactive `aa6c7086 0deg`. Both match MAGI's
Catppuccin Mocha palette, **not** the selected/generated Nord. The static source has
Mocha-like active colours but inactive `aa595959`, so runtime inactive also differs
from that static fallback. Previous MAGI application is consistent with the result;
the exact historical application event is not established.

This proves publication with gated activation (A) and stale compositor colours
rather than successful propagation of the current Nord selection. Reactive MAGI
surfaces/wallpaper can still change independently. There is no evidence that a
reload/observer or alternate route applied the new Nord border file (B/D). Native
acceptance restored selected Nord, intentionally correcting the stale Mocha
runtime rather than preserving it as the user's intended palette. The original
runtime values are retained for failure recovery.

## Existing architecture preserved

Palette registry → semantic palette resolution → `Hyprland.render` → Lua syntax
validation → all-target preflight barrier → generation/pointer publication →
per-target executor → activation receipt → Orchestrator status → AppearancePage.
`theme_activation/coordinator.py` still owns the publication barrier and target
isolation. No other adapter activation or publication policy was modified.

Only active and inactive borders are owned: blue/focus at alpha `ee`, angle 45;
inactive at alpha `aa`. No layout, gap, animation, shadow, monitor, input, window
rule or opacity writes. The generated Lua bytes are unchanged. Static bootstrap
reads XDG data `magi/theme-orchestrator/hyprland/current/colors.lua` only if it
exists. Missing runtime state leaves base source colours intact. Existing
bootstrap fixtures exercise absent/active/disabled states and source preservation.
An invalid existing payload is not silently swallowed; ownership/validation still
protect publication. No `.conf` output or Hyprlang path was added.

Legacy enrollment planning remains for non-Git user configs and historical tests;
`bootstrap.py`/coordinator guards refuse tracked Git/Stow mutation. That path already
renders Lua, and is outside this compatibility change. Generated payloads,
current/previous pointers and receipts remain in XDG stores, never tracked source.

## Upstream audit

Sources inspected 2026-11-03. These are interface observations, not copied code.
No upstream code/assets were incorporated.

| Source/version | Evidence and MAGI relevance |
| --- | --- |
| [0.57 release notes](https://github.com/hyprwm/Hyprland/releases/tag/v0.57.0) | Legacy provider removal does not require converting this already-Lua adapter. New reload APIs are not needed. |
| [0.56.2 HyprCtl.cpp](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/debug/HyprCtl.cpp), [0.57 Commands.cpp](https://github.com/hyprwm/Hyprland/blob/v0.57.0/src/ipc/s1/Commands.cpp) | `evalRequest`, `configErrorsRequest`, `dispatchGetOption` preserve Lua eval, error reporting and gradient introspection. IPC implementation moved; these command contracts remain. `eval` rejects non-Lua providers. |
| [0.57 Lua ConfigManager](https://github.com/hyprwm/Hyprland/blob/v0.57.0/src/config/lua/ConfigManager.cpp) | `eval` returns errors/warnings; successful IPC eval returns `ok`. `getConfigValue` normalizes colon names to Lua dots. An arbitrary zero-exit textual reply is not proof of application. |
| [0.57 SystemInfo](https://github.com/hyprwm/Hyprland/blob/v0.57.0/src/helpers/SystemInfo.cpp) | `getVersion` begins with the Hyprland release token; dependency versions and trailing tags must not drive compatibility. |
| Installed `/usr/include/hyprland/src/config/shared/complex/ComplexDataTypes.hpp`, release commit above | `CGradientValueData::toString` serializes hex colours and a degree angle. Readback compares canonical ARGB integers and angle, ignoring hex case/spacing. |

Operation classification: `hyprctl version`, `eval dofile(...)`, `configerrors`
and generated `hl.config` border structure are compatible in the audited release.
`-j getoption` is an existing compatible API newly used for verification.
Normal reload remains available but is not required by this mechanism; full-reset
is never used. `keyword`/legacy provider are removed and unused by this adapter.
`io.open`/`dofile` bootstrap remains valid Lua, with deterministic source order.
Installed `Hyprland --verify-config` accepted unmodified generated files for
Everforest Dark Hard, One Light and Nord (`config ok`, exit 0). Its isolated IPC
socket warning is not a live compositor acceptance result. A separate isolated
`hl.get_config` probe returned Nord colours `0xEE81A1C1` / `0xEE88C0D0` and
angle `45.00000125223908`; a strict Lua `== 45` exploratory assertion failed due
to floating-point conversion. IPC serializes this angle as integer degrees, which
is the canonical representation used by the candidate. This was not a live query.

## Candidate behavior

`hyprland_runtime.py` parses only an anchored release token (`Hyprland 0.57.0 …`,
`Hyprland v0.57.0 …`, or `v0.57.0`). Releases in major 0, minors 56–57, with numeric
patch versions are allowed; future minors, malformed text and prerelease suffixes
fail closed. Retaining the bounded range avoids replacing one single-minor gate
with another, without assuming unknown releases are safe.

Before mutation, both border options must be introspectable. Eval must reply
exactly `ok`, configerrors must be empty, and both values must match the published
payload. Success becomes `Live`; no automatic reload. This strengthens the old
command-accepted check. A live readback mismatch/config error remains a local
`Verification failed` error. Unsupported/malformed versions, missing hyprctl,
command failures and rejected eval receive `Generated · live unavailable`, with
separate machine-readable reasons and detailed diagnostics. This does not promise
that an unknown future compositor can load the file on reload. Generation and
publication failures retain their existing distinct statuses.

Existing activation receipts deliberately prevent automatic replay. After candidate
deployment, explicitly retry Hyprland once (or switch palette); merely opening
Settings does not overwrite a prior receipt or apply colours.

## Native acceptance — passed

The operator executed `/tmp/magi-hyprland-057-accept.py` in the desktop session.
It checked the exact baseline/clean source, recorded runtime values and Settings,
then temporarily installed only four candidate Python files. No QML restart,
Hyprland bootstrap edit, compositor reload, commit or push occurred. The normal
MAGI `settings theme` IPC drove the real reactive surfaces and Theme Orchestrator;
`systemTheme status` supplied the same target model displayed in Settings.

Sequence: explicit Hyprland retry for selected Nord → Everforest Dark Hard →
One Light → Nord. Each stage read both real compositor options and required exact
canonical agreement, an empty configerrors response, the matching publishedPalette,
and healthy `Live` status. The operator paused to inspect both distinct palettes
and answered yes to the final Follow MAGI/Live, focus/fullscreen, panels, lock
appearance and wallpaper regression checklist. The final Nord check passed again.

Evidence: `/tmp/magi-hyprland-057-native-fgn_bnxd/report.json` has five successful
readbacks, `visualAccepted=true`, `paletteRestored=true`, empty Git status and no
error/restore/conflict fields. Exact Settings bytes equal both the pre-test snapshot
and the earlier investigation hash; the Hyprland source hash is unchanged.
Production source was restored, HEAD remains the baseline and tracking divergence
is 0/0. The generated state and receipts legitimately reflect the restored Nord
activation; they were not reverted to the stale failure record.

The candidate is not permanently installed. A further palette switch before
integration can still encounter the old production version gate. The read-only
`tests/theme-orchestrator/hyprland-live.py --theme nord` remains available for
repeatable native verification; it is deliberately excluded from the offline runner.

Native observed values exactly matched these computed expectations:

| Palette | Active ARGB + angle | Inactive ARGB + angle |
| --- | --- | --- |
| Nord (selected/restored) | `ee81a1c1 ee88c0d0 45deg` | `aa4c566a 0deg` |
| Everforest Dark Hard | `ee7fbbb3 eea7c080 45deg` | `aa7a8478 0deg` |
| One Light | `ee4078f2 ee4078f2 45deg` | `aaa0a1a7 0deg` |

The original stale runtime was `ee89b4fa eeb4befe 45deg` / `aa6c7086 0deg`
(Catppuccin Mocha). All palette transitions above used the existing Lua `eval`
mechanism. The 0.56-only gate was the compatibility defect; no replacement API or
configuration rewrite was necessary. Parser/status/readback hardening prevents a
similar false publication failure or unverified success in future releases.

The operator approved the focused commit and closeout after full regression review.

## Regression

Targeted `theme-orchestrator/run`, `theme-orchestrator/bootstrap`, `phase12h/run`:
3 PASS / 0 FAIL. Covers 0.56, 0.57.0, patch parsing, future/malformed output, absent
hyprctl, command failures, refused eval, readback/probe failure, successful apply
and verification, generated-without-live status and cross-target isolation.
Full `python3 linux/magi/tests/run-all.py`: **94 PASS / 4 ENVIRONMENT / 0 FAIL /
0 UNKNOWN / 0 SKIPPED** across 98 suites. Logs:
`/tmp/magi-regression-0qb4jts4/results.json`. Environment classifications are the
existing independently evidenced private D-Bus restrictions (Bluetooth,
notifications and the two clipboard image cases) and audited native-lock socket /
private-bus restrictions. No environment exemptions were changed. `git diff --check`
passes. The four production Python files exactly match the natively tested copies.

Review inventory: four adapter/activation Python files, two test/checker files,
seven documentation files (13 paths total), all unstaged in the worktree; its index
is empty. Production tree/index are clean at the original baseline, origin/main
0/0. No schema files, bootstrap/config files, generated artifacts, operator Settings
or unrelated sources are part of the candidate. Proposed single commit:
`magi: support Hyprland 0.57 theme activation`.
