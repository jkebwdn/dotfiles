# Phase 14B — Audio routing and Tray behaviour

Baseline: `fcb29af4262d22ec566784839e95a3a0df733dda` (`magi: fix bluetooth device pairing`),
verified synchronized with origin/main. Implementation and native review took
place on 27 October 2026 in `/home/jkebwdn/magi-phase14b`, then through an exact
runtime allowlist in the live checkout. Final schema: **22**.

## Audit evidence

Installed versions: Quickshell 0.3.2, PipeWire 1.6.10, WirePlumber 0.5.18.
Inspected the installed PipeWire qmltypes under
`/usr/lib/qt6/qml/Quickshell/Services/Pipewire/` on 2026-10-27. It exposes:

- read-only defaultAudioSink/defaultAudioSource and writable
  preferredDefaultAudioSink/preferredDefaultAudioSource;
- nodes ObjectModel, node.ready, audio, type, isStream/isSink, properties,
  description, nickname, name, id;
- writable audio.volume/audio.muted and channel volumes;
- PwObjectTracker, required to bind metadata/controls. No peak monitor is used.

[Quickshell v0.3.2 qml.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/services/pipewire/qml.cpp)
confirms preferred-default setters delegate to its default tracker. The
[PwNode reference](https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Pipewire/PwNode/)
explains application.name/icon-name/media.name metadata, tracker requirements,
ready and direction semantics. The v0.3.0 documentation is checked against the
installed 0.3.2 metadata rather than assumed identical. No third-party source or
artwork was copied. All new implementation is original.

Installed WirePlumber scripts inspected:
`default-nodes/find-selected-default-node.lua`, `state-default-nodes.lua`,
`find-best-default-node.lua`, `apply-default-node.lua`, and `linking/prepare-link.lua`.
Configured selection gets priority above remembered history, then best available
policy applies. On disappearance the session manager selects a fallback. A default
change can move streams following that default; streams with explicit remembered
routing remain subject to WirePlumber policy. MAGI must not force every stream's
links or erase saved targets.

Host read-only audit supplied by operator:

- Super+A and Super+T: no active bindings, including modified variants.
- node.restore-default-targets, linking.follow-default-target,
  node.stream.restore-target and bluetooth.autoswitch-to-headset-profile are true.
- Bluetooth sink is present, but built-in output remains actual default. The
  configured default names a different, currently unavailable Bluetooth sink.
  This is evidence that arrival does not unconditionally select the new speaker.
- Speaker's active Profile parameter: `a2dp-sink`, High Fidelity Playback,
  codec SBC, available yes. Sink api.bluez5.profile also says a2dp-sink. The
  device's bluez5.profile property says off, so it is not used as the active-profile
  authority. No profile write is made.
- A Bluetooth Midi/Bridge node also exists: device.api=bluez5 alone is not an
  audio-device classification rule.

Host identifiers, addresses and application names are deliberately omitted from
captures and this record. The helper commands were read-only diagnostics, not a
production wpctl/pactl backend.

## Audio implementation

One shared AudioModel normalizes Quickshell PipeWire state; Audio.qml provides the
single native adapter. PwObjectTracker keeps audio metadata and writable controls
bound. Ready nodes are classified strictly by media.class: Audio/Sink,
Audio/Source and Stream/Output/Audio. No polling or shell-command routing backend.

Output/input dropdowns express user intent through preferredDefaultAudioSink and
preferredDefaultAudioSource. The actual default drives volume, mute and selected
state. Duplicate pending selections are guarded; a five-second timeout reports an
unconfirmed selection without retry storms. On disappearance WirePlumber chooses
the fallback. MAGI does not rewrite links, profiles or remembered routes.

Auto-switch is deliberately deferred: node arrival alone cannot distinguish an
intentional Bluetooth connection from restart/profile recreation. No arrival,
initialization or reload event changes routing. The operator approved this policy.
Bluetooth pairing and audio routing remain separate services.

