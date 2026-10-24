# Phase 12G — Application Background Transparency + Shared MAGI Transparency + Blur

## Final native acceptance — 2026-10-24

The operator explicitly accepted the complete implemented feature set and authorized
final regression, precise staging, commit and push. The following results are
operator-observed native acceptance, not inferred from synthetic tests.

- Ghostty 1.3.1: the four-state matrix passed. At 100% the background is opaque
  with blur either on or off; at reduced alpha, OFF reveals sharp detail and ON
  reveals blurred detail. Text, prompt/icons, cursor and deliberate coloured cells
  remain opaque/readable. Running terminals reload safely using Ctrl+Shift+,.
- Theme changes preserve opacity/blur; opacity edits preserve semantic colours.
  Theme Orchestrator alone publishes the composed Ghostty output. Disable removes
  the generated override and restores the operator's `background-opacity = 0.95`
  after reload. Reset restores defaults without resetting the theme.
- Bar, Hub/Settings, Control Centre, Calendar, Launcher through Hub, Notifications
  and applicable panel surfaces passed shared background transparency/blur checks.
  Foreground content stays opaque. OFF restores individual surface styles without
  altering their saved values; re-enable resumes shared appearance.
- Global blur amount 1–40 applies after debounce. OFF/reset restores the captured
  baseline 8. Passes are not written. This is explicitly compositor-wide strength,
  separate from the shared participation toggle.
- Final saved operator preferences: Catppuccin Frappé, background opacity 50%, shared
  management ON, blur ON, global customization ON at 12. Ownership state records
  baseline 8 and applied 12. These local preferences are preserved and unstaged.

Settings ownership: **Transparency** sidebar, **Transparency & blur** page. Shared
background opacity range is 50–100%. Global blur amount is a separate disclosure
on the same page. Wallpaper and lock-screen presentation remain separate; a global
compositor strength setting inherently affects any already-participating surface.

Last authoritative native invariants: active/inactive/fullscreen opacity 1.0/1.0/1.0,
passes 4, global size baseline 8 (managed amount currently recorded as 12). The
finalization sandbox cannot access live Hyprland IPC (`Couldn't set socket timeout`);
no fresh authoritative readback is claimed. No production whole-client opacity path
exists and no configuration mutation was used to obtain finalization evidence.

GTK 4.24.1 compatibility: its compositor blur-region calculation ignores requests
below the internal 20px threshold. The initial 1px CSS parsed but emitted no usable
region. `window.window { backdrop-filter: blur(20px); }` produces the accepted blur
request; Hyprland controls actual strength. The fixed exact-class Ghostty no-blur
rule only toggles enabled state; no effect mutation, broad matcher or Layer Rule.

Schema 19 contains only applicationAppearance `{managed, backgroundOpacity,
blurEnabled}` and separately opted-in appearance.globalBlur `{managed, size}`.
18→19 defaults are neutral and idempotent. No rejected active/inactive/fullscreen
opacity fields remain. Baselines and journals live outside Git and Settings.

### Permanent ownership rules

Application transparency uses native background-alpha adapters, never compositor
whole-window opacity. Foreground content stays opaque. One writer composes theme
and appearance for each generated file. Shared MAGI styling changes outer paint
only and preserves individual styles underneath. Global strength is labelled global;
participation and strength remain independent. Transaction failure restores previous
published/runtime state; disable restores actual operator defaults, not a neutral preset.

### Support and Phase 12H ledger

Ghostty is supported and natively accepted; manual safe reload is still required.
Zen Linux chrome capability is verified but MAGI activation remains partial/deferred.
GTK/Thunar transparency is deferred; no universal transparent CSS ships. Neovim
Normal/NormalNC inherit terminal defaults; floats retain intentional backgrounds.
Yazi/yatline partially inherit with deliberate cells retained. btop inherits where
`theme_background=false` permits. Starship/Fastfetch inherit their terminal host.
These TUI capability descriptions do not promise every view is transparent.

Phase 12H remains unimplemented: generalized Theme Activation Coordinator, safe
Ghostty automatic reload, Zen activation, GTK/Thunar investigation, Yazi/Neovim
activation status, btop semantic polish and live/next-launch/restart-required status.
True fresh login and destructive compositor-loss tests remain deferred; synthetic
restart/config-generation/crash-recovery tests cover those contracts. No dedicated
full-compositor reload was performed during finalization.

## Final regression and inventory

Final run: 18 of 19 suite commands passed. The private-D-Bus Notifications
integration command exits 127 before loading MAGI because sandbox socket binding
is prohibited; the unchanged accepted-baseline runner fails identically. Separate
Notifications policy and presentation tests pass. No tests were weakened.

Passed: 26 Phase12G policy/adapter/transaction tests (including the multi-theme,
multi-opacity, managed/blur state rendering matrix), 11 global-blur transaction
tests, copied operator schema-18 migration/idempotence, Settings persistence,
presentation/navigation and appearance, 12C–12F, Bar/Calendar, Hub, Notifications
presentation/policy, 15 Theme Orchestrator tests, runtime visuals and shared-surface
lifecycle. Expected offscreen/IPC warnings remain harness-classified environment
messages. GTK emits an existing load_from_data deprecation warning, not a CSS error.

Final inventory: **85 paths — 48 added, 37 modified, 0 deleted**.
The Hyprland path includes only the approved bootstrap hunk. settings.json,
operator configs, runtime state and temporary logs are excluded.

| Category | Paths |
|---|---:|
| Shared shell surfaces / wiring | 14 |
| Settings UI / synthetic preview | 5 |
| Application appearance coordinator / policy / executor | 6 |
| Global blur service | 2 |
| Ghostty adapter / sole publisher | 3 |
| Schema / Settings persistence | 4 |
| Documentation / retained audit history | 5 |
| Current preview gallery | 15 |
| Historical rejected preview evidence | 13 |
| Tests / fixtures | 17 |
| Approved Hyprland bootstrap only | 1 |

<details><summary>Exact accepted path inventory (A/M)</summary>

```text
M linux/magi/.config/quickshell/magi/components/bar/Bar.qml
A linux/magi/.config/quickshell/magi/components/bar/PaintedBlurRegion.qml
M linux/magi/.config/quickshell/magi/components/bar/SharedStatusSurface.qml
M linux/magi/.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml
M linux/magi/.config/quickshell/magi/components/bar/menu/CombinedMenuHost.qml
M linux/magi/.config/quickshell/magi/components/hub/HubSelector.qml
M linux/magi/.config/quickshell/magi/components/hub/HubSurface.qml
M linux/magi/.config/quickshell/magi/components/hub/HubWindow.qml
M linux/magi/.config/quickshell/magi/components/notifications/NotificationCard.qml
M linux/magi/.config/quickshell/magi/components/notifications/ToastHost.qml
A linux/magi/.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml
M linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml
A linux/magi/.config/quickshell/magi/components/settings/pages/ApplicationsPage.qml
M linux/magi/.config/quickshell/magi/components/settings/qmldir
M linux/magi/.config/quickshell/magi/plugins/bar/workspaces/Workspaces.qml
A linux/magi/.config/quickshell/magi/services/ApplicationAppearanceService.qml
A linux/magi/.config/quickshell/magi/services/GlobalBlurService.qml
A linux/magi/.config/quickshell/magi/services/application_appearance/coordinator.py
A linux/magi/.config/quickshell/magi/services/application_appearance/executor.py
A linux/magi/.config/quickshell/magi/services/application_appearance/planner.py
A linux/magi/.config/quickshell/magi/services/application_appearance/policy.py
A linux/magi/.config/quickshell/magi/services/application_appearance/registry.py
A linux/magi/.config/quickshell/magi/services/global_blur.py
M linux/magi/.config/quickshell/magi/services/qmldir
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/adapters/desktop.py
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/coordinator.py
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/storage.py
M linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
M linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
M linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
M linux/magi/.config/quickshell/magi/settings/persist.py
M linux/magi/.config/quickshell/magi/shell.qml
M linux/magi/.config/quickshell/magi/theme/Theme.qml
M linux/magi/docs/README.md
M linux/magi/docs/architecture.md
M linux/magi/docs/decisions.md
A linux/magi/docs/design/phase12g-window-visuals.md
A linux/magi/docs/design/previews/phase12g/background/01-default.png
A linux/magi/docs/design/previews/phase12g/background/02-opaque.png
A linux/magi/docs/design/previews/phase12g/background/03-translucent-sharp.png
A linux/magi/docs/design/previews/phase12g/background/04-translucent-blurred.png
A linux/magi/docs/design/previews/phase12g/background/05-opaque-blur-on.png
A linux/magi/docs/design/previews/phase12g/background/06-opaque-blur-off.png
A linux/magi/docs/design/previews/phase12g/background/07-support-detail.png
A linux/magi/docs/design/previews/phase12g/background/08-compact-dawn.png
A linux/magi/docs/design/previews/phase12g/background/09-error-detail.png
A linux/magi/docs/design/previews/phase12g/background/theme-catppuccin-mocha.png
A linux/magi/docs/design/previews/phase12g/background/theme-everforest-dark-hard.png
A linux/magi/docs/design/previews/phase12g/background/theme-nord.png
A linux/magi/docs/design/previews/phase12g/background/theme-rose-pine-dawn.png
A linux/magi/docs/design/previews/phase12g/background/theme-rose-pine.png
A linux/magi/docs/design/previews/phase12g/background/theme-tokyo-night-moon.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/01-management-off.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/02-on-100-100.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/03-differentiated.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/04-strong-difference-blur-allowed.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/05-blur-excluded.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/06-compact-light.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/07-error-detail.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-catppuccin-mocha.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-everforest-dark-hard.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-nord.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-rose-pine-dawn.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-rose-pine.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-tokyo-night-moon.png
M linux/magi/docs/quickshell-reference.md
M linux/magi/tests/calendar/bar.qml
M linux/magi/tests/phase12c/schema.cjs
M linux/magi/tests/phase12d/schema.cjs
M linux/magi/tests/phase12e/ownership.cjs
M linux/magi/tests/phase12f/presentation.qml
A linux/magi/tests/phase12g/bootstrap.lua
A linux/magi/tests/phase12g/global_blur.py
A linux/magi/tests/phase12g/lifecycle.py
A linux/magi/tests/phase12g/lifecycle.qml
A linux/magi/tests/phase12g/presentation.py
A linux/magi/tests/phase12g/presentation.qml
A linux/magi/tests/phase12g/run.py
A linux/magi/tests/phase12g/schema.cjs
M linux/magi/tests/settings/expected18.cjs
M linux/magi/tests/settings/run.py
M linux/magi/tests/settings/schema.cjs
M linux/magi/tests/settings/store.qml
M linux/t15g/hypr/.config/hypr/hyprland.lua
```

</details>

All following checkpoints are retained historical evidence. Their previous pending
acceptance labels, inventories and rejected ownership models are superseded above.

---

## Phase 12G shared shell appearance — operator-approved scope extension (2026-10-24)

The operator confirmed theme switching preserves Ghostty opacity and blur, then
requested the same controls for Quickshell menus and explicitly included the Bar.
This supersedes the earlier application-only shell exclusion for painted MAGI
panel backgrounds. Wallpaper and lock-screen styling remain separate.

