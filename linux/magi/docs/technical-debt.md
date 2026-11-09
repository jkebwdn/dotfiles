# Technical debt register

Reviewed against production `e251450` on 2026-11-05. This register contains concrete
remaining limitations; it schedules no new features. Severity follows the
[post-0.57 audit](review/post-057-consolidation.md). No P0 issue was established by
this bounded source/runtime review; it is not a security certification.

| Severity | Remaining issue / evidence | Boundary or next decision |
| --- | --- | --- |
| P2 | Displays 10C.2B is not a production monitor transaction manager | HyprMon remains authority. Planner/synthetic watchdog coverage does not replace physical apply/rollback acceptance. |
| P2 | Physical external-monitor lock acceptance remains deferred | Internal fingerprint/password, lock themes and suspend/resume passed. Do not generalize that evidence to unavailable external displays. |
| P2 | Native transport/private-bus tests encounter sandbox restrictions | Keep exact source hashes, independent denial probes and failure-case checks. Native/auth changes require fresh host proofs, not broader skips. |
| P2 | QuickActions polls three status requests every 5s; Brightness polls every 2s | Accepted current behavior; investigate event-driven ownership separately if an observed problem warrants it. Clipboard's bounded queue wait is not another compositor poll. |
| P2 | Native fingerprint broker uses 10 ms bounded bus dispatch while an attempt is active | Cancellation/deadlines/retry are tested. Event-loop integration would require separate auth review; no change here. |
| P2 | Ghostty appearance/history can accumulate generations beyond the ordinary two-entry theme journal | Inventory pending/current/previous, ownership and audit recovery references before owner-validated pruning. No age-based cleanup or blind CSS deletion. |
| P2 | Zen has partial theme/activation support | Workspace colour remains a deliberate application action. Thunar background alpha and compositor blur passed native acceptance; GTK changes still require application relaunch. |
| P2 | Zen can report Playing with missing MPRIS duration until pause/resume | Keep valid-position timer handling; no fabricated duration, unsolicited playback change or extra polling. |
| P2 | Bar-wide keyboard traversal/focus handoff lacks a complete contract | Preserve current shortcuts; decide keyboard-grab/return behavior separately. |
| P2 | No reduced-motion policy; some semantic-role text contrast is weak | Requires explicit accessibility/visual choices, not silent palette or animation changes. |
| P2 | Audio grouping can fall back to application.name | Same-name apps can share a row. Revisit only with observed metadata collisions. |
| P2 | Authenticated Bluetooth PIN/passkey hardware and physical multi-monitor Tray coverage are incomplete | Preserve application-scoped Agent1 and native menus; synthetic tests are not complete hardware proof. |
| P3 | Some QML harnesses duplicate fixture/stub setup or transform fixture source | Retain distinct behavioral coverage; consolidate only with evidence that isolation and assertion strictness survive. |
| P3 | Native lock README is a chronological proof/deployment log with old headers | Current architecture/security/testing docs take precedence. Old commands and package references are historical, never installation authority. |
| P4 | Hover disclosure, weather semantic artwork, depth-mask import and rounded-edge pixelation need separate review | No visual redesign here. Pixelation cause is unproven; existing corners were accepted. |

Resolved items are recorded in their review documents rather than kept as open debt:
Settings backup-version drift, Profile column cycling, notification idle work,
Wi-Fi/focus feedback, production fingerprint integration, curated lock themes,
Hyprland 0.57 border/effects compatibility, normal Ghostty blur/reload acceptance,
and guarded canonical Hyprland link/enrollment placement with unchanged native readback.

The scoped Ghostty opt-out is inherited by terminal descendants; direct absolute-binary
or D-Bus launches bypass the wrapper. These are documented launch boundaries, not
claims that every possible terminal invocation is covered. Theme publication remains
per-target atomic with compensation, not a global filesystem transaction.

Optional Bluetooth audio auto-switch remains a policy decision; WirePlumber owns
routing. It is not a missing cleanup fix. See [current priorities](current-roadmap.md).

Custom Image: the operator confirmed the live visual check passed. Physical mixed-DPI
output acceptance remains pending. The importer requires installed `python-pyqt6`; optional
WebP decoding also depends on the host Qt image-format plugin. This host decodes
GIF/PNG/JPEG; unsupported formats fail import without replacing the selected asset.
The current Bar catalogue permits one configurable Custom Image item, shared across
enabled outputs. Multiple independent artwork instances would require a deliberate
catalogue-instance design. See [candidate evidence](review/bar-custom-image.md).

Control Centre decoration, revised GIF artwork and tests were accepted by the
operator on 2026-11-09. Native CPU measurement remains unavailable in the sandbox;
synthetic routing does not establish physical multi-output acceptance. The existing
outside-dismiss catcher still owns outside clicks while open; artwork adds no input
target. See [acceptance review](review/controlcentre-image.md).