Application rows group streams by application.id, then application.process.binary,
then application.name. Track titles and PIDs are not grouping keys. Unidentified
streams remain separate rather than combining unrelated playback. A group shows
the highest current member volume; moving its slider assigns the chosen volume
to every current member. Group mute mutes all members, or unmutes all if all were
muted. No implicit write occurs when a stream arrives. Removed members are
filtered before dispatch. Other applications and hardware master volume remain
unchanged. Application artwork stays untinted and system-owned.

Output, input and application sliders share RenderTokens.sliderHeight and the
existing IconSlider. The optional slider-icon action toggles mute and supports
keyboard/accessibility without changing volume. The normal adjustment range stays
0–100%; no amplification setting, MPRIS transport, microphone meter or recording.

Output and Input blocks sit together above Applications. Both use the same themed
dropdown. There is no redundant Audio heading, percentage text, separate mute
chip or per-stream track-title clutter. Audio measures content height and adds
normal menu padding, bounded by screen height and 560px; long lists scroll.
Input controls use the same supported preferred-default and audio APIs.

Settings → Bar → Appearance → Volume exposes **Audio menu**, with the same
SurfaceStyleSettings used for Wi-Fi/Bluetooth: border enable, shared colour/width,
and shared surface roundness. `appearance.surfaceBorders.volume` defaults false,
so enabling this capability does not alter the current appearance.

## Entry points and output routing

- Volume left-click opens/toggles Audio; right-click toggles default-output mute.
- Wheel retains five-percent output-volume adjustment.
- Super+A uses `quickshell ipc -c magi call magi toggle audio`.
- Existing composition identity `volume` is preserved; IPC `audio` maps to it.
- Audio follows originating-output/focused-enabled-output routing, with existing
  fallback semantics. It uses the shared expanded-surface family and dismissal.
- Super+T uses `quickshell ipc -c magi call magi toggle tray`.

Source and host bindings were audited before assignment. The final host check
finds one Super+A/T binding each. Hyprland's Lua dispatcher exposes numeric
callback IDs (`__lua`), so the helper verifies approved source independently;
operator interaction confirms the actual actions. No unrelated bind is replaced.

## Final Tray policy

Bar Layout alone defines default Tray placement. There are no Always/When-items/
Hidden options. Super+T toggles **icons directly in the Bar**, not a menu:

- Placed Tray hides/shows in its existing region.
- Unplaced Tray appears temporarily at the right of the main-output status area,
  then disappears on the next press.
- The override belongs to the shared runtime Tray model, survives output
  presentation replacement, and is never written to Settings.
- A normal MAGI reload returns to saved layout defaults. Empty trays occupy no
  space. Hosting continues regardless of presentation.

The overflow button remains available for excess icons. Its icon-only surface
has compact cells following shared statusIconSize/bar metrics, eight-pixel outer
padding, four-pixel gaps, bounded width and 300px scrolling height. It grows and
shrinks with items. Scrollbar input is disabled when content fits, preventing a
fading scrollbar from covering icons after shrink. Tooltips/accessibility retain
application identity; application artwork is never tinted.

Sticky highlight was caused by pointer activation forcing keyboard focus and then
using activeFocus as selected fill. Fill now follows actual menu visibility,
pointer press and hover; keyboard focus is a separate ring. Left activation
clears pressed fill on release. Native menu close, item removal and reload clear
menu state. NeedsAttention remains a separate dot. Native menus remain native.
StatusNotifier/AppIndicator support is retained; legacy XEmbed remains unsupported.

## Bluetooth presentation

At the operator's request, the existing menu now places paired/bonded devices
contiguously before unpaired discoveries, preserving order within each group.
Connected-device presentation remains first. Native adapter.devices is a
Quickshell ObjectModel; its reactive values array is normalized for presentation.
Pairing, trust, Agent1 authentication, connect/disconnect and discovery are unchanged.
No Bluetooth backend or launcher-lifecycle source is modified by this phase.

## Schema and preservation