**Transparency & blur** is now the shared Settings page. The existing neutral
schema-19 applicationAppearance policy drives background alpha (50–100%) and blur
participation for supported applications and MAGI panels. Its persisted name is
retained; no extra copy of the desired policy is introduced. The separately opted-in
global blur amount is colocated on this page and retains baseline restoration.
Theme Orchestrator remains the sole Ghostty writer. Application planners still
emit no client-opacity changes, shell rules, effect mutations or whole reloads.

Theme.surfaceBackground applies alpha only at outer paint sites: Bar host and
pills, Hub frame/selector (including Settings/Launcher), expanded menus, Calendar
and toast cards. Palette, text, icons, artwork and inner control/card colours are
unchanged. Local Bar/style settings are preserved and restored when shared
management is disabled. Nested opaque controls intentionally remain readable.

Quickshell 0.3.2 BackgroundEffect.blurRegion sends native background-effect regions
for painted shapes. Bar regions track actual items and rounded geometry, never the
full-screen dismissal/input catcher. Hub and toast regions similarly exclude empty
screen space. No new Hyprland bootstrap or Layer Rules are required. An empty region
when disabled stops MAGI-requested blur; the native protocol object remains attached
until the Wayland surface is destroyed. Thus this is ownership of MAGI's own blur
regions, not a promise to defer to hypothetical manual layer blur rules. No such
operator layer blur rule was found in the audited configuration.

API evidence: installed Quickshell 0.3.2 qmltypes and
https://github.com/quickshell-mirror/quickshell/blob/v0.3.2/src/wayland/background_effect/qml.cpp
(BackgroundEffect::updateBlurRegion / surface lifetime), inspected 2026-10-24.
Native compositor rendering remains an operator acceptance gate.

Offline checks: Phase12G presentation verifies background-only alpha, unchanged
foreground image pixels, independent blur, unchanged palette tokens and restoration.
Calendar/Bar runs its production open/close/CC handoff and animation checks with
shared management enabled. 12C–12F, runtime visuals, 24 application tests, 11 global
blur tests and 15 Theme Orchestrator tests passed. Native shell review is pending. Live integration loaded cleanly in the existing shell
(10:09:51 and 10:10:30); no new QML errors. The 15-source-path integration
left all protected files byte-identical. Backup: `/tmp/magi-12g-shared-native-e0ympz0c`.
Sidebar label: **Transparency**; page title: **Transparency & blur**.

## Finalization checkpoint — native acceptance recorded, theme check pending

The operator accepted the Ghostty four-state matrix (opaque 100% with blur on/off;
reduced alpha with sharp/blurred backdrop), foreground staying opaque, management
disable restoring the operator 95% background after reload, and Reset preserving
the theme. Global blur amount adjustment and OFF restoration to captured size 8
were separately accepted. The global size control is an explicit approved scope
extension; applications still never write compositor whole-client opacity.

Theme-switch/native opacity-composition acceptance remains pending: the operator
reported it had not yet been tested. No staging/commit occurs before this last check.
Terminal-app capability observations are source/config audits, not completed native
TUI acceptance. No logout/login or deliberate compositor-loss test was performed.
Fake-executor restart/reload/failure tests are evidence, not claims of native tests.
The independent global service has synthetic lifecycle coverage; an operator-triggered
full compositor reload has not been performed as a dedicated final lifecycle test.

Final regression: 24 application-policy/transaction tests, 11 global-blur tests,
schema/migration, QML lifecycle, Phase12G presentation, Settings persistence and full
presentation/navigation, phases12C/12D/12E/12F, 15 Theme Orchestrator tests, runtime
visuals and diff whitespace check pass. Expected offscreen IPC/DBus/window-mask
warnings are filtered by existing harnesses. Two test expectations needed correction:
neutral globalBlur added to the migration fixture; presentation preservation compares
objects semantically rather than JSON key ordering. Both reruns pass.

Inventory prepared: 72 paths, 47 added / 25 modified / 0 deleted, including only the
approved fixed Ghostty bootstrap hunk in hyprland.lua. settings.json and all other
protected operator files are excluded. The separate existing theme include and
hyprmon include remain operator-local and are not part of the prepared bootstrap
patch. Current main and isolated source agree; the index remains empty.

## Phase 12G approved extension — global blur amount

After native Ghostty blur was visually confirmed working, the operator explicitly
approved a separate global control. **Appearance → Advanced shell styling → Global
blur** now offers opt-in amount (size 1–40). The UI clearly states that this affects
all blurred desktop surfaces. Passes, blur enablement, client opacity, fullscreen
and per-surface participation are untouched. Applications remains the separate
background-alpha/participation owner. Earlier prohibitions on global blur writes
below describe the application-only scope; this separate opt-in control supersedes
those prohibitions for blur size only.

The independent GlobalBlurService debounces edits, validates policy, uses the audited
Lua runtime `hl.config({decoration={blur={size=N}}})` API and verifies with
`hl.get_config("decoration.blur.size")`. No config reload or protected Lua edit.
`appearance.globalBlur={managed:false,size:8}` remains neutral in schema 19; old
candidate-19 files receive effective defaults without a forced save. One schema bump
from 18 remains sufficient because Phase12G is not committed.

Runtime ownership lives at `$XDG_STATE_HOME/magi/global-blur/ownership.json`, under
an exclusive lock. A durable pre-write journal captures exact operator baseline and
runtime snapshot. Disable/reset restores that baseline. Same instance/generation
reuses it; new compositor/config generation captures fresh configured size. The
existing approved bootstrap supplies read-only generation identity. Duplicate events
are idempotent. Apply/readback failure restores prior state; rollback failure retains
the journal and reports an error. No polling, no whole-config reload.

The previously audited pinned renderer effectively bounds size to 1–40; the config
API allows 0–100. User controls use the effective range; baseline restoration accepts
the full config range so existing operator values are restored exactly. Current
operator baseline is 8. Native global-control enable/change/restore acceptance is
pending; default management is off. Ghostty background blur itself is now visually
confirmed working after the GTK 20px request-threshold correction.

## Native protocol follow-up — 24 October 2026, 09:24

The diagnostic Ghostty log proved the custom stylesheet loaded without CSS errors
and GTK created ext_background_effect_surface_v1, but no set_blur_region request
was sent. Fresh-window native acceptance therefore failed too. The initial 1px
request was insufficient: GTK 4.24.1 `gskblurutils.c` defines
BACKGROUND_BLUR_THRESHOLD=20.0 and only classifies a blur node at or above that
radius as background blur. The adapter now requests 20px, with a regression
assertion against falling below that threshold. This still does not set Hyprland's
blur strength: the protocol conveys a region only. Native verification remains pending.
Source inspected 2026-10-24:
https://github.com/GNOME/gtk/blob/4.24.1/gsk/gskblurutils.c
(`compute_blur_node_blur` and BACKGROUND_BLUR_THRESHOLD).

# Phase 12G — Application Background Transparency + Blur

2026-10-24. **Corrected architecture candidate, isolated review only.** Not natively
accepted, not integrated, not staged, not committed or pushed. Phase 12H is not begun.
The accepted committed baseline remains `abeba3be79c22113e1d165c3da1bb2296cbe9495`
(`magi: refine settings product design`), divergence `0 0`.

## Live rollback — completed before correction work

The operator reported that the client-opacity test faded foreground content as well
as backgrounds. The saved ownership baseline was active 1.0 / inactive 1.0; the last
managed values were approximately .78 / .80. The existing release transaction ran
through Settings. Operator-provided authoritative `hyprctl repl` readback confirmed:

| Value | Restored / preserved |
| --- | --- |
| active client opacity | 1.0 |
| inactive client opacity | 1.0 |
| fullscreen opacity | 1.0, untouched |
| global blur size / passes | 8 / 4, untouched |
| old MAGI all-client no-blur rule | false |
| service status / ownership | released / null |

The operator explicitly confirmed **baseline appearance restored**. Live desired
management is false. This correction pass does not edit live settings, application
configs, generated themes, or hyprland.lua. The old static rule remains disabled.
The live checkout still contains the prior integrated candidate, with management
off; the corrected Applications page exists only in the isolated worktree.
Evidence and a fresh snapshot of main checkout state are in
`/tmp/magi-12g-background-1ikwfrpb/`. The earlier schema-18 operator snapshot remains
the migration fixture; the live file is now an uncommitted experimental schema 19.

## Product correction and rejected mechanisms

The feature is native **application background alpha**, with opaque foreground,
plus compositor blur behind transparent pixels. Unsupported applications remain
unchanged. No whole-client fallback is permitted.

1. Mutable named opacity rules: rejected because effects append instead of replace.
2. Generated fragment with MAGI-triggered whole reload: rejected because unrelated
   operator configuration is re-evaluated.
3. Runtime global client opacity: technically reversible, but **rejected for this
   product** because it multiplies the entire client surface, including foreground.

All earlier audit and native-error evidence is retained below, explicitly historical.
Rejected production option writers, their backend, and their service were removed
from this worktree. No corrected application planner writes client opacity.

## Installed capability matrix

Audit date: 2026-10-24. Versions are from installed pacman records. Local configs,
generated adapters and installed documentation were read only. “Supported” below
means a verified mechanism; it does not substitute for native four-state acceptance.

| Target / version | Current adapter and background capability | Blur / activation / limits |
| --- | --- | --- |
| Ghostty 1.3.1-2 | `desktop.Ghostty`; native background-opacity, default-background only with background-opacity-cells=false. Implemented reference candidate. | Hyprland blur behind transparent pixels; narrow exclusion proposed. Reload required, no restart normally needed on GTK. Native matrix pending. |
| Zen 1.23.2b-1 | `zen.Zen`; Linux chrome transparency exists, but current MAGI output only aliases ctp menu colours. **Partial/deferred**, no new alpha CSS emitted. | Potential chrome blur; native workspace layers and restart remain unverified. No webpage transparency changes. |
| GTK3 3.24.52 / GTK4 4.24.1, Thunar 4.20.10 | `desktop.Gtk`; GTK3 named theme paints separate surface/view/control backgrounds. **Partial/deferred** transparency. GTK4 palette already deferred. | No transparency or blur changes. Relaunch and widget-hierarchy review would be required. |
| Neovim 0.12.6 | `neovim.Neovim`; Normal/NormalNC/SignColumn already use NONE. **Inherits host** for base areas. | Floats, Pmenu, Telescope, status/selection regions retain deliberate backgrounds. Existing :colorscheme magi reload or next launch. |
| Yazi 26.9.1 + yatline | `terminal.Yazi`; many base styles use bg=reset; local yatline show_background=false. **Partial inheritance**. | File markers, selection/count backgrounds remain opaque. Current explicit palette data is retained; next launch. |
| btop 1.4.7 | `terminal.Btop`; generated theme has main_bg but local theme_background=false suppresses it. **Inherits host** in this configuration. | No new btop styling; restarting/reselecting theme remains existing activation. Full semantic polish stays in 12H. |
| Starship 1.27.0 | `terminal.Starship`; terminal output, **inherits host**. | Explicit segment backgrounds stay opaque; no fake alpha adapter. Next prompt/new shell as existing enrollment requires. |
| Fastfetch 2.70.0 | `terminal.Fastfetch`; ANSI output, **inherits host**. | Foreground/artwork unchanged, next invocation; no independent alpha file. |
| Hyprland 0.56.2, efb50993780079460b0cbed1363e2166a2de1d9f | Theme adapter stays border-only. Application module uses only a fixed rule handle. **Compositor engine**, not alpha provider. | Existing global blur retained. No Layer Rules, client-opacity options or whole reload. |

