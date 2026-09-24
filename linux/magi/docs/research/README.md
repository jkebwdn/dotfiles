# MAGI research index

Status: **2026-09-24**. The [local codebase audit](local-audit.md), documentation
reconciliation and [phase-1 Quickshell research](quickshell-windows-and-lifecycle.md)
are complete. Phase 2A now documents [K4](k4.md) and [Serpantinum](serpantinum.md),
including a separately pinned historical imperative-dots comparison.
These are source investigations, not local runtime test results.

| Completed investigation | Pinned source |
| --- | --- |
| K4, main | `5b1406c2267440c97c4c9986a9fa19c7424094c0` |
| Serpantinum, master; version.txt 2.1.9 | `9f0e36bd9199c1d379701d052b884762b0de008b` |
| Historical imperative-dots, master | `705501e29f8e3f2d3f29a8c185c6f845e30426d1` |

Reports record licenses, source paths, ownership, motion, input, lifetime,
compatibility questions and proposed tests. No external code was reused.
See the [neutral A/B/C comparison](serpantinum.md#technical-comparison-for-magi)
before selecting a host architecture. Further research/tests/implementation
await approval.

## Proposed order

First review phase-1 T01–T07 and phase-2A's isolated comparison experiments.
Keep MAGI's current popup geometry/animation as the control. Remaining
external-project research can proceed in the order below after approval.
Verify networking object lifetime, scanning and failure handling before
designing a Wi-Fi migration.

The following remaining repositories were supplied by the original README.
Their contents, supported versions and licenses remain uninspected.
Questions in this table are investigation goals, not implementation claims.

| Order | Project / source URL | Proposed investigation | Planned report |
| --- | --- | --- | --- |
| 1 | [Noctalia v4](https://github.com/noctalia-dev/noctalia-shell) | Identify and pin an actual v4 tag/commit; plugin interfaces, settings and menu/service lifecycle. Do not substitute current main for v4. | `noctalia-v4.md` |
| 2 | [Lucid](https://github.com/Sn3akyy1/lucid) | Content hosting, transitions, focus and dismissal. | `lucid.md` |
| 3 | [Caelestia](https://github.com/caelestia-dots/shell) | Window/focus coordination, service separation and screen handling. | `caelestia.md` |

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
