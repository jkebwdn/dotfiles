# Control Centre actions and icon packs

Status: **implemented and operator-accepted, 2026-09-28**.

## Catalogue and configuration

`modules/ControlCatalog.qml` is the single presentation catalogue. Entries
declare stable ID, semantic icon role, availability/state adapters, supported
forms (`tile`, `action`, `slider`, `detail`), actions, optional detail
navigation and danger/confirmation metadata. Schema v3 stores ordered primary
`controls`, dedicated `sliders`, ordered secondary `actions`, and separate
column counts. Visibility remains independent of service and detail ownership.

The v3 defaults are:

- primary: Wi-Fi, Bluetooth, Low Power, Airplane Mode;
- sliders: Volume, Brightness;
- secondary: VPN, DND, Caffeine, Lock, Hibernate, Shutdown.

The v2 four-control built-in set migrates to the new primary default even if it
was reordered during earlier Settings testing. Other v2 documents retain their
raw user entries; unsupported old presentations are excluded from the safe
effective model rather than executed.

## Backend semantics

- **Low Power:** `services/system_actions.py` prefers
  `powerprofilesctl`, then a writable Linux `platform_profile`. This machine
  exposes `low-power balanced performance` but the control is read-only to the
  user, and power-profiles-daemon is absent, so the tile is unavailable. During
  one shell session MAGI remembers the prior normal profile.
- **Airplane Mode:** `AirplaneMode.qml` uses the existing Network and
  Bluetooth services. It records and disables the two radio states, then
  restores only radios previously enabled. An external radio enable exits the
  remembered Airplane state. This is a MAGI aggregate state, not privileged
  rfkill; a shell restart does not retain its restoration snapshot.
- **VPN:** the adapter reads NetworkManager profiles through argument-vector
  `nmcli`, selects an active profile first and otherwise the first configured
  VPN/WireGuard profile, and stores no credentials. This machine has no such
  profile, so the action reports unavailable.
- **DND:** a replaceable adapter targets the detected SwayNotificationCenter
  interface (`swaync-client -D/-dn/-df`) and polls for external changes.
- **Caffeine:** one Quickshell Wayland `IdleInhibitor` belongs to the existing
  bar window. It does not kill or restart Hypridle.
- **Lock:** uses `loginctl lock-session`. **Hibernate** and **Shutdown** use
  `systemctl hibernate/poweroff` only after a second activation within five
  seconds. Tests use a dry-run boundary and never invoke these actions.

## Icon packs

The [icon-pack contract](../design/icon-pack-contract.md) defines the canonical
24×24 UI canvas, manifest and safe SVG subset. `AssetManager` validates and
copies a local pack to XDG managed storage. `IconRegistry` loads managed
manifests without QML changes and resolves missing roles through the declared
parent and then MAGI Legacy. Individual overrides still win.

The new semantic roles use MAGI Legacy fallback glyphs. No custom first-party
SVG artwork is claimed or synthesized.

## Validation and acceptance

Focused tests pass for schema migration/filtering/order, open-surface geometry
retargeting, backend state boundaries, Airplane transitions, Caffeine state,
unavailable DND/VPN, destructive arming, canonical SVG checks, manifest
installation and incomplete-pack fallback. All prior settings, appearance,
module ownership, media, Settings-window and 48-step lifecycle suites pass.
`qmllint` exits successfully with the repository's known Quickshell metadata
warnings; `git diff --check` passes.

Runtime PID 326388 owns one 1920×1080 Quickshell layer at output-local `(0,0)`
with monitor reservation `[0,48,0,0]`. Schema v2 migrated and persisted as v3
through the single SettingsStore writer; theme, radii, bar, profile/avatar,
media and icon settings were preserved, a migration backup exists, and the
store reports saved with no diagnostics. Logs contain only startup/configuration
messages.

Operator-observed passes:

- four primary controls and six secondary actions appear;
- Low Power and VPN honestly appear unavailable;
- SwayNC DND changes state, then returns to off;
- Caffeine shows its active indication;
- disabling/re-enabling a secondary action updates correctly;
- the destructive power action's first click arms without executing;
- Bluetooth, sliders, media, profile and the existing shell behavior show no
  observed regressions.

Airplane Mode was not toggled in the live session to preserve the active remote
connection. Its state transitions have mocked service-boundary coverage only.
Caffeine's compositor idle effect was not held through a full idle timeout.
The local login1 check reports Hibernate unavailable (consistent with the
operator's no-swap system) and Shutdown available; no destructive second click
was performed. Multi-output and fractional-scale behavior remain untested.