### Ghostty reference findings

Installed `ghostty +show-config --default --docs` and `ghostty(5)` identify the
native keys, 0–1 accepted opacity, default false for background-opacity-cells, and
Ctrl+Shift+, bound to reload_config. The operator's current base config has
background-opacity=0.95, then the existing MAGI colors.conf include. That file is
preserved. Disabling MAGI background ownership **omits** both new keys from the
included generated output, restoring the operator's .95 after reload, not forcing 1.

[Ghostty option reference](https://ghostty.org/docs/config/reference) documents
background opacity separately from foreground and explains explicit cell backgrounds.
[Ghostty v1.3.1 generic renderer](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/renderer/generic.zig)
loads alpha into background colour uniforms; foreground colour is separate.
[GTK application reloadConfig](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/apprt/gtk/class/application.zig)
loads configuration and propagates it to terminal surfaces. That source also handles
SIGUSR2, but this phase does **not** add PID discovery/signalling or a universal
activation scheduler. The reference native gate uses the existing keyboard reload.

The default Wayland app ID/X11 class is com.mitchellh.ghostty, confirmed by installed
class option docs. Custom --class/config IDs and alternate terminal hosts are not
covered by the fixed rule. Native acceptance must verify the actual client class.
The local configuration has no custom class. Application command-line overrides,
custom shaders or explicit foreground faint/dimming settings remain app-owned;
MAGI adds no foreground alpha. Background images are background content, and may
follow background alpha; terminal image/content samples must be checked natively.

Ghostty's own background-blur knob is documented for macOS/KWin; it is not the
Hyprland control. This adapter never emits it. Hyprland provides blur using its
already-configured engine. At opacity 1 blur can be visually irrelevant. At lower
alpha, blur off must show sharp underlying pixels; blur on must soften them while
text/content remain unchanged. Native acceptance is still required to prove this
on the host, and absence of blur is a failed gate, not success by transparency alone.

### Zen and GTK scope decisions

[Zen's official advanced preferences](https://docs.zen-browser.app/guides/about-config-flags)
identify zen.widget.linux.transparency for chrome, separate from webpage background
behaviour. Installed `browser/omni.ja` → `defaults/preferences/firefox.js` defaults
both that flag and browser.tabs.allow_transparent_browser to false. Neither is
explicitly overridden in the audited profile. Installed zen-theme.css conditionally
makes the top-level browser transparent under the Linux flag; workspace/chrome
layers are independently styled. A --zen-background-opacity variable alone is not
proof of a complete numeric-alpha mechanism. Existing MAGI ctp aliases mainly feed
popup/menu variables and cannot safely become a universal chrome alpha override.
Therefore Zen generation remains unchanged; a future verified chrome-only adapter
must coordinate with the current workspace styling and explicit restart. Webpage
content and browser preferences are not rewritten. [Zen's FAQ](https://docs.zen-browser.app/faq)
also warns about transparent webpage backgrounds changing site appearance.

Thunar's current generated theme styles window/dialog/toolbar/menubar, view/entry,
menu/popover, and selected/hovered states separately. Native GTK CSS RGBA support
alone cannot establish that the top-level visual, view background and each container
compose correctly. The sidebar, icon/list view, header/path controls, dialogs and
popovers therefore remain a deferred **native hierarchy** audit. No universal
transparent selector or experimental GTK alpha output ships in this pass.

## Ownership and coordinator

Canonical theme palette + normalized application preference → the **same Ghostty
adapter** → one complete colors.conf. Theme Orchestrator remains the sole generated
file writer and uses its existing store/lock. No parallel overlay writer races it.
Unsupported theme adapters receive no new alpha input and render byte-identical
output for the same palette. Theme changes read the retained appearance policy;
changing alpha adds only background-opacity and background-opacity-cells lines.
Palette/ANSI/foreground values are identical.

`application_appearance` separates policy, capability registry, blur planner,
executor and `ApplicationAppearanceCoordinator`. The coordinator runs inside the
existing Theme Orchestrator lock via the application-appearance operation. It
requires existing Ghostty enrollment and valid hooks; it does not enroll or edit
operator files. Removing Ghostty enrollment while appearance is managed is refused
until appearance is released. A pending transaction blocks competing theme work.

Generated files stay under `$XDG_DATA_HOME/magi/theme-orchestrator/ghostty/`, with
immutable generations and an atomic current pointer. State and recovery intent
stay in `$XDG_STATE_HOME/magi/theme-orchestrator/state.json`, outside Git. Settings
holds desired policy only. No second generated state location is needed.

Transaction: normalize → check enrollment/hook ownership → snapshot verified
current generation → render palette + policy → validate with installed Ghostty
parser using isolated HOME/config → read fixed blur handle → durable journal →
publish generation → verify manifest/files → toggle blur if needed → authoritative
handle readback → commit policy/status. Publication and file writes reuse the
existing atomic generation store, with directory fsync added for journal/pointer durability. Failure restores the previous generation and
previous same-generation rule state. Failed rollback retains the journal and
reports error; recovery precedes further theme work. After a compositor reload,
old handle state is never restored into a new generation. Release omits generated
alpha keys and disables the owned exclusion. Reload Ghostty to finish release.

Status contract distinguishes `released`, `reload-required`, `error`, support and
native verification. Published configuration is **not** labelled visually Applied.
The QML service retains debounce and config-reload reconciliation but is **unwired**
from shell.qml in this worktree. Tests use fake executors and a disposable fake
worker. No application reload is initiated automatically; there is no destructive
compositor-loss test. A human reload occurring during an error requires reloading
the restored generation too. Full multi-app activation and applied-generation
acknowledgment remain Phase 12H.

## Blur architecture and bootstrap proposal

The old all-client no-blur rule is too broad: unsupported apps must remain unchanged.
The proposed replacement has one immutable rule named
magi-ghostty-background-no-blur, matching exactly `^com\\.mitchellh\\.ghostty$`,
disabled by default. It targets ordinary Ghostty clients only, not layers or MAGI.
The retained handle is magi_application_background.rule; runtime operations are only
set_enabled(true/false), with is_enabled readback and config-generation guards.

Blur allowed means the MAGI exclusion is disabled. Operator no_blur=true exceptions
remain authoritative. Blur off enables the fixed exclusion without changing Ghostty
background alpha. App-specific opaque cell backgrounds remain opaque in both modes.
The fixed rule belongs after operator rules/includes; later same-priority rules or
higher-priority setprop retain normal Hyprland precedence. No effects are redefined
at runtime and no whole reload is used for edits.

The new block is a **proposal only** in [bootstrap.lua](../../tests/phase12g/bootstrap.lua).
A later approved surgical change must replace/remove the old disabled all-client
block, not append a second competing authority. Its generation UUID distinguishes
config loads; no opacity baseline callback is needed now. No live hyprland.lua edit
was made during correction. If a custom Ghostty ID or operator blur exception blocks
the reference test, stop for a scoped rule review rather than broadening the matcher.

Global blur size/passes, fullscreen opacity, border palette, shell tokens, layer
opacity and lock effects are outside this policy. A future **Appearance → Advanced
shell/compositor styling → Global blur** must explicitly describe global effects;
it is not implemented here.

## Settings, preview and schema 19 proposal

Recommend first-class **Applications** navigation with page title **Application
appearance**. This replaces Windows because the feature concerns supported native
adapters, not window-state opacity. It reuses the Phase 12F spacing, sliders,
toggles, quiet Reset, semantic 22 px apps icon and progressive disclosure.

Keep an explicit “Use application appearance” toggle: 100% is an intentional opaque
background override, while management off restores an operator background such as
Ghostty's .95. Those are meaningfully different actions. Normal controls are one
Background opacity percentage and Blur behind applications. Support details are
collapsed, with honest reload/partial/inherited labels and native-pending text.

```json
{"applicationAppearance":{"managed":false,"backgroundOpacity":1.0,"blurEnabled":true}}
```

Schema still advances **18 → 19 only once**; no active/inactive/fullscreen fields.
The clean schema-18 fixture migration preserves all old fields and is idempotent.
The proposed range is **50–100%**, a conservative product limit within Ghostty's
0–1 capability. Foreground remains opaque; six-theme preview checks cover the
background/readability relationship. The lower bound remains subject to native
reference acceptance. It is not claimed to guarantee readability for every TUI.

The already-saved experimental schema-19 live file is not silently rewritten.
Future integration must explicitly replace its rejected Windows policy after
rollback and preserve all unrelated fields; no schema-20 debt is added for an
uncommitted experiment. The copied schema-18 snapshot is the migration authority.

Preview background alpha is on a **background rectangle only**. A sibling opaque
foreground contains text, a control, icon and image sample. Sharp striped desktop
detail is replaced inside the application by a soft gradient when blur is enabled;
this is an illustrative approximation, not shader/compositor equivalence. QML tests
check background alpha, unchanged foreground ancestry opacity, and identical opaque
image pixels across alpha/blur changes. The preview never queries or changes windows.

Future **Application appearance → App overrides** may add supported per-app alpha;
none is implemented. Phase 12H can consume the capability/activation contract without
changing file ownership. Zen refresh, global application reload scheduling and btop
semantic redesign remain outside this phase.

## Review gallery and tests

[Default](previews/phase12g/background/01-default.png) ·
[100%](previews/phase12g/background/02-opaque.png) ·
[Translucent, sharp](previews/phase12g/background/03-translucent-sharp.png) ·
[Translucent, blurred](previews/phase12g/background/04-translucent-blurred.png) ·
[100%, blur on](previews/phase12g/background/05-opaque-blur-on.png) ·
[100%, blur off](previews/phase12g/background/06-opaque-blur-off.png) ·
[Support detail](previews/phase12g/background/07-support-detail.png) ·
[Compact Dawn](previews/phase12g/background/08-compact-dawn.png) ·
[Error detail](previews/phase12g/background/09-error-detail.png).

Six theme captures are in the same directory: Catppuccin Mocha, Everforest Dark
Hard, Rosé Pine, Nord, Tokyo Night Moon and Rosé Pine Dawn. The 13 rejected
whole-window captures are retained separately for historical evidence. Software
rendering does not reproduce all SVG tinting; native icon acceptance is deferred.

Backend tests cover policy bounds, independent transparency/blur plans, forbidden
writes, fixed-rule toggling, blank diagnostics, native Ghostty config validation,
foreground/palette invariance, deterministic output, release, theme composition,
unsupported adapters, generation/validation/publication failure, partial toggle
failure, readback mismatch, rollback failure/recovery, IPC unavailable, restart/
reload, release failure, modified generated files and enrollment conflict. QML
lifecycle and preview tests run without native compositor mutation. Final regression
results and exact inventory are recorded below after completion.

## Native acceptance plan — later approval only

1. Review the corrected schema, file ownership and narrow bootstrap proposal.
2. Verify live client defaults remain 1/1 and old broad exclusion is disabled; install
   only the approved narrow replacement. Confirm Ghostty's actual client class.
3. Enroll/use the existing Ghostty theme hook; capture effective app opacity (.95 on
   this config) and generated generation before ownership. Publish and use Ghostty's
   Ctrl+Shift+, reload; do not kill or restart terminal sessions.
4. Test **100% / blur off**, **100% / blur on**, **reduced / blur off**, **reduced /
   blur on**. At reduced alpha verify sharp versus blurred underlying detail and
   identical text, icons, controls, terminal images and deliberate coloured cells.
5. Verify shell surfaces unchanged, global blur 8/4 unchanged, no client opacity
   writes, no rule accumulation. Test update, release and Reset; app default .95
   must return after native reload. Validate reload/restart reconciliation separately.
6. If Ghostty cannot satisfy both background alpha and independent blur reliably,
   stop. Do not declare Phase 12G complete or expand unsupported-app scope.
7. Zen/GTK native work remains deferred until its specific limitations are resolved.
   Full session restart and app-wide activation coordination are not required here.


## Final corrected-pass validation and exact inventory

Passed: 23 backend/capability/transaction tests; final schema-19 migration from the
copied operator schema-18 document; QML lifecycle/debounce; QML preview and keyboard/
reset/persistence checks; Settings persistence and presentation/navigation;
Phases 12C, 12D, 12E and 12F; Theme Orchestrator (15 tests); runtime visuals;
`git diff --check`. A preview-only QML punctuation error was corrected, and every
affected UI regression was rerun successfully. Known offscreen IPC/mask warnings
are explicitly filtered by existing harnesses, not native acceptance claims.

The entire main-checkout snapshot after rollback is byte-identical, including all
14 protected entries, live settings.json and hyprland.lua. Both indexes are empty.
No corrected source or application-generated output was integrated live.

Inventory relative to accepted baseline: **66 paths: 44 A, 22 M, 0 D**.
There are 15 corrected preview captures and 13 retained historical captures.
Retained groundwork: schema-19 plumbing, Settings primitives/navigation integration,
existing regression version expectations, lifecycle/test harnesses and audit history.
Redesigned: page/model/preview, final schema policy, rule fixture and Phase 12G tests.
New: application_appearance modules, service, sole-writer Ghostty renderer extension
and shared-lock coordinator integration. Removed rejected candidate files:
WindowAppearanceService.qml, window_appearance_backend.py, window_appearance/*.py,
WindowsPage.qml and WindowAppearancePreview.qml. These were untracked candidate
files, so their removal is not a baseline Git D. shell.qml is back to the baseline
(no new service activation). Historical PNGs moved into rejected-whole-window/.

```text
A linux/magi/.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml
M linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
A linux/magi/.config/quickshell/magi/components/settings/pages/ApplicationsPage.qml
M linux/magi/.config/quickshell/magi/components/settings/qmldir
A linux/magi/.config/quickshell/magi/services/ApplicationAppearanceService.qml
A linux/magi/.config/quickshell/magi/services/application_appearance/coordinator.py
A linux/magi/.config/quickshell/magi/services/application_appearance/executor.py
A linux/magi/.config/quickshell/magi/services/application_appearance/planner.py
A linux/magi/.config/quickshell/magi/services/application_appearance/policy.py
A linux/magi/.config/quickshell/magi/services/application_appearance/registry.py
M linux/magi/.config/quickshell/magi/services/qmldir
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/adapters/desktop.py
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/coordinator.py
M linux/magi/.config/quickshell/magi/services/theme_orchestrator/storage.py
M linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
M linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
M linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
M linux/magi/.config/quickshell/magi/settings/persist.py
M linux/magi/docs/README.md
M linux/magi/docs/architecture.md
M linux/magi/docs/decisions.md
A linux/magi/docs/design/phase12g-window-visuals.md
A linux/magi/docs/design/previews/phase12g/background/01-default.png
A linux/magi/docs/design/previews/phase12g/background/02-opaque.png
A linux/magi/docs/design/previews/phase12g/background/03-translucent-sharp.png
A linux/magi/docs/design/previews/phase12g/background/04-translucent-blurred.png
A linux/magi/docs/design/previews/phase12g/background/05-opaque-blur-on.png
A linux/magi/docs/design/previews/phase12g/background/06-opaque-blur-off.png
A linux/magi/docs/design/previews/phase12g/background/07-support-detail.png
A linux/magi/docs/design/previews/phase12g/background/08-compact-dawn.png
A linux/magi/docs/design/previews/phase12g/background/09-error-detail.png
A linux/magi/docs/design/previews/phase12g/background/theme-catppuccin-mocha.png
A linux/magi/docs/design/previews/phase12g/background/theme-everforest-dark-hard.png
A linux/magi/docs/design/previews/phase12g/background/theme-nord.png
A linux/magi/docs/design/previews/phase12g/background/theme-rose-pine-dawn.png
A linux/magi/docs/design/previews/phase12g/background/theme-rose-pine.png
A linux/magi/docs/design/previews/phase12g/background/theme-tokyo-night-moon.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/01-management-off.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/02-on-100-100.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/03-differentiated.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/04-strong-difference-blur-allowed.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/05-blur-excluded.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/06-compact-light.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/07-error-detail.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-catppuccin-mocha.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-everforest-dark-hard.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-nord.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-rose-pine-dawn.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-rose-pine.png
A linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-tokyo-night-moon.png
M linux/magi/docs/quickshell-reference.md
M linux/magi/tests/phase12c/schema.cjs
M linux/magi/tests/phase12d/schema.cjs
M linux/magi/tests/phase12e/ownership.cjs
M linux/magi/tests/phase12f/presentation.qml
A linux/magi/tests/phase12g/bootstrap.lua
A linux/magi/tests/phase12g/lifecycle.py
A linux/magi/tests/phase12g/lifecycle.qml
A linux/magi/tests/phase12g/presentation.py
A linux/magi/tests/phase12g/presentation.qml
A linux/magi/tests/phase12g/run.py
A linux/magi/tests/phase12g/schema.cjs
M linux/magi/tests/settings/expected18.cjs
M linux/magi/tests/settings/run.py
M linux/magi/tests/settings/schema.cjs
M linux/magi/tests/settings/store.qml
```

# Historical rejected architectures — retained evidence, not implementation instructions

# Phase 12G — runtime client defaults and fixed blur exclusion

## Native adapter correction — blank diagnostics

Operator readback of `hyprctl -j configerrors` returned `[""]`. The initial
adapter incorrectly treated that nonempty list as a real error and stopped before
baseline capture or writes. Normalize blank/whitespace-only diagnostic lines;
retain real diagnostics in the error detail and reject malformed responses.
The 25-test backend suite now covers the native empty-string response, whitespace,
real errors and malformed diagnostics. Schema 19 saved with all unrelated operator
settings preserved. Native opacity acceptance resumes through the existing Retry
action; this fix does not request a shell or compositor reload.


> **Native finalization in progress:** operator approved the exact bootstrap append
> and confirmed unchanged appearance. Live readback: active/inactive/fullscreen 1,
> blur size 8, passes 4, fixed no-blur rule disabled. The 48-path source integration
> reloaded in the existing MAGI process with no new QML errors; settings.json stayed
> byte-identical at schema 18. Production service activation is now being wired,
> governed by managed=false. Native managed-policy acceptance, final regression,
> staging, commit and push remain pending. Earlier unwired statements below record
> the isolated checkpoint, not final acceptance.


2026-10-24. **Ready for a controlled live activation gate; production activation
remains unwired.** Worktree `/home/jkebwdn/magi-phase12g` continues from
`abeba3be79c22113e1d165c3da1bb2296cbe9495` (`magi: refine settings product design`),
with `HEAD...origin/main = 0 0`. No integration, staging, commit, push or Phase 12H.
The two accepted architecture stops are retained below as historical records;
their rejected mechanisms and bootstrap examples are not current instructions.

## Architecture decision

| Candidate | Decision |
| --- | --- |
| Mutable named opacity rules | Rejected: updating a named rule appends effects. Stable object count is insufficient. |
| Generated fragment plus whole reload | Rejected for routine activation: re-evaluates unrelated operator configuration. |
| Runtime client opacity defaults plus one fixed no-blur rule | Selected for controlled native acceptance. No rule effect mutation or compositor reload. |

Global compositor blur strength was rejected in the first review. This implementation
never writes blur size, passes, enabled, noise, contrast, brightness, vibrancy or
other global blur parameters. Operator configuration currently specifies size 8,
passes 4; actual IPC readback remains unavailable in this isolated environment.

## Exact-version contract and isolation evidence

The accepted installed audit identifies **Hyprland 0.56.2**, revision
`efb50993780079460b0cbed1363e2166a2de1d9f`. Source contracts below are pinned to that
revision, not current wiki syntax. The executor refuses other builds. Live IPC
was unavailable in the audit; all execution in this pass used fakes/mocks.

- [HyprCtl.cpp](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/debug/HyprCtl.cpp): `dispatchKeyword` rejects Lua configuration and directs callers to eval. Therefore the suggested `hyprctl keyword decoration:active_opacity …` is **not** used for this operator's Lua setup. `evalRequest` supplies `eval` and `repl` entry points.
- [Lua config bindings](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/config/lua/bindings/LuaBindingsConfigRules.cpp): `hl.config` updates nested configuration values and schedules their refresh; `hl.get_config` returns their current typed values. [ConfigValues.cpp](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/config/values/ConfigValues.cpp) defines active/inactive/fullscreen opacity as floats, default 1, range 0–1, with window-state refresh.
- [Window.cpp, updateDecorationValues](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/desktop/view/Window.cpp#L1721-L1778) reads these three options for **client windows**. True internal fullscreen selects the fullscreen value independently; other clients select active or inactive. It does not multiply fullscreen by active opacity.
- [Renderer.cpp, renderLayer](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/render/Renderer.cpp#L852-L937) constructs layer render data using the layer fade alpha, not client opacity options. [SurfacePassElement.hpp](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/render/pass/SurfacePassElement.hpp#L14-L38) initializes render alpha to 1. Session-lock rendering is also separate. This proves the global **client** options do not change layer-shell opacity.
- [WindowRuleApplicator.cpp](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/desktop/rule/windowRule/WindowRuleApplicator.cpp#L522-L555) filters window-rule type, checks matches, and applies rules in engine order. The rule targets clients, not layer namespaces. [Engine.cpp](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/desktop/rule/Engine.cpp) preserves registration order; naming does not confer specificity priority.
- [LuaWindowRule.cpp](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/config/lua/objects/LuaWindowRule.cpp): `set_enabled` changes the enabled flag and refreshes rules, without adding effects; `is_enabled` reads it and returns nil for an expired handle.

Representative exact operations (documentation only; not run against the session):

```sh
hyprctl -i "$HYPRLAND_INSTANCE_SIGNATURE" eval 'hl.config({decoration={active_opacity=0.95}})'
hyprctl -i "$HYPRLAND_INSTANCE_SIGNATURE" eval 'hl.config({decoration={inactive_opacity=0.90}})'
hyprctl -i "$HYPRLAND_INSTANCE_SIGNATURE" repl 'print(hl.get_config("decoration.active_opacity"))'
hyprctl -i "$HYPRLAND_INSTANCE_SIGNATURE" eval 'magi_window_appearance.rule:set_enabled(true)'
hyprctl -i "$HYPRLAND_INSTANCE_SIGNATURE" eval 'magi_window_appearance.rule:set_enabled(false)'
hyprctl -i "$HYPRLAND_INSTANCE_SIGNATURE" repl 'print(magi_window_appearance.rule:is_enabled())'
```

Production prepends an instance/config-generation guard to each mutation in the
**same Lua evaluation**. It reads identity, generation, active/inactive options,
rule enabled state, configured baseline and read-only fullscreen value in one
`repl` snapshot. It checks `version` and JSON `configerrors` before activation.
A missing bootstrap, expired handle, invalid readback or changed generation fails
closed. Numeric verification accounts for Hyprland's float32 representation.

## Opacity composition, fullscreen and operator rules

The [installed SAlphaValue implementation](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/desktop/types/OverridableVar.hpp)
multiplies a normal rule's alpha by its global default; an `override` rule returns
its own alpha instead. Thus global .90 with an app multiplier .80 produces .72;
app override .80 remains .80. MAGI neither rewrites nor deletes these rules.
The tests compile the installed header's alpha structure and exercise both cases.
The UI percentage is a default, not a guarantee about final application pixels.
Application-provided transparency also remains effective.

**Fullscreen decision A: leave fullscreen_opacity entirely operator-owned.**
The source default is 1 and the audited operator config has no fullscreen opacity
setting or rule. Lowering active/inactive defaults therefore does not make ordinary
true-fullscreen games, video or presentations translucent. Existing fullscreen
rules and app alpha still apply. Maximized windows are not true fullscreen. No
fullscreen setting, write, baseline ownership or slider is introduced.

The existing named Settings/Clipboard rules only float/center/size their fallback
client windows; no local opacity/no-blur rules were found. Fixtures cover no rules,
app multipliers, overrides, named and anonymous no-blur true/false, and fullscreen
independence. PiP, XWayland and dialog **clients** follow ordinary defaults. Wayland
popup surfaces use a separate render path; popup blur parameters remain untouched.
Native popup appearance is an acceptance observation, not an offline proof.

Blur allowed disables MAGI's fixed rule, leaving every operator no-blur exception
intact. Blur excluded enables its fixed `no_blur=true` effect. The proposed EOF
insertion is after all existing rules/includes, so it wins over earlier configured
`no_blur=false` rules at window-rule priority. Specificity alone is not priority.
Later runtime rules, exec rules or higher-priority `setprop` can supersede it;
MAGI does not fight arbitrary external mutations. None was found in the current
operator configuration. Readback reports the owned default/rule state, not an
assertion that every possible per-client override was eliminated.

The domain is deliberately all ordinary clients (`class = ".*"`), with no invented
application exclusions. MAGI's production Settings lives in the Hub layer. Bar,
Hub, CC, Launcher, Calendar, Notifications, wallpaper and lock retain their surface
paths and styling. A separately launched fallback Quickshell **FloatingWindow**
is an ordinary client and would follow these defaults; it is not exempt by brand.
No shell style fields, Layer Rules, border colours or Theme Orchestrator output change.

## Baseline, transaction and lifecycle

Settings → normalized policy → deterministic planner → guarded executor → readback.
`WindowAppearanceService.qml` schedules a Python service after 450 ms debounce.
No page invokes hyprctl. The service is registered but **not activated by shell.qml**.
No request from this isolated Settings preview can apply compositor policy.

Runtime files belong only under `$XDG_STATE_HOME/magi/window-appearance/` (fallback
`~/.local/state/magi/window-appearance/`): desired.json, ownership.json,
transaction.json, status.json and transaction.lock. No generated Lua/config file.
Ownership records compositor instance, configuration generation, captured operator
active/inactive baseline, desired policy and verified applied values. It never goes
in settings.json. Files use private atomic temp writes, fsync, rename and directory
fsync; flock serializes workers.

First enable reads the actual runtime options, preserving values even below the UI
minimum. Before any write, a durable transaction journal records that snapshot and
previous ownership. The planner only changes differing active/inactive values and
the blur flag. After all writes, typed readback must match before publishing Applied.
On failure it restores **all three** prior runtime values, verifies them, and reports
an error. Rollback failure leaves a recovery journal and unknown active status.
No exit-zero-only Applied claim, rule creation, effect update or whole reload occurs.

Disable restores the captured opacity baseline, disables the owned rule, verifies,
then clears ownership. It never blindly writes 1. Reset uses the same release path.
A managed-false migration with no ownership makes no IPC calls. A failed release
retains ownership and rolls back to the prior managed state, with an explicit error.

[Compositor.cpp](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/Compositor.cpp#L173-L201)
creates and exports a signature from commit, startup time and randomness. Every
executor command selects that signature explicitly and readback confirms it.
Same compositor + same generation reuses the persisted baseline, including after a
MAGI restart. A new compositor discards old ownership and captures fresh defaults
before applying desired policy. A worker with an old signature cannot silently
retarget a new session; the new session launches MAGI with its new environment.

[Lua ConfigManager.cpp](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/config/lua/ConfigManager.cpp#L784-L789)
resets Lua/configuration on reload, finishes configuration work, emits the internal
`config.reloaded` callback, then posts the `configreloaded` IPC event. The bootstrap
captures configured defaults during that callback. Its per-load UUID distinguishes
reloads even if MAGI was stopped or missed IPC. On a new generation in the same
compositor, the service saves those configured defaults as its new baseline and
reapplies desired state once. Repeated events/readback produce no duplicate writes.

Generation checks prevent a reload between a read and write from restoring stale
values into the new configuration. A pending recovery journal is replayed only for
its original instance/generation; otherwise it is discarded before reconciliation.
IPC loss keeps desired policy, reports unavailable, and retains recovery state.
QML uses a passive event socket, one bounded startup/reconnect retry and lifecycle/
edit events, not a polling loop. Actual socket reconnection remains a native test.

## Proposed surgical bootstrap — NOT APPLIED

A static fixed rule is required: runtime creation is unnecessary and risks repeated
definitions. The additional UUID and read-only callback are lifecycle metadata,
not opacity policy. They are necessary to recognize a reload missed during MAGI
restart and to preserve the newly configured baseline without guessing from managed
runtime values. `/proc/sys/kernel/random/uuid` is read once per config load; no file
is written by the hunk. If unavailable, configuration fails rather than using an
ambiguous generation identifier.

Insert after the current final include. BEFORE (end of file):

```lua
-- hyprmon: managed monitor profile include
require("hyprmon")
```

AFTER: retain that exact context, append a blank line and the following exact hunk:

```lua
-- MAGI WINDOW APPEARANCE BEGIN -- append after all operator rules/includes
-- Fixed rule: define once per config load; runtime may only toggle the handle.
do
    local uuid = assert(io.open("/proc/sys/kernel/random/uuid", "r"))
    magi_window_appearance = {
        generation = assert(uuid:read("*l")),
        rule = hl.window_rule({
            name = "magi-application-no-blur",
            match = {class = ".*"},
            enabled = false,
            no_blur = true,
        }),
    }
    uuid:close()
    -- Read-only lifecycle metadata, captured before the configreloaded IPC event.
    hl.on("config.reloaded", function()
        magi_window_appearance.configured = {
            activeOpacity = hl.get_config("decoration.active_opacity"),
            inactiveOpacity = hl.get_config("decoration.inactive_opacity"),
        }
    end)
end
-- MAGI WINDOW APPEARANCE END
```

The [standalone fixture](../../tests/phase12g/bootstrap.lua) is the exact hunk.
A copy of the current dirty operator Lua plus this append compiles with Lua; removal
recovers the exact original bytes. A fake Lua capability harness verifies its default
disabled state, operator-rule coexistence and 200 enable/disable cycles without any
new effect or rule. This proves representation/API intent, not a native render test.

Later approved integration must append this block only, after all existing
rules/includes, and verify the initially disabled rule. Removal plan: first disable
management and verify restored baseline, stop activation, then remove only this
marked block. Any operator reload needed to install/remove the bootstrap is a
separate explicit native action; routine MAGI changes never initiate one.

## Windows page, schema and previews

The first-class Windows entry uses the shared 22 px semantic apps icon. Wide layout
places inert overlapping synthetic windows left and production Settings controls
right; it stacks below 580 px page content. Active/inactive sliders independently
cover **30–100%**, with percentages, keyboard steps and accessible names. Management
and blur participation toggles, quiet Reset and an Advanced disclosure complete the
page. The default lower bound avoids effectively invisible windows; operator
baseline restoration is not clamped to this product bound.

Blur text says it uses existing Hyprland settings. The preview illustrates allowed
versus excluded blur with a veil, not a strength simulation or compositor-equivalent
render. It never reads titles or focuses/moves windows. Advanced explains fullscreen,
external rules and error details. Runtime baseline is not exposed in normal UI.

Schema **18 → 19**, once, with neutral defaults:

```json
{"windows":{"appearance":{"managed":false,"activeOpacity":1.0,"inactiveOpacity":1.0,"blurApplications":true}}}
```

No size/passes/fullscreen fields. Migration and reset affect only Windows policy;
the current copied operator fixture preserves every existing field except schema
version, and migration is idempotent. Production integration remains separate.

[Off](previews/phase12g/rejected-whole-window/01-management-off.png) ·
[On, 100/100](previews/phase12g/rejected-whole-window/02-on-100-100.png) ·
[Differentiated](previews/phase12g/rejected-whole-window/03-differentiated.png) ·
[Stronger difference, blur allowed](previews/phase12g/rejected-whole-window/04-strong-difference-blur-allowed.png) ·
[Blur excluded](previews/phase12g/rejected-whole-window/05-blur-excluded.png) ·
[Compact/light](previews/phase12g/rejected-whole-window/06-compact-light.png) ·
[Error details](previews/phase12g/rejected-whole-window/07-error-detail.png).

Theme gallery: [Mocha](previews/phase12g/rejected-whole-window/theme-catppuccin-mocha.png),
[Everforest](previews/phase12g/rejected-whole-window/theme-everforest-dark-hard.png),
[Rosé Pine](previews/phase12g/rejected-whole-window/theme-rose-pine.png), [Nord](previews/phase12g/rejected-whole-window/theme-nord.png),
[Tokyo Night Moon](previews/phase12g/rejected-whole-window/theme-tokyo-night-moon.png),
[Dawn](previews/phase12g/rejected-whole-window/theme-rose-pine-dawn.png).
Offscreen software rendering cannot demonstrate every tinted SVG icon or native
blur; the production semantic icon architecture is unchanged.

## Validation, acceptance and future work

Passed: **23** policy/planner/adapter/transaction tests, including compiled installed
alpha semantics, fixed-rule Lua fixture, exact mock commands, baseline capture/
restore, same-session restart, fresh session, missed reload, reload during apply,
partial failures at each apply/release step, readback mismatch, rollback failure
and recovery, IPC loss, invalid policy and persistence failure. Negative assertions
reject reload, dynamic window-rule definitions/effects, fullscreen writes, global
blur writes, layer rules and shell namespace matching.

Also passed: copied operator schema-18 migration; QML fake-worker lifecycle/debounce;
Windows presentation, keyboard/reset/persistence, compact layout and six themes;
Settings persistence/schema/presentation/navigation; Phase 12C, 12D, 12E, 12F;
Theme Orchestrator **15 tests**; runtime visuals; git diff --check. The direct Settings
schema command initially omitted its required path argument; the corrected invocation
passed. Offscreen harnesses explicitly filter known unavailable IPC/mask warnings.
Regression logs are under `/tmp/magi-12g-pivot-tests/`; these are development artifacts.

The controlled native gate must approve/install the exact disabled bootstrap and
wire service activation, then check live readback, operator baseline restore, real
layer surfaces, fullscreen/app overrides, reload/restart and socket loss. Offline
success is not a claim that native activation has already occurred. No architectural
blocker remains under the documented authority/precedence contract.

Future **Windows → App Rules** can use operator-compatible multiplier/override
semantics; it is not implemented. Future **Appearance → Advanced shell/compositor
styling → Global blur** must disclose effects on all participating compositor
surfaces. It is separate from app rules and is not implemented. Theme Orchestrator
still owns border palette only. Phase 12H activation coordination is untouched.

Protected-state verification and exact inventory follow; historical audit text
below is retained for traceability, not as active integration guidance.

## Protected state and exact current inventory

All 14 protected entries remain intact: the 13 snapshotted regular files are
byte-identical, the full main tracked binary diff is unchanged, and the Yazi flavor
symlink retains its target. Both Git indexes are empty. Main settings.json and
hyprland.lua are untouched. No runtime generated state is in Git.

**48 paths**, including 13 intentional PNG captures. This inventory supersedes the
historical inventories below. UI paths are components/settings; the QML service
and backend are services; policy/planner/executor/transaction files are under
services/window_appearance; schema/persistence are settings; tests are tests;
documentation and previews are docs. The proposed bootstrap exists only as a test
fixture and the documented hunk, never in the operator file.

```text
linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
linux/magi/.config/quickshell/magi/components/settings/WindowAppearancePreview.qml
linux/magi/.config/quickshell/magi/components/settings/pages/WindowsPage.qml
linux/magi/.config/quickshell/magi/components/settings/qmldir
linux/magi/.config/quickshell/magi/services/WindowAppearanceService.qml
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/services/window_appearance/executor.py
linux/magi/.config/quickshell/magi/services/window_appearance/planner.py
linux/magi/.config/quickshell/magi/services/window_appearance/policy.py
linux/magi/.config/quickshell/magi/services/window_appearance/service.py
linux/magi/.config/quickshell/magi/services/window_appearance_backend.py
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/settings/persist.py
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/phase12g-window-visuals.md
linux/magi/docs/design/previews/phase12g/rejected-whole-window/01-management-off.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/02-on-100-100.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/03-differentiated.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/04-strong-difference-blur-allowed.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/05-blur-excluded.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/06-compact-light.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/07-error-detail.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-catppuccin-mocha.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-everforest-dark-hard.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-nord.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-rose-pine-dawn.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-rose-pine.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-tokyo-night-moon.png
linux/magi/docs/quickshell-reference.md
linux/magi/tests/phase12c/schema.cjs
linux/magi/tests/phase12d/schema.cjs
linux/magi/tests/phase12e/ownership.cjs
linux/magi/tests/phase12f/presentation.qml
linux/magi/tests/phase12g/bootstrap.lua
linux/magi/tests/phase12g/lifecycle.py
linux/magi/tests/phase12g/lifecycle.qml
linux/magi/tests/phase12g/presentation.py
linux/magi/tests/phase12g/presentation.qml
linux/magi/tests/phase12g/run.py
linux/magi/tests/phase12g/schema.cjs
linux/magi/tests/settings/expected18.cjs
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
```

## Historical second architecture stop — superseded

# Historical reduced-scope implementation checkpoint

2026-10-24. **Windows presentation and offline groundwork implemented; native
activation blocked by a newly verified named-rule accumulation issue.**
The accepted initial audit is retained below as historical evidence.
No integration, staging, commit, push or Phase 12H work occurred.

## Accepted scope and implementation

The operator approved independent application active/inactive opacity and blur
participation. Global blur strength/size/passes remain operator/compositor-owned.
The Windows page exposes none of those global controls. No planner writes any
`hl.config`, global opacity option, blur parameter, border colour or layer rule.

The first-class **Windows** navigation entry follows Appearance and uses the shared
22 px semantic `apps` icon, without an override. Wide layout has the synthetic
scene on the left and controls on the right; below 580 px of page content the
columns stack. Existing Settings sliders, toggles, disclosure, Reset, spacing and
typography are reused. The inert scene shows background detail and overlapping
active/inactive clients. Blur participation uses an illustrative veil, not a
claim of matching compositor blur. It neither queries titles nor controls windows.

Active and inactive values are independent, normalized 0.30–1.00; the UI presents
30–100% with 1% keyboard steps. The lower bound preserves useful visibility.
Reset disables management, restores both values to 1 and follows existing blur.
Blur allowed means no **enabled** MAGI blur-exclusion rule; it never emits
`no_blur=false`, so an operator exclusion is preserved. Blur excluded means the
MAGI default `no_blur=true`; a later operator rule can still override that default.
Advanced explains fullscreen, global blur ownership and status/error details.

Schema advances once, **18 → 19**:

```json
{"windows":{"appearance":{"managed":false,"activeOpacity":1.0,"inactiveOpacity":1.0,"blurApplications":true}}}
```

Migration is neutral and idempotent. The copied current operator schema-18 fixture
was checked for exact semantic preservation of every old field. Only schemaVersion
and the new neutral Windows section differ. No live settings file was changed.

## New capability finding: named updates are not replacement

The local installed header
`/usr/include/hyprland/src/desktop/rule/RuleWithEffects.hpp`, corroborated by the
[exact installed revision's RuleWithEffects.hpp](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/desktop/rule/RuleWithEffects.hpp),
uses `emplace_back` in both `addEffect` and `addParsedEffect`. Reusing a named
rule retains its position and object count, but appends additional effects.
Thus a constant count of two named rules does **not** establish no accumulation.
Repeated opacity updates would retain old effects. The earlier fake replacement
model was insufficient; the regression now explicitly models and demonstrates
append behavior. This candidate is rejected for production.

The source inspected is Hyprland 0.56.2 commit
`efb50993780079460b0cbed1363e2166a2de1d9f`. Installed binary identity comes from the
accepted audit; no live version/readback proof is claimed. Inspection date is
2026-10-24. No upstream implementation was copied.

The reduced blur scope is accepted and remains sound. **This is a separate
activation blocker**, not a reopening of the global blur scope decision.

## Opacity, ordering and fullscreen findings

The offline fragment expresses three opacity values with `override`: requested
active, requested inactive, and fullscreen 1.0. This avoids unintended multiplication
by global decoration opacity. It would be inserted before operator rules; later
matching opacity effects can replace this default, including its override flags.
Specificity alone grants no priority. Both named and anonymous later operator
rules are represented in source-derived Lua fixtures. Future MAGI App Rules would
need a deliberate position after the global default and before operator rules.
These fixtures are models, not native Hyprland tests.

[Window.cpp::updateDecorationValues](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/desktop/view/Window.cpp)
selects fullscreen alpha independently when internal fullscreen mode is full.
[WindowRule.cpp::parseOpacityRule](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/desktop/rule/windowRule/WindowRule.cpp)
accepts separate values and override flags. Therefore the proposed fixed safe
default is 100% **compositor opacity** for full fullscreen, without another stored
setting. This does not remove application-owned alpha and does not prevent a
later operator fullscreen rule. Maximized windows use active/inactive policy.
No game/video/PiP exception editor is introduced.

## Service and transaction groundwork

`WindowAppearanceService.qml` is registered but **not activated from shell.qml**.
A Settings preview never activates it. Its backend is fail-closed: production
`ready()` and `apply()` reject the unapproved mechanism without invoking hyprctl.
The adapter retains bounded read-only call/readback scaffolding only. There is no
production opacity executor that is represented as safe or complete.

Separate Python policy, planner, executor and transaction modules permit isolated
validation. Generated state is designated for
`$XDG_STATE_HOME/magi/window-appearance/`, fallback `~/.local/state`, never Stow.
The offline service uses desired.json, generated.lua, active.json, status.json,
last-known-good.lua, a transaction journal and an advisory transaction lock.
Writes use a private temporary file, fsync and atomic rename. Recovery reconstructs
a plan from normalized journal policy rather than trusting stored executable Lua.

The fake-executor transaction validates and compiles before mutation, journals the
previous policy, applies, verifies a token plus enabled handle state, then publishes.
Failure restores known-good; rollback failure retains the recovery journal and
reports active state as unknown. This readback would establish MAGI slot state,
not every client's final composited opacity; operator rules remain legitimate.

Startup, restart, reload, disable and compositor-loss outcomes below are **offline**:

| Case | Result |
| --- | --- |
| Startup with persisted enabled policy | One fake activation; a single delayed unavailable retry is bounded. |
| Rapid slider edits | 450 ms debounce; real QML/fake-worker harness coalesces edits. |
| MAGI restart | Persisted candidate/readback match produces no extra fake apply. |
| Config reload | Event bursts coalesce; sourced matching candidate needs no extra fake apply. Stale state is reconciled once. |
| IPC loss | Desired policy retained; unavailable status. Passive socket loss clears claimed active state; one reconnect attempt, then lifecycle/manual retry. |
| Partial apply/readback failure | Fake rollback verified; original error remains visible. |
| Release failure/rollback failure | Error and unknown active state; durable journal recovered on next reconciliation. |
| Management off | Fake slots disabled; zero enabled MAGI rules, no neutral overriding rule. Physical slot removal is not proven as a live operation. |

A new compositor instance has a new socket path/signature; normal fresh-session
MAGI startup is required. The real event socket is not exercised here. No native
startup, restart, reload, rollback, blur or opacity acceptance is claimed.

## Remaining architecture decision and bootstrap candidate

A deterministic generated fragment loaded once per full config reconstruction can
avoid effect accumulation. However the inspected Lua reload path resets global
config values and re-executes unrelated configuration. It can discard runtime-only
operator values even if MAGI emits no global writes. Silently changing to that
mechanism would weaken the requested preservation boundary. It is **not enabled**.

Safest next review: either accept config reconstruction as an explicit activation
boundary (with unrelated-runtime-state reconciliation defined), or defer native
activation until reliable named effect replacement/removal exists. Do not use
an unbounded rule pool, repeatedly append effects, or restore global blur with
forbidden writes to conceal the issue.

`tests/phase12g/bootstrap.lua` is a **review fixture only** for early slot placement.
The exact hunk was compiled against a copy of the current dirty operator Lua and
its omission/file-present paths tested with fake hl handles. It was not applied.
The insertion point is immediately before the first `hl.config({` in INPUT:

```lua
-- BEFORE
-- INPUT
----------------------------------------------------------------

hl.config({
```

Exact proposed AFTER context (review only):

```lua
-- INPUT
----------------------------------------------------------------

-- REVIEW CANDIDATE ONLY: not approved for native activation. Never repeatedly eval generated.lua.
-- MAGI WINDOW APPEARANCE BEGIN (before all operator window rules)
local magi_state = os.getenv("XDG_STATE_HOME")
if not magi_state or magi_state == "" then magi_state = os.getenv("HOME") .. "/.local/state" end
local magi_windows = magi_state .. "/magi/window-appearance/generated.lua"
magi_window_appearance = {token = "bootstrap", handles = {}}
local magi_windows_file = io.open(magi_windows, "r")
if magi_windows_file then
    magi_windows_file:close(); dofile(magi_windows)
else
    magi_window_appearance = {token = "bootstrap", handles = {}, expected = {false, false}}
    table.insert(magi_window_appearance.handles, hl.window_rule({name = "magi-window-opacity", enabled = false,
        match = {class = "negative:^(org\\.quickshell|quickshell|magi.*)$"}, opacity = "1 override 1 override 1 override"}))
    table.insert(magi_window_appearance.handles, hl.window_rule({name = "magi-window-no-blur", enabled = false,
        match = {class = "negative:^(org\\.quickshell|quickshell|magi.*)$"}, no_blur = true}))
    magi_window_appearance.token = "ready"
end
-- MAGI WINDOW APPEARANCE END

hl.config({
```

The standalone [bootstrap fixture](../../tests/phase12g/bootstrap.lua) contains the same hunk. All existing window rules follow it. No formatting or unrelated
rewrite is needed. The marked block is removable; full reconstruction after
removal would eliminate its slots. Its generated fragment must never be repeatedly
evaluated under the rejected update mechanism. No bootstrap is approved yet.

## Boundaries and future work

Planner match excludes `org.quickshell`, `quickshell` and `magi*` clients.
Window-rule APIs do not target layer namespaces. No layer rule, shell token,
wallpaper or lock changes are emitted. Negative tests cover the match and absent
global writes; QML changes/reset preserve other Settings sections. Theme
Orchestrator source is unchanged and its 15-test regression passes.

Future **Windows → App Rules** may add application exceptions after precedence is
settled. Separately, any future global blur control belongs under
**Appearance → Advanced shell/compositor styling → Global blur**, explicitly
covering every participating surface. Neither extension nor Phase 12H is implemented.

## Validation and gallery

Passed: 16 policy/planner/capability/fake-transaction tests; copied operator schema
migration; real QML/fake-worker lifecycle; production Windows page keyboard/reset/
persistence and six palettes; Settings schema/store and presentation/navigation;
Phase 12C, 12D, 12E, 12F; Theme Orchestrator (15 tests); runtime visuals;
`git diff --check`. Offscreen harnesses filter their known unavailable IPC/window
mask warnings. No live compositor requests or applications were mutated.

The policy/service successes do not override the capability regression: the latter
proves why production remains blocked. The production-refusal test asserts zero
subprocess calls. A full Settings/runtime regression need not be rerun merely for
the later fail-closed adapter guard; focused tests were rerun after that change.

[Off](previews/phase12g/rejected-whole-window/01-management-off.png) ·
[On, 100/100](previews/phase12g/rejected-whole-window/02-on-100-100.png) ·
[Differentiated](previews/phase12g/rejected-whole-window/03-differentiated.png) ·
[Stronger difference, blur allowed](previews/phase12g/rejected-whole-window/04-strong-difference-blur-allowed.png) ·
[Blur excluded](previews/phase12g/rejected-whole-window/05-blur-excluded.png) ·
[Compact/light](previews/phase12g/rejected-whole-window/06-compact-light.png) ·
[Error details](previews/phase12g/rejected-whole-window/07-error-detail.png).

Theme captures: [Mocha](previews/phase12g/rejected-whole-window/theme-catppuccin-mocha.png),
[Everforest](previews/phase12g/rejected-whole-window/theme-everforest-dark-hard.png),
[Rosé Pine](previews/phase12g/rejected-whole-window/theme-rose-pine.png),
[Nord](previews/phase12g/rejected-whole-window/theme-nord.png),
[Tokyo Night Moon](previews/phase12g/rejected-whole-window/theme-tokyo-night-moon.png),
[Dawn](previews/phase12g/rejected-whole-window/theme-rose-pine-dawn.png).
Software rendering does not render every tinted SVG icon; the shared icon path
is unchanged. Native icon and compositor appearance acceptance remains pending.

Protected-state final check: 13 initially modified/untracked regular files remain
byte-identical; the entire main tracked binary diff is identical. Yazi flavor
symlink is present. Both indexes are empty. settings.json and hyprland.lua are
untouched. No generated runtime policy exists in Git.

## Exact current inventory

Inventory is generated below from the unstaged worktree. No settings.json or
operator hyprland.lua changes are included. The historical four-file inventory
farther below describes the earlier accepted audit only.

**48 paths**: 13 captures and 35 source/test/documentation paths.

```text
linux/magi/.config/quickshell/magi/components/settings/WindowAppearancePreview.qml
linux/magi/.config/quickshell/magi/components/settings/pages/WindowsPage.qml
linux/magi/.config/quickshell/magi/services/WindowAppearanceService.qml
linux/magi/.config/quickshell/magi/services/window_appearance/executor.py
linux/magi/.config/quickshell/magi/services/window_appearance/planner.py
linux/magi/.config/quickshell/magi/services/window_appearance/policy.py
linux/magi/.config/quickshell/magi/services/window_appearance/service.py
linux/magi/.config/quickshell/magi/services/window_appearance_backend.py
linux/magi/docs/design/phase12g-window-visuals.md
linux/magi/docs/design/previews/phase12g/rejected-whole-window/01-management-off.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/02-on-100-100.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/03-differentiated.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/04-strong-difference-blur-allowed.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/05-blur-excluded.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/06-compact-light.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/07-error-detail.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-catppuccin-mocha.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-everforest-dark-hard.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-nord.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-rose-pine-dawn.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-rose-pine.png
linux/magi/docs/design/previews/phase12g/rejected-whole-window/theme-tokyo-night-moon.png
linux/magi/tests/phase12g/bootstrap.lua
linux/magi/tests/phase12g/lifecycle.py
linux/magi/tests/phase12g/lifecycle.qml
linux/magi/tests/phase12g/presentation.py
linux/magi/tests/phase12g/presentation.qml
linux/magi/tests/phase12g/run.py
linux/magi/tests/phase12g/schema.cjs
linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
linux/magi/.config/quickshell/magi/components/settings/qmldir
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/settings/persist.py
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/quickshell-reference.md
linux/magi/tests/phase12c/schema.cjs
linux/magi/tests/phase12d/schema.cjs
linux/magi/tests/phase12e/ownership.cjs
linux/magi/tests/phase12f/presentation.qml
linux/magi/tests/settings/expected18.cjs
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
```

# Historical accepted initial audit — retained verbatim in substance

Date inspected: 2026-10-24. **Stopped for operator architecture review; not implemented.**
Phase 12F remains the accepted product. Phase 12H has not begun.

## Baseline and isolation

Main checkout: `/home/jkebwdn/dotfiles`.
Verified HEAD `abeba3be79c22113e1d165c3da1bb2296cbe9495`, subject
`magi: refine settings product design`, HEAD...origin/main `0 0`.
Fresh detached worktree: `/home/jkebwdn/magi-phase12g`, at that exact commit.
No fetch, live integration, staging, commit, push, compositor mutation, package
installation or session restart was performed.

The main checkout has the expected protected local edits and untracked files.
An external audit snapshot at `/tmp/magi-12g-audit/` contains SHA-256 hashes of
all initially modified/untracked files, the tracked binary diff and a byte copy
of the operator's schema-18 settings. These are local evidence, not Git artifacts.

## Stop decision and safest alternatives

The complete requested contract is **not proven**. Blur size and passes are
shared renderer parameters, not per-client parameters. Preserving layer rules
does not preserve a blurred layer's appearance when these parameters change.
No per-window blur-size/pass override was found in the exact-version bindings.

The checked operator Lua has no layer blur rules, and MAGI QML has no blur or
background-effect requests. This is evidence against an immediate shell change
in the checked configuration; it is **not** proof about runtime rules, plugins,
other layer clients or protocol-requested effects. Runtime readback is unavailable.
We do not claim the current shell necessarily changes, nor that Hyprland cannot
support a reversible implementation. The unconditional application-only boundary
cannot presently be certified for the requested strength controls.

The user's sections 18/38/70 require stopping rather than claiming isolation or
reversibility without evidence. No UI or schema change is shipped ahead of that gate.

Review alternatives:

1. Preserve all global blur parameters. Implement client opacity and client
   `no_blur` targeting only; enabling client blur would mean allowing the
   operator's existing blur, not overriding a globally disabled renderer.
   This is the safest reduced scope, but does not meet the requested independent
   blur strength/passes controls and needs an explicit scope decision.
2. Permit shared compositor blur parameter ownership, with honest scope and
   acceptance of effects on other blurred surfaces. This changes the boundary;
   it must not be presented as application-only.
3. Retain the full original contract and defer strength controls until an
   application-specific blur mechanism is available and verified.

A read-only native capability check is also needed. No operator script is supplied
or required in this pass. Do not infer approval to modify the live session from
this report.

## Installed environment and evidence

`hyprctl version` and `hyprctl getoption decoration:blur:enabled` both failed:
`Couldn't set socket timeout (2)`. `hyprctl instances` produced no instances.
The inherited instance directory contains lock/log files; no IPC sockets were
visible. Therefore actual running version, current option values, runtime rules
and event delivery are not claimed as verified.

`Hyprland --version` reports installed **0.56.2**, branch/tag `v0.56.2`, commit
`efb50993780079460b0cbed1363e2166a2de1d9f`, clean, build date 2026-08-05.
Installed `/usr/share/hypr/stubs/hl.meta.lua` describes Lua `hl.config`,
`hl.window_rule`, `hl.layer_rule`, `hl.get_config`, named rule handles and
`config.reloaded` subscriptions. `hyprctl --help` lists `eval`, `repl`,
`getoption`, `getprop`, `configerrors`, and `reload [config-only]`.
These establish interfaces, not successful runtime behavior.

All following upstream source links are pinned to the installed commit, inspected
on the date above. No code was copied into MAGI. Current wiki text was consulted
only as secondary guidance; one page has contradictory named-rule precedence
wording, so that wording is not adopted as an implementation guarantee.

| Source | Verified finding and relevance | Remaining validation |
| --- | --- | --- |
| [Config values](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/config/values/ConfigValues.cpp) | Active/inactive/fullscreen opacity defaults are 1, bounds 0–1. Blur enabled defaults true; size default 8, accepted 0–100; passes default 1, accepted 0–10. Popup/input-method blur defaults false. | Actual runtime values unavailable. |
| [OpenGL renderer](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/render/OpenGL.cpp) | Shared framebuffer blur reads global size/passes; damage calculation clamps size to 1–40 and pass loop clamps passes to 1–8. Configuration bounds and effective renderer behavior differ. | No claim of compositor-equivalent preview or surface isolation. |
| [Surface pass](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/render/pass/SurfacePassElement.cpp) | Blur need depends on surface texture opacity and combined alpha; both window and layer paths use the blur machinery. | Opaque application content must not be promised visible background blur. |
| [Rule bindings](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/config/lua/bindings/LuaBindingsConfigRules.cpp) | `hlWindowRule` reuses an existing named object, otherwise registers one. Updates register supplied matches/effects; they are not a demonstrated replace-all operation. | Omitted-field clearing and failed update behavior need fixtures. |
| [Rule handle](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/config/lua/objects/LuaWindowRule.cpp) | Exposes `set_enabled` and `is_enabled`; disabling updates rules. No removal method exposed here. | A disabled retained object is not physical deletion. |
| [Rule engine](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/desktop/rule/Engine.cpp) | Internal unregister-by-name exists. Its existence does not establish an external IPC/Lua removal API. | Do not invent a runtime remove command. |
| [Rule applicator](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/desktop/rule/windowRule/WindowRuleApplicator.cpp) | Dynamic refresh resets applicable properties and iterates registered rules. No CSS-like specificity ranking is established. | Test exact ordering with named/anonymous, broad/specific, and disabled rules before making coexistence claims. |
| [Lua manager](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/config/lua/ConfigManager.cpp) | Reload syntax-checks, then reinitializes Lua and resets config values before executing configuration. A later runtime error can still fail. | A reload is not an atomic transaction with automatic rollback. |
| [Effect descriptors](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/config/lua/bindings/LuaBindingsInternal.hpp) | Per-client opacity and blur exclusion exist; no per-client size/passes descriptor. | Match/exclusion semantics require exact-version fixture coverage. |

## Current operator configuration and conflicts

Read-only audit of main `linux/t15g/hypr/.config/hypr/hyprland.lua`:

- No explicit active/inactive/fullscreen opacity or opacity rule found.
  Default 1 is a source/config inference, not runtime readback.
- Blur enabled, size 8, passes 4, ignore_opacity true, new_optimizations true,
  xray false, brightness 0.90, contrast 0.92, noise 0.015, vibrancy 0.15,
  vibrancy_darkness 0.50. All remain operator-owned.
- Two named window rules: `magi-settings-window` and `magi-clipboard-window`,
  matching Quickshell class and stable title; effects float/center/size only.
- No broad/app-specific opacity, `no_blur`/`noblur`, game/media/XWayland,
  special-workspace, fullscreen, dialog or picture-in-picture visual rules found.
  This does not rule out runtime rules or future additions.
- `hl.on("hyprland.start", ...)` starts session components including MAGI.
  Super+Shift+R invokes compositor reload. No custom config-reloaded hook found.
- Final theme `dofile` loads generated `colors.lua`; its current content sets
  active/inactive border colors only. Final `require("hyprmon")` loads a
  monitor-only profile. Both includes were read; neither was modified.

| Existing authority | Expected interaction | Safe coexistence requirement |
| --- | --- | --- |
| Operator global blur | Changing size/passes affects every surface using shared blur | Preserve it unless broader ownership is explicitly accepted. |
| MAGI Settings/Clipboard geometry rules | Broad client opacity would also match normal Quickshell windows | Exclude shell clients; do not add neutral overriding rules to them. |
| Theme Orchestrator border colors | Separate properties, no necessary conflict | Keep adapter and generated palette border-only. |
| Future app-specific opacity/no_blur | Specificity alone does not ensure priority | Establish source/order contract and test it; no late broad runtime assertion. |
| Fullscreen/game/video/PiP | No local exception exists | Audit explicit fullscreen opacity and mapped versus popup surfaces before choosing policy; no silent exception. |

Dialogs represented as independent client windows need matching like other clients.
Wayland popup surfaces are a different rendering path; popup blur has a separate
global option. Neither inheritance nor fullscreen behavior was tested natively.
No popup editor, game exception or per-app editor is introduced.

## Architecture disposition

No activation architecture is selected or certified reversible yet.

- Append-only runtime rules: rejected. Fixed names support updates, but the
  external handle has no removal API; enabling/disabling and restoring shared
  global values still require lifecycle/ownership proofs.
- Reasserting global opacity: rejected because it also changes excluded ordinary
  shell windows and does not provide clean authority release by itself.
- Generated Lua plus bootstrap: promising alternative for a later reviewed design.
  Full configuration reconstruction can remove omitted MAGI rules; runtime
  execution errors and side effects require preflight, readback and rollback.
  It does not solve global blur coupling.
- Snapshot-and-restore shared options alone: insufficient; restoring a stale
  snapshot can overwrite an operator change or a newly reloaded configuration.

No bootstrap hunk is proposed: selecting a precise insertion point and precedence
contract before resolving these gates would imply an architecture not yet approved.
No copied-fixture bootstrap test is claimed. Live dirty Lua remains untouched.

If work resumes, generated state belongs under
`$XDG_STATE_HOME/magi/window-appearance/` (fallback `~/.local/state`), outside Stow.
Desired normalized policy, deterministic planner and executor must stay separate.
The service must validate, preflight, snapshot known-good, apply, read back, then
publish; failure must attempt rollback and expose rollback failure. Desired state
survives IPC loss. Startup/restart/reload use bounded idempotent reconciliation.
These are requirements, not implemented or tested results.

Future `Windows → App Rules` can extend the planner once precedence is proven.
It should remain separate from Theme Orchestrator and any Phase 12H activation
coordinator; palette activation must never implicitly acquire window authority.

## Product and schema disposition

No first-class Windows page, preview gallery, service, planner, executor or tests
were added because the architecture gate stopped implementation. All requested
management, reset, independent percentage sliders, blur controls, statuses,
keyboard accessibility, compact layout and six-theme captures remain pending.

Schema remains **18**. The copied operator fixture reports `schemaVersion: 18`.
No migration ran. If implementation proceeds, add schema 19 once with neutral
`managed: false`, active/inactive 1 and blur disabled. A proposed 30–100% opacity
UI bound would avoid effectively invisible clients, but is not an accepted or
implemented bound. Blur UI bounds remain undecided; do not confuse accepted
config limits with effective rendering clamps.

## Validation and inventory

Passed: baseline identity/divergence, isolated worktree creation, local grammar
inspection, operator/config include audit, exact-build source inspection,
settings schema read, final protected-state comparison, empty indexes and
`git diff --check`.

Not run: Phase 12G policy/planner/service/failure injection, migration/persistence,
Settings presentation/navigation, 12C–12F, Theme Orchestrator and runtime visual
suites. No executable code changed; this is an audit stop, not a tested feature.
Enable/change/disable/rollback/startup/restart/reload/IPC-loss acceptance remains
unproven. No preview captures or generated runtime files exist for this phase.

Exact worktree inventory: **4 documentation paths**:

- `linux/magi/docs/design/phase12g-window-visuals.md` (this audit).
- `linux/magi/docs/README.md` (checkpoint index).
- `linux/magi/docs/architecture.md` (pending ownership gate).
- `linux/magi/docs/decisions.md` (stop decision).

Settings UI: 0; service: 0; policy: 0; planner: 0; executor: 0; schema: 0;
tests: 0; previews: 0; proposed bootstrap artifacts: 0. No index entries added.

Next acceptance must first settle blur scope, then prove exact-version rule
precedence, release and reload semantics with isolated fixtures/fake execution.
Only after implementation and review should native acceptance exercise real
applications, shell invariance, reload, failure/rollback and concurrent operator
changes. No native mutation is authorized by this document.
# Native blur investigation — 24 October 2026

Native acceptance remains pending. The operator demonstrated sharp wallpaper at
85% background opacity with blur enabled. Authoritative readback: enabled=true,
size=8, passes=4, new_optimizations=true, ignore_opacity=true; MAGI exclusion=false.
Installed packages: Ghostty 1.3.1-2, GTK4 1:4.24.1-1.

The original blur-allow plan was incomplete for this combination. GTK creates an
ext-background-effect object; Hyprland honours that object's blur region, including
an empty region. Merely disabling a no-blur rule cannot supply a missing request.
This is a source-supported diagnosis; visual confirmation of the remedy is pending.

The sole Ghostty adapter now publishes `background-blur.css` alongside its palette
while managed, referenced with Ghostty's repeatable `gtk-custom-css` option:

```css
window.window { backdrop-filter: blur(20px); }
```

The installed Ghostty resource identifies its main window with CSS class `window`.
The provider loads inside Ghostty only, never through GTK user/system CSS. It changes
no background colour, foreground, opacity, or other application's styling. On this
pinned Hyprland protocol, only the blur region is conveyed: CSS radius is not a
global blur-strength write. Hyprland retains size=8/passes=4. The request stays
constant across blur toggles; the immutable Ghostty-only no-blur rule gates it.
Management disable removes both CSS reference and generated CSS from the current
generation; Ghostty reload unloads the old provider and restores operator behaviour.
The same atomic publication and rollback journal cover both generated files.

Verified sources (inspected 2026-10-24):
- [GTK 4.24.1 surface creation](https://github.com/GNOME/gtk/blob/4.24.1/gdk/wayland/gdksurface-wayland.c), `gdk_wayland_surface_create_wl_surface`: creates background-effect object.
- [Hyprland pinned renderer](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/render/Renderer.cpp), `shouldBlur(PHLWINDOW)`: honours empty/nonempty client region after exclusions.
- [Hyprland background-effect protocol](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/protocols/BackgroundEffect.cpp): region-only request, no radius.
- [Ghostty 1.3.1 application](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/apprt/gtk/class/application.zig), `loadCustomCss`/`propConfig`: removes old providers and reloads custom CSS on config change.
- [Ghostty native protocol support](https://github.com/ghostty-org/ghostty/issues/10721) is tracked for 1.4.0; no package upgrade is attempted here.

Focused validation: 24 Phase12G tests pass, including installed GTK CSS parsing,
stable CSS across blur toggles, palette isolation, release and transaction rollback.
Native four-state validation must be repeated after Ghostty reload; no success claim
is inferred from generated output or rule readback alone.


## Native global blur acceptance — 24 October 2026

Operator confirmed that the global amount control works and that turning customization
off restores the original amount 8. Subsequent read-only ownership inspection shows
management re-enabled at size 12 with the correctly retained baseline 8; this is not
a restore failure. Current saved application policy is managed, background alpha 0.72,
blur allowed, theme Catppuccin Frappé. These are observations, not a request to overwrite
operator preferences. Index remains empty and HEAD remains the accepted 12F baseline.

Ghostty blur has separate explicit visual confirmation after the threshold fix. Full
four-state/foreground/coloured-cell acceptance, application disable/reset restoration,
theme composition and final overall acceptance are still pending explicit confirmation.
No completion or commit is claimed from the global-control acceptance alone.
