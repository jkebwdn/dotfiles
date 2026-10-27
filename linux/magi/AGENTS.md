# MAGI — Codex project instructions

MAGI is a modular Quickshell desktop environment for Arch Linux and Hyprland.

Project root: ~/dotfiles/linux/magi
Live shell: .config/quickshell/magi/
Documentation: docs/

Read docs/README.md before beginning work.

## Development rules

- Inspect existing source files before proposing modifications.
- Target the Quickshell and Hyprland versions installed on the user's machine.
- Verify Quickshell APIs against documentation for the applicable version.
- Preserve the working bar, expandable-menu animations and popup positioning.
- Preserve the existing Wi-Fi scanning, connection and password-entry functionality.
- Do not modify live QML during research without explicit approval.
- Do not restart Quickshell or modify Hyprland configuration without approval.
- Make small, reviewable changes.
- Use nvim in editor instructions, never nano.
- Do not commit or push changes without explicit approval.
- Do not modify unrelated dotfiles.

## Research standards

Record the following for each technical finding:

1. Source URL and date inspected.
2. Repository commit or documentation version, where applicable.
3. Relevant source files and functions or QML components.
4. What the source actually demonstrates.
5. Relevance to MAGI.
6. Compatibility considerations.
7. Remaining questions or required tests.

Distinguish verified facts from hypotheses and design proposals.

Do not infer an implementation from screenshots or videos alone.
Do not invent source references or test results.
Check licenses before reusing code or assets.

## Documentation maintenance

Keep these files consistent with the implementation:

- docs/README.md — project status and research index
- docs/architecture.md — existing and proposed architecture
- docs/quickshell-reference.md — verified APIs and patterns
- docs/decisions.md — architectural decisions and debugging history

Store reference-project investigations in docs/research/.
Store render specifications and annotations in docs/design/.

## Current priorities

1. Preserve the accepted production baseline and protected operator state.
2. Resolve evidenced reliability debt with affected/full regression coverage.
3. Complete hardware acceptance only when the relevant device and authorization exist.
4. Follow docs/current-roadmap.md; do not begin a new feature phase automatically.

## Permanent production and closeout policy

- `~/dotfiles` is the persistent source of truth. Read the current docs index,
  architecture, testing, generated-state and closeout guidance; phase documents are
  historical evidence, not instructions to restore old source or rerun live helpers.
- Prefer unique `/tmp/magi-<task>-<id>` worktrees when isolation is useful. Do not
  accumulate home-directory phase checkouts or use them as archives.
- After accepted work is committed, pushed, synchronized and protected-state verified,
  remove the completed worktree unless explicitly retained. Prove its HEAD merged,
  reconcile every dirty/untracked file, check active services/references, use Git
  worktree removal, and prune genuinely stale registrations. Never delete by name/age.
- Snapshot all operator-local dirty/untracked state, Settings, icon artwork and
  configuration symlinks before integration. Preserve local Hyprland, Ghostty, GTK,
  Yazi, lock, generated-theme and other customizations. Never stage settings.json or
  unrelated local edits. Stage exact paths/hunks only; never `git add .` / `git add -A`.
- Use the canonical `tests/run-all.py`; use `--only` for affected checks. Internal
  assertions/Qt warnings must not be hidden by later PASS markers. Environment limits
  require specific evidence; unknown failures stop finalization.
- Preserve native lock/PAM authority, application-scoped Agent1 caller checks,
  detached launcher streams, shared Tray state/native menus, and external PipeWire /
  WirePlumber authority. Application icons are not MAGI semantic icons.
- Keep runtime/generated state in its intended XDG store, not Git. Theme Orchestrator
  remains the generated-theme writer; preserve current/previous/pending/conflicted
  generations. Do not introduce competing writers during cleanup.
- Update canonical docs and technical debt when architecture or acceptance changes.
  No feature work or speculative restoration during consolidation.
- Avoid helper-script spam. Prefer direct tools; if host Git transport is necessary,
  use one guarded helper for the final fetch/divergence/normal-push sequence. Never
  force push. Remove safe temporary builds/helpers after jobs complete; retain only
  evidence needed for unresolved review. See docs/phase-closeout.md.
