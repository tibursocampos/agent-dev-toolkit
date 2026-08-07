# Spawn / subagents (Tier 1)

Human summary of the portable spawn contract. Agents load the canonical skill contract at `core/skills/_shared/agents/SPAWN.md` (published under `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` after sync).

Per-adapter honesty notes: each `adapters/<id>/README.md` → **Spawn / subagents**. Registry capability: `docs/ADAPTERS.md`.

## Capability `subagents`

| Value | Meaning |
|-------|---------|
| `native` | Host exposes Cursor **Task** or a documented product-equivalent spawn API |
| `none` | No Task/equivalent — prefer in-parent / documented handoff (never hard-fail) |

- String enum only (`native` \| `none`) — **not** boolean.
- Declared: `adapters/registry.json`. Effective: adapter `Get-Capabilities` (may differ; see Antigravity).
- Missing/unknown → treat as `none`. Stubs/defaults must never mint `native`.

## Tier 1 inventory × host spawn

Sources: official host product docs (primary), `adapters/registry.json`, SPAWN / `SUBAGENT-MODEL.md` / `orchestrate-*`.

| Agent id | Display | Product evidence | Registry `subagents` | Prefer when effective `native` |
|----------|---------|------------------|----------------------|--------------------------------|
| `cursor` | Cursor | Cursor **Task** (Forma C / `SUBAGENT-MODEL`) | `native` | Cursor Task |
| `claude` | Claude Code | Agent/Task in Claude Code | `native` | Agent / Task |
| `antigravity` | Antigravity | `invoke_subagent` (+ `define_subagent`, `/agents`, worktrees) since **2.0** — [docs](https://antigravity.google/docs/subagents), [CLI](https://antigravity.google/docs/cli/subagents) | `native` (declared) | Effective via probe → `invoke_subagent` or fallback |
| `codex` | Codex | Parallel spawn via prompt / `AGENTS.md` / skills; `.codex/agents/` — [codex/subagents](https://developers.openai.com/codex/subagents) | `native` | Spawn agents (prompt/skill) |
| `copilot` | GitHub Copilot | `/fleet` + `.github/agents/` — [GitHub Blog /fleet](https://github.blog/ai-and-ml/github-copilot/run-multiple-agents-at-once-with-fleet-in-copilot-cli/) | `native` | `/fleet` subagents |
| `opencode` | OpenCode | `mode: subagent` + **Task** tool — [opencode.ai/docs/agents](https://opencode.ai/docs/agents/) | `native` | OpenCode Task |
| `grok` | Grok Build | `spawn_subagent` + `[subagents]` — [docs.x.ai](https://docs.x.ai/build/settings/reference), [x.ai/cli](https://x.ai/cli) | `native` | `spawn_subagent` |
| `zcode` | ZCode | **Agent** tool + `~/.zcode/agents/` — [zcode subagents](https://zcode.z.ai/en/docs/subagents) | `native` | ZCode Agent tool |

**Honesty:** promote/demote only with product evidence. Demote registry `native` → `none` only with a documented regression. Absence of a Spawn section in an adapter README does **not** by itself imply `none`.

## Antigravity dual-layer (version gate)

Pré-2.0: Agent Manager with parallel agents in separate conversations — **not** hierarchical in-session delegation. Since 2.0: `invoke_subagent` (async, nesting ≤10, worktrees).

| Layer | Value | Role |
|-------|-------|------|
| `registry.json` | `native` | Declared Tier 1 product capability (2.0+) |
| `Get-Capabilities` | probe → `native` \| `none` | Effective on this machine |
| SPAWN / skills | Prefer native only if effective = `native` | Never hard-fail |

Probe fail-closed (`Resolve-AntigravitySubagentsCapability`):

1. Override `ADT_ANTIGRAVITY_SUBAGENTS` ∈ {`native`,`none`} wins.
2. Prefer product/IDE `>= 2.0.0` when a stable version source exists (`ADT_ANTIGRAVITY_PRODUCT_VERSION` / PATH).
3. Parseable CLI `agy --version` `>= 1.0.0` = proxy of harness 2.0 (**do not** gate on CLI major ≥ 2 — CLI is `1.x`).
4. Missing binary / parse failure / unknown → `none`.

## Behavior matrix

| `subagents` | Orchestrate / code-review multi-angle | `*-developer` medium/complex | Trivial developer |
|-------------|----------------------------------------|------------------------------|-------------------|
| `native` | Prefer Task (or host equivalent); receipt; no guideline paste | Up to **2** children; paths + receipt | In-parent |
| `none` | In-parent / documented handoff; **never** hard-fail | Same outcome in-parent | In-parent |

| Context | Cap |
|---------|-----|
| `*-developer` children | **≤ 2** |
| `orchestrate-*` parallel | **≤ 4** concurrent (wave if more) |

**RN:** subagent-first = preference + fallback. Antigravity: use **effective** capability (probe), not registry alone.

## Specialists (`needs_*` → ROSTER)

O1 triage sets `needs_*` on `FEATURE.md`. Spawn map (flag → specialist / action / prompt): **`Flags (needs_*)` table** in `core/skills/_shared/agents/ROSTER.md` — do **not** copy that table into skills or this page. Point agents there.

## Task `model`

Default: **omit** `model` on Task → child inherits the parent session model. Premium / alternate slug only when the gate in `SUBAGENT-MODEL.md` fires **and** the user answers **sim** (silence ≠ approval). Details: `core/skills/_shared/agents/SUBAGENT-MODEL.md`.

## Orchestrate parents

`orchestrate-analyze` / `deliver` / `develop` parents **coordinate**: goals, gates, scoped paths, receipts, synthesis. They **must not** implement application code — specialists (or stack `*-developer` / `sdd-develop`) own implementation. Receipt shape: `RECEIPT.md` (lazy-load).

## Related

| Path | Role |
|------|------|
| `core/skills/_shared/agents/SPAWN.md` | Canonical agent contract (when/how; anti-paste; child payload) |
| `core/skills/_shared/agents/ROSTER.md` | Which roles / `needs_*` spawn map (O1) |
| `core/skills/_shared/agents/RECEIPT.md` | Specialist receipt schema |
| `core/skills/_shared/agents/SUBAGENT-MODEL.md` | Cursor Task `model` policy |
| `adapters/<id>/README.md` | Per-host Spawn / subagents honesty |
| [ADAPTERS.md](ADAPTERS.md) | Registry + publish surfaces |
