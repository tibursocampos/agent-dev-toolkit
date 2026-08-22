## Hermes spawn bridge (this host only)

On **Hermes**, effective `subagents=native` means the host tool **`delegate_task`** — not Cursor **Task**, not `/fleet`, not `spawn_subagent`.

### Map SPAWN → `delegate_task`

When SPAWN / Orchestrated Delivery prefer a specialist child:

1. Call **`delegate_task`** with a clear `goal` and a self-contained `context`.
2. Put in `context`: portable paths (FEATURE / CONTINUITY / PLAN / story notes), role, and receipt requirement (`RECEIPT.md`). Do **not** paste guideline packs, full SKILL bodies, or large policy dumps.
3. O3 develop: **one child = one PLAN step** (`sdd-develop` contract). Parent updates CONTINUITY only; parent never writes application code.
4. Prefer `role=leaf` (default). Nested `role=orchestrator` is optional operator config — the toolkit does **not** emit `delegation.*` YAML.

### Where this file applies

Hermes loads project `AGENTS.md` from the **session CWD** (git-root chain), not automatically from `$HERMES_HOME`. This folded home `AGENTS.md` applies when the session CWD is the Hermes home. For normal repo work, follow the portable SPAWN map in `skills/_shared/agents/SPAWN.md` (use **only** the `hermes` row) and load skills on demand.

### Out of scope for the toolkit

Do **not** expect Publish to write `config.yaml`, gateway tokens, or `delegation.max_spawn_depth` / worktree settings. Configure those in the operator’s Hermes home if needed. Do **not** use `skills.external_dirs` when the toolkit publishes into the official home `skills/` tree.

Official: [Subagent delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation). Portable contract: `skills/_shared/agents/SPAWN.md`.
