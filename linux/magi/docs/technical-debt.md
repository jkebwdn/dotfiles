# Technical debt register

> Current Phase 15 source-review findings; no new feature is scheduled by this register.

Phase 15 source review, 2026-10-27. Severity describes impact, not a feature schedule.
No critical vulnerability has been established by this bounded review.

| Severity | Issue / evidence | Impact and proposed direction | Safe to defer? |
| --- | --- | --- | --- |
| High | Native lock transport tests cannot complete in this sandbox; SOCK_SEQPACKET send returns EPERM | Host offline transport verification remains required; do not weaken auth assertions or claim a security pass | Yes for documentation-only cleanup; no for auth changes |
| Medium | Settings migration-backup trigger drift | Resolved: persistence compares the on-disk version with the outgoing Schema-analyzed document; current-schema saves create no migration backup. Original migration/recovery contents and failed-write retry protection remain covered | Resolved; existing backups retained |
| Low | Profile Settings provisional-width/column cycle | Fixed in shared SettingsRow using parent available width; strict long-text/pinned-preview regression and native smoke pass | Resolved; see Profile layout review |
| Medium | `QuickActions.qml` refreshes three status requests every 5s; Brightness polls every 2s | Repeated Python/subprocess work; investigate event-driven adapters before changing behavior | Yes |
| Medium | Audio application grouping falls back to application.name after ID/binary | Same-name applications can share one volume row; document metadata limits, revisit only with real collisions | Yes; accepted current behavior |
| Medium | Native authenticated Bluetooth hardware acceptance remains absent | Synthetic Agent1 tests do not prove every PIN/passkey device; test suitable hardware when available | Yes; keep capability limitations explicit |
| Medium | Displays and fingerprint have synthetic groundwork but incomplete physical production acceptance | Complete guarded hardware gates before expanding deployment | Yes |
| Medium | Theme activation has per-target publication/compensation, not global filesystem atomicity | Keep journals, ownership checks and honest partial-failure status; do not promise all-target atomic replacement | Yes; tested design boundary |
| Low | Many presentation harnesses duplicate disposable-root and service-stub setup; some consume fixture text via AST/string substitution | Brittle isolation and warning lists; consolidate incrementally with before/after coverage | Yes |
| Low | Chronological docs mix pending and completed checkpoints | Canonical index/current architecture must take precedence; preserve history without treating old instructions as current | Addressed by canonical documentation structure |
| Low | Native lock README includes historical real-lock procedures | Label history prominently; never interpret old commands as current authorization | Addressed by current-doc pointer; security gate remains |
| Low | Audio device icon classification uses Bluetooth/volume fallback | Future semantic roles can improve differentiation; no artwork added in cleanup | Yes |
| Low | Test schema expectations hard-coded current versions and replaced custom lock data | Phase 15 fixes version assertions and preserves custom migration fixtures; retain historical input schemas | Addressed in test-only changes |
| Cosmetic | Weather semantic artwork and depth-mask import remain deferred | Consider only after daily-use reliability/hardware priorities | Yes; no feature work in Phase 15 |

No obsolete Tray shortcut popup or audio auto-switch implementation was found to
remove. TrayOverflow is still used by the Bar's overflow control. `trayVisibility`
appears only in the deliberate migration scrub and regression fixtures. Historical
migration support is not dead code.

Icon fallback compositor setup and old schema/catalogue/Theme assumptions were corrected in tests during regression reconciliation. No production resolver or runtime changes were made.