Schema remains 22, already introduced during native review. Migration from 21
changes the version without changing Bar layout. The superseded native-preview
`bar.trayVisibility` field is removed during migration and is absent from both
final saved and runtime state. The Audio border flag is an additive neutral default
in the existing style group. There is no persisted Tray override, runtime item
list, stream state or auto-switch preference.

Operator Settings remain unstaged. Shared Bar/lock layout, theme/transparency,
local dotfiles, Yazi symlink, battery artwork and generated state are protected.
Only the approved A/T lines are eligible for the Hyprland commit; pre-existing local
theme/hyprmon additions remain in the working tree and outside the index.

## Validation

Final matrix: 22 passing commands covering Phase14B, Bluetooth actions/authentication,
Phase14A, Phase12C, Phase10B, Settings/store/presentation, Phase12D, Phase12F,
Phase12G/H and their presentations, Phase13A/B and their presentations, Control
Centre ownership, launcher backend/presentation/lifecycle and runtime visuals.
`git diff --check` also passes.

The runtime-visual harness initially reached native TrayService after the new
shared override dependency. It now substitutes the same synthetic TrayModel as
other harnesses; the rerun passes without weakening warning checks. Final preview
capture uses QtTest window capture so dropdown overlays are included.

Launcher evidence: the old path reproduces delayed EPIPE; detached launches survive
Hub closure, LauncherContent destruction, hard reload and shell exit. A write at
**127.3 seconds** completed without broken pipe. Launcher production source is
unchanged from the accepted baseline.

Synthetic tests additionally cover grouped app isolation/metadata/removal, input
selection, icon mute without volume changes, equal slider heights, measured menu
height, content limits, runtime Tray toggling without layout writes, main-output
routing, icon sizes16/22/28, growth/shrink and large-item scrolling, pointer/menu
highlight lifecycle, paired/bonded ordering and Audio appearance controls.

[Deterministic preview gallery](previews/phase14b/index.html) contains synthetic
identities only, including Dawn, dropdown, compact, muted and Tray interaction
states. Software rendering is not native application-icon quality evidence.

## Native acceptance evidence

The operator previously confirmed speaker routing, independent app/input controls,
tray clicks and both tray applications, inline Super+T behaviour and reload survival.
The final host gate reconfirmed active non-conflicting A/T bindings, schema22 and
absence of the retired field. Toggling Tray twice changed neither runtime Settings
nor the saved file.

One normal reload ran in the same MAGI process at **14:21:11.711 → 14:21:12.005**.
Before/after native snapshots match default sink/source, endpoint/stream volume
and mute, stream identities, Steam/Mullvad process identities and two tray
registrations. Settings was not written during reload. The helper's final IPC read
briefly returned empty; a bounded-retry, read-only resume completed successfully.
Its guard prevented a second reload when invoked again.

Physical multi-monitor acceptance remains deferred (one display); synthetic
origin/focus/main-output/hotplug coverage passes. Real NeedsAttention and large
natural tray counts use synthetic coverage rather than installing applications.

Final operator acceptance recorded: **“All native checks pass—finalize.”** This
includes final Audio routing/input/grouped volume/mute/appearance checks, Tray
inline toggle/sizing/menu states and Mullvad/Steam, Bluetooth ordering/actions,
and no unexpected window/menu, audio change or EPIPE after reload.

## Exact final inventory

62 paths: 22 A, 40 M, 0 D.

