# MAGI research index

Status: **2026-09-24**. The [local codebase audit](local-audit.md) is complete.
Documentation reconciliation is approved; external-project research has
not begun and awaits the user's next approval. No individual external
project reports exist yet, and no architecture or license findings are
claimed for the projects below.

## Proposed order

First deepen the [official Quickshell 0.3.1 research](../quickshell-reference.md):
windows/anchors/exclusion, TransformWatcher, focus/dismissal, Qt animation
interruption and Loader lifetime. Then verify networking object lifetime,
scanning and failure handling before designing a Wi-Fi migration.

The following repositories were supplied by the project's original README.
Their contents, supported versions and licenses remain to be inspected.
Questions in this table are investigation goals, not implementation claims.

| Order | Project / source URL | Proposed investigation | Planned report |
| --- | --- | --- | --- |
| 1 | [K4](https://github.com/k4ditano/k4) | Bar/menu composition, positioning, animation ownership and interruption handling. | `k4.md` |
| 2 | [Noctalia v4](https://github.com/noctalia-dev/noctalia-shell) | Identify and pin an actual v4 tag/commit; plugin interfaces, settings and menu/service lifecycle. Do not substitute current main for v4. | `noctalia-v4.md` |
| 3 | [Lucid](https://github.com/Sn3akyy1/lucid) | Content hosting, transitions, focus and dismissal. | `lucid.md` |
| 4 | [Caelestia](https://github.com/caelestia-dots/shell) | Window/focus coordination, service separation and screen handling. | `caelestia.md` |
| 5 | [Serpantinum](https://github.com/ilyamiro/serpantinum) | Menu navigation, geometry and reusable content patterns. | `serpantinum.md` |

## Required evidence for each investigation

- Source URL and inspection date; pinned repository commit/tag and relevant
  dependency/documentation versions.
- Exact files, functions and QML components that demonstrate each finding.
- What the code actually demonstrates, distinguished from screenshots,
  design proposals and hypotheses.
- License and asset provenance before any reuse; record restrictions.
- Relevance to MAGI's current bar, menu animations, window-relative geometry
  and preserved Wi-Fi/password flow.
- Compatibility with installed Quickshell 0.3.1, Qt 6.11.2 and Hyprland 0.56.2;
  identify differences rather than assuming patterns transfer unchanged.
- Remaining questions and a bounded local test plan. Record actual results
  only after tests are authorized and performed.

Compare findings before proposing a shared menu/content/service contract.
Review the architecture and tests with the user before replacing expansion
or migrating Wi-Fi. Reference-project code is evidence to evaluate, not an
instruction to change MAGI automatically.
