# Current status and next priorities

Schema 22. Completed capabilities include the Bar visual builder and multi-output
policy, Hub utilities, Control Centre/Settings ownership, theme/application appearance,
native lock and designer/modules, detached launcher lifecycle, generic Bluetooth
pairing/Agent1, System Tray, and Audio output/input routing with grouped application
volume. Super+T is an inline runtime Bar toggle; there are no Tray visibility modes.
Bluetooth audio auto-switch is deferred; WirePlumber remains routing authority.

TTY login is the accepted workflow. **MAGI Greeter is not on the active roadmap.**
Historical Greeter proposals are retained as history, not pending commitments.

## Highest-value next decisions

1. **Reliability:** run native lock/private-bus transport proofs on a host without
   sandbox denial. The Settings migration-backup trigger debt is resolved; normal
   current-schema saves no longer create migration backups.
2. **Hardware acceptance:** prioritize authenticated Bluetooth hardware and the
   existing Displays 10C.2B / Fingerprint 11B gates when suitable devices are available.
   Do not expand deployment based solely on synthetic evidence.
3. **Daily-use polish:** choose an observed user pain before optional features. Weather
   semantic icons and depth-mask import remain legitimate polish candidates; optional
   Bluetooth audio auto-switch needs an explicit policy review, not silent default-on.

Physical multi-monitor Tray acceptance, GTK/Thunar transparency and Zen activation
limitations remain documented deferrals. None is automatically scheduled by Phase 15.
No next feature phase begins as part of this consolidation.
