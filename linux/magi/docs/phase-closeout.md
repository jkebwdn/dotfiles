# Development and phase closeout

`~/dotfiles` is the persistent production source of truth. Use an isolated worktree
only when it improves safety; prefer a unique `/tmp/magi-<task>-<id>` root for ephemeral
work. Do not accumulate `~/magi-phase*` or turn worktrees into archives.

Before changing production, verify baseline/tracking synchronization and an empty
index. Snapshot dirty/untracked operator state, including Settings, local Hyprland,
application configs, icon artwork and symlink targets. Never normalize it implicitly.
User authorization and accepted native checks carry across turns.

Closeout checklist:

- Run affected checks, then the canonical full matrix; distinguish PASS, genuine
  FAIL, specific ENVIRONMENT and intentional SKIPPED. Never trust a success marker
  after internal failures. Complete required native acceptance.
- Update current architecture, decisions, testing, roadmap and debt documentation;
  retain historical phase evidence without presenting it as current instructions.
- Build native components from clean source when affected; do not install/redeploy
  merely to test. Preserve security and service-ownership boundaries.
- Calculate exact A/M/D inventory; stage only an explicit allowlist. Never `git add .`
  or `git add -A`. Inspect cached check, names and stat. Exclude Settings and unrelated
  operator edits, including mixed-file Hyprland changes.
- Commit reviewable changes. Fetch, verify only the expected commits are ahead and
  none behind, then push normally. Never force push. If sandbox networking blocks
  Git, use at most one guarded host helper with exact commit and divergence checks.
- Verify tracking divergence 0 0, empty index and protected-state preservation.
- **After accepted work is committed, pushed and synchronized, remove its development
  worktree unless explicitly retained.** First prove HEAD merged, dirty/untracked
  content redundant or recovered, and no active service/persistent reference uses
  the path. Use `git worktree remove`; force only after explicit reconciliation.
  Prune genuinely missing registrations and remove only fully merged phase branches.
- Remove safe temporary test/package/build roots after jobs finish. Preserve current
  runtime/rollback state and evidence needed for unresolved findings. Do not use
  home archives or blanket cache cleanup.

A fresh session should read current canonical docs, then the relevant historical
record. Do not resurrect old whole files or run old native helper commands merely
because a phase document mentions them.
