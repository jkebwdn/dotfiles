# Bluetooth device pairing — natively accepted, 2026-10-27

Baseline: `da296e64ffcc21e4d19d67a4349e9444a285acc7` (`magi: add system tray`),
verified synchronized with origin/main. Settings schema remains 21. Native acceptance was confirmed by the operator after live testing. The operator's immediate target is a speaker
that normally requires no PIN; the operator also requested authentication support
for future devices. No claim is made that every Bluetooth profile/device is supported.

## Verified bug and API boundary

The production menu hid its action chip unless connected, paired or bonded; the
row itself had only a HoverHandler. The service's toggleConnection also had no
unpaired branch. This explains the silent no-op without invoking a BlueZ failure.
Known-device connection/disconnection worked through Quickshell's Device1 calls.
Quickshell tracked connecting/disconnecting, but MAGI did not expose failures or
pairing progress. No MAGI Forget action was present; Quickshell's forget API is
unchanged, and selecting a device after an external forget now starts pairing.

Installed `/usr/lib/qt6/qml/Quickshell/Bluetooth/quickshell-bluetooth.qmltypes`
(Quickshell 0.3.2, inspected 2026-10-27) exposes paired, bonded, pairing, connected,
state, writable trusted, dbusPath, pair(), cancelPair(), connect(), disconnect(),
forget(). Pairing is separate from the four-state connection enum. It exposes no
Agent1 challenges or structured error results. MAGI had no authentication agent.
The sandbox could not inspect the real system bus; this is not evidence that the
host has no external default agent.

Research inspected 2026-10-27:

- [Quickshell v0.3.2 device.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/bluetooth/device.cpp):
  pair() invokes asynchronous Device1.Pair, toggles pairing and logs errors; it does
  not explicitly trust/connect. connect/disconnect invoke the corresponding BlueZ
  methods and guard their own transitions. This makes property-only error reporting
  insufficient for an accurate MAGI failure message.
- [Quickshell v0.3.2 bluez.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/bluetooth/bluez.cpp)
  and [module sources](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/bluetooth/CMakeLists.txt):
  BlueZ object-model tracking, no agent registration in this module.
