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

1. Audit MAGI's current source and reconcile the documentation.
2. Research Quickshell's window, popup, animation and focus APIs.
3. Study K4, Noctalia v4, Lucid, Caelestia and Serpantinum.
4. Establish a clean modular menu architecture.
5. Implement the user's annotated design renders incrementally.

Do not migrate Wi-Fi or replace the existing expansion system until the
relevant architecture and tests have been reviewed with the user.
