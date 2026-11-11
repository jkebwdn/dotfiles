# Current status and next decisions

Schema 22. The accepted [Pass 2](review/controlcentre-settings-pass2.md), based on
synchronized `93ef0da`, adds a persistent/larger preview and final shared-default
roundness ownership. Native acceptance and final alignment are operator-confirmed;
two focused commits and normal push are authorized. Host synchronization is recorded
in the durable push receipt. Do not begin Pass 3.

Production includes the Bar/multi-output policy, Hub utilities, Control Centre and
Settings ownership, shared tray/audio services, generic Bluetooth pairing/Agent1,
detached application launching, wallpaper, Theme Orchestrator, terminal visuals and
NERV fetch. Curated lock themes and production fingerprint/password unlock are
accepted, including internal suspend/resume. The internal designer remains available
only through its developer gate. Greeter is not on the active roadmap; TTY login stays.

Hyprland uses Lua on 0.57. The T15g stays in Hybrid mode with Intel compositor rendering
and NVIDIA available for application/game offload. Ghostty owns alpha, Hyprland owns
its blur, and MAGI retains precise panel regions. NVIDIA-primary and Discrete desktop
experiments are rejected history, not planned architecture.

Consolidation's guarded canonical-config placement and native readback passed;
regression is complete and the operator approved one consolidation commit. Push remains
a separate approval. Settings, audit evidence, monitor behavior and packages are
preserved; GPU experiments remain closed.

Remaining decisions are bounded by evidence:

1. Complete Displays 10C.2B and physical external-monitor lock/Tray acceptance only
   with suitable hardware and an explicit native gate. Production fingerprint work
   is already complete; the old Phase 11B integration plan is not outstanding.
2. Revisit authenticated Bluetooth hardware coverage and native transport tests when
   needed for affected source changes. Current sandbox exceptions remain narrow.
3. Choose an observed daily-use problem before optional work: GTK/Thunar transparency,
   Zen reporting/activation polish, selected polling, reduced motion, or depth-mask
   import require their own decisions. Bluetooth audio switching requires an explicit
   routing policy; it is never silently enabled by consolidation.

See [technical debt](technical-debt.md) for concrete limitations and
[historical checkpoints](history.md) for dated development evidence. Completed work
must not be inferred to be pending from those old records.

The [Custom Image Bar item](review/bar-custom-image.md) is deployed and native visual
acceptance has passed. The supplied AE86 follows Date at the currently saved 20px
height, adjustable in Settings. Schema remains 22. One focused commit is authorized;
push remains a separate operator approval. Preserve live Settings exactly.

Control Centre Decorative Image and the revised GIF artwork passed operator
acceptance on 2026-11-09. The focused commit preserves current Settings exactly;
push requires separate approval. Physical multi-output acceptance and native CPU
measurement remain documented limitations. No additional decoration features are
planned. See [review](review/controlcentre-image.md).

## Focus, picker and Settings grouping

The synchronized decoration baseline is `771cf7c`. The bounded new candidate passed
103 checks with 0 FAIL / 0 UNKNOWN and four established environment limits. Native
focus, picker and grouped-card acceptance passed on 2026-11-10. Three focused
commits were approved and pushed; synchronization is verified at `eb19df4`. See [review and API evidence](review/focus-picker-settings.md).

## Appearance and feature-owned Roundness

Appearance is native-accepted, committed and synchronized at `fa40a70`. Native product
review superseded the uncommitted central Option A editor. Its review deployment was
rolled back safely; the revised candidate distributes nine multiplier sliders and
one pixel stepper across their features, retaining all twelve fields and the hidden
base fallback. That historical temporary Buttons/switches editor is now superseded by the
approved Pass 2 default-UI ownership model. [Revised phase](review/roundness-feature-ownership.md).
The operator accepted the revised UI, committed and pushed it at `5e00c38`.
Native acceptance is operator-reported; the helper did not save a completed case
receipt. No schema/migration,
field merge/removal or Options B/C work is authorized.