- [BlueZ Device API](https://bluez.readthedocs.io/en/latest/device-api/): Pair uses an
  application agent or the default agent and fails without either. Pair establishes
  a low-level connection and retrieves services, so an early Connected signal is
  not sufficient proof of completed pairing. Trusted is writable. Disconnect can
  cancel an outstanding Connect. Live BlueZ package: 5.87-2.
- [BlueZ Agent API](https://bluez.readthedocs.io/en/latest/agent-api/): an application
  agent handles actions from its bus connection; KeyboardDisplay supports the
  requested interaction modes. NoInputNoOutput or automatically accepting every
  confirmation would not satisfy the operator's future-device requirement.
- [GIO object registration](https://docs.gtk.org/gio/method.DBusConnection.register_object.html)
  and [asynchronous calls](https://docs.gtk.org/gio/method.DBusConnection.call.html):
  typed object export, asynchronous reply/error handling and finite call timeouts.
  API 2.0, methods available since 2.26. Python GI is already installed. No external
  implementation or artwork was copied; this implementation is original.

## Architecture and policy

`Bluetooth.qml` retains Quickshell's authoritative adapter/device model. One
on-demand Python/GIO backend runs a shared action coordinator and a private
system-bus connection. Agent registration and Pair originate from that **same**
connection. MAGI never requests default-agent status and does not replace another
desktop's agent. No helper starts merely because a menu is rendered or MAGI reloads.

Device identity is dbusPath, never name. One deliberate operation is active at a
time; repeated clicks and other-device clicks cannot retarget it. QML additionally
guards Quickshell pairing/connecting/disconnecting states. Backend checks fresh
BlueZ state before acting. No polling, shell commands or bluetoothctl parsing.

- Unpaired: register application-scoped KeyboardDisplay agent, Pair exactly once.
- Successful asynchronous Pair reply: write Trusted=true, then read current state.
  If still disconnected, Connect once; if already connected, do not duplicate it.
- Paired/bonded disconnected: Connect. Connected: Disconnect.
- Failures become compact, retryable messages. Pair rejection, cancellation,
  timeout, operation-in-progress, service/adapter/device loss are distinguished.
  Failed post-pair Connect never forgets or untrusts the device.
- Pair timeout is 120 seconds; Connect/Disconnect 45 seconds; property/agent calls
  15 seconds. Service startup has a 10-second QML deadline. These are bounded
  asynchronous operations, not periodic scans or retries.
- Removal/power-off cancels intent; late callbacks cannot advance an old operation.
  Closing the menu cancels pairing or outstanding authentication. Closing helper
  stdin or terminating it closes its private bus connection and drops the agent.
- A selected device's authentication requests can be shown during Pair or Connect.
  Authentication for unrelated devices and non-BlueZ callers is rejected. Connection
  cancellation uses Device1.Disconnect; pairing cancellation uses CancelPairing.

Agent1 implements RequestPinCode, DisplayPinCode, RequestPasskey, DisplayPasskey,
RequestConfirmation, RequestAuthorization, AuthorizeService, Cancel and Release.
Only the current BlueZ unique bus owner may invoke it. Requests remain associated
with the active device and monotonically numbered prompt. Stale responses cannot
approve a later prompt. PIN/passkey entry is validated; numeric display retains
leading zeroes. Codes and answers exist only in transient IPC/memory, are not logged
or saved, and are cleared on completion/cancel. Prompts render plain text. There is
no blanket auto-authorization and no incoming/global pairing-agent policy.

The existing expanded menu, icons and transparency system are retained. Pair and
Connect chips plus row pointer/keyboard activation use the same service path.
State appears in row accessibility text. An inline authentication body replaces
the list while a request needs attention; Cancel/Escape remains available.

Discovery was manual Scan/Stop with no menu-close or time limit. The focused
lifecycle correction stops MAGI-started discovery on close or after 30 seconds;
an already-active scan that MAGI did not initiate is not stopped on close.

## Evidence and native acceptance

- Production coordinator: 17 deterministic tests pass. Includes pair/connect call
  counts, automatic connection, rejection/timeouts/in-progress, connection retry,
  forgetting, duplicates, identity, cancellation, adapter loss and stale callbacks.
- Production QML menu/service fixture: pointer and keyboard selection, all prompt
  presentations, validated entry, state guards, retry and owned-discovery cleanup
  pass. Transport and adapter inputs are replaced only in a disposable copy.
- Private D-Bus fake-BlueZ integration: operator ran `tests/bluetooth/bus.py` on the
  host and reported PASS. Validates actual GIO serialization, same-owner agent
  routing, confirmation/PIN/passkey replies, trust/connect, rejection, caller
  isolation and device removal. Sandbox socket binding is denied; that limitation
  is not hidden by a skipped-success result.
- Control Centre/module ownership, Settings/schema/presentation, Phase12D,
  Phase12F, Phase12G/backend/presentation and runtime visuals pass. Phase12D's
  stale schema19 assertion was corrected to the existing production schema21;
  no production schema/migration change was made.
- Operator confirmed Settings saved. Exactly five runtime files were integrated;
  MAGI instance u0417bcknt (PID 51870) reloaded at 11:56:10 without errors.
  Protected settings remained byte-identical and the index stayed empty. The
  operator reran the private-bus test and reported PASS again.
- After being asked to test speaker pairing/reconnection and already-paired-device
  connect/disconnect/reconnect, the operator confirmed: “confirmed working.” This
  is operator-reported acceptance; no per-device transition trace was supplied.
  Native PIN/passkey hardware was not reported tested; authentication evidence
  remains the production QML, coordinator and private-bus fixtures.

Final inventory: 16 paths, 8 added / 8 modified / 0 deleted. Schema remains 21.
The finalization allowlist excludes settings.json, all local configs, launcher and
System Tray implementation, generated themes, icon artwork and runtime state.
Protected state is checked against the pre-integration snapshot. Automatic future
reconnection is enabled by Trusted; actual reconnection also depends on BlueZ,
the device and its supported profiles. No reboot was required for acceptance.
