# Shared-surface lifecycle regression

Run from the MAGI project root:

```sh
python3 tests/shared-status-surface/run.py
```

Requires the existing Quickshell 0.3.1 runtime; no added dependencies. The
runner stages a disposable copy of the current config under `/tmp`, loads the
real SharedStatusSurface with dummy module bodies, uses the offscreen Qt backend
and removes the temporary config/runtime after exit. It creates no native
window, uses no pointer injection and does not operate network/audio devices.
Quickshell needs permission to create a temporary local IPC socket even here.

The 44-step sequence checks normal open/close/reopen, switching without zero
height, rapid retargeting, reversal during widening/reveal/fade/retract/narrow,
compact-width changes, same-turn request bursts and retained module bodies.
Failures print phase/height/opacity and make the Python runner exit nonzero.
The sequence also checks tall Wi-Fi/Bluetooth → short CC/Volume geometry against
the reference CC tokens. This is lifecycle coverage, not a compositor/focus/input/visual acceptance test.