| Status | Path |
| --- | --- |
| M | `linux/magi/.config/quickshell/magi/components/bar/Bar.qml` |
| M | `linux/magi/.config/quickshell/magi/components/controls/IconSlider.qml` |
| M | `linux/magi/.config/quickshell/magi/components/settings/BarInspector.qml` |
| M | `linux/magi/.config/quickshell/magi/components/settings/pages/BarPage.qml` |
| M | `linux/magi/.config/quickshell/magi/components/tray/TrayGroup.qml` |
| M | `linux/magi/.config/quickshell/magi/components/tray/TrayItem.qml` |
| M | `linux/magi/.config/quickshell/magi/components/tray/TrayOverflow.qml` |
| M | `linux/magi/.config/quickshell/magi/plugins/bar/bluetooth/Bluetooth.qml` |
| M | `linux/magi/.config/quickshell/magi/plugins/bar/volume/Volume.qml` |
| M | `linux/magi/.config/quickshell/magi/services/Audio.qml` |
| M | `linux/magi/.config/quickshell/magi/services/TrayModel.qml` |
| M | `linux/magi/.config/quickshell/magi/services/qmldir` |
| M | `linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js` |
| M | `linux/magi/.config/quickshell/magi/settings/SettingsSchema.js` |
| M | `linux/magi/docs/README.md` |
| M | `linux/magi/docs/architecture.md` |
| M | `linux/magi/docs/decisions.md` |
| M | `linux/magi/docs/quickshell-reference.md` |
| M | `linux/magi/tests/bluetooth/presentation.qml` |
| M | `linux/magi/tests/phase10b/lifecycle.qml` |
| M | `linux/magi/tests/phase10b/run.py` |
| M | `linux/magi/tests/phase12c/presentation.qml` |
| M | `linux/magi/tests/phase12c/schema.cjs` |
| M | `linux/magi/tests/phase12d/schema.cjs` |
| M | `linux/magi/tests/phase12f/presentation.qml` |
| M | `linux/magi/tests/phase12g/presentation.qml` |
| M | `linux/magi/tests/phase12g/schema.cjs` |
| M | `linux/magi/tests/phase12h/presentation.qml` |
| M | `linux/magi/tests/phase13a/model.cjs` |
| M | `linux/magi/tests/phase13a/presentation.qml` |
| M | `linux/magi/tests/phase13b/model.cjs` |
| M | `linux/magi/tests/phase13b/presentation.qml` |
| M | `linux/magi/tests/phase14a/model.cjs` |
| M | `linux/magi/tests/runtime-visual/run.py` |
| M | `linux/magi/tests/settings/expected18.cjs` |
| M | `linux/magi/tests/settings/modules.py` |
| M | `linux/magi/tests/settings/run.py` |
| M | `linux/magi/tests/settings/schema.cjs` |
| M | `linux/magi/tests/settings/store.qml` |
| M | `linux/t15g/hypr/.config/hypr/hyprland.lua` |
| A | `linux/magi/.config/quickshell/magi/components/audio/AudioDeviceSelector.qml` |
| A | `linux/magi/.config/quickshell/magi/components/audio/AudioLevel.qml` |
| A | `linux/magi/.config/quickshell/magi/components/audio/AudioSurface.qml` |
| A | `linux/magi/.config/quickshell/magi/services/AudioModel.qml` |
| A | `linux/magi/docs/design/phase14b-audio-tray-behaviour.md` |
| A | `linux/magi/docs/design/previews/phase14b/audio-bluetooth.png` |
| A | `linux/magi/docs/design/previews/phase14b/audio-compact.png` |
| A | `linux/magi/docs/design/previews/phase14b/audio-dawn.png` |
| A | `linux/magi/docs/design/previews/phase14b/audio-input-and-streams.png` |
| A | `linux/magi/docs/design/previews/phase14b/audio-muted.png` |
| A | `linux/magi/docs/design/previews/phase14b/audio-output-dropdown.png` |
| A | `linux/magi/docs/design/previews/phase14b/index.html` |
| A | `linux/magi/docs/design/previews/phase14b/tray-attention.png` |
| A | `linux/magi/docs/design/previews/phase14b/tray-dawn.png` |
| A | `linux/magi/docs/design/previews/phase14b/tray-empty.png` |
| A | `linux/magi/docs/design/previews/phase14b/tray-inline.png` |
| A | `linux/magi/docs/design/previews/phase14b/tray-menu-open.png` |
| A | `linux/magi/docs/design/previews/phase14b/tray-overflow.png` |
| A | `linux/magi/docs/design/previews/phase14b/tray-post-activation.png` |
| A | `linux/magi/tests/phase14b/presentation.qml` |
| A | `linux/magi/tests/phase14b/run.py` |
| A | `linux/magi/tests/phase14b/schema.cjs` |
