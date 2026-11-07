# Spawn / subagents

Human summary of the portable spawn contract. Agents **Read** the canonical skill contract at `core/skills/_shared/agents/SPAWN.md` (published under `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` after sync) before `CreatePlan` that cites orchestration/Task/subagents and before the first non-trivial spawn vs in-parent decision.

Per-adapter honesty notes: each `adapters/<id>/README.md` → **Spawn / subagents**. Registry capability: `docs/ADAPTERS.md`.

## Child assignment lifecycle

Lifecycle: see `core/skills/_shared/agents/SPAWN.md` section "Task ownership and lifecycle".
## Capability `subagents`

| Value | Meaning |
|-------|---------|
| `native` | Host exposes Cursor **Task** or a documented product-equivalent spawn API |
| `none` | No Task/equivalent — prefer in-parent / documented handoff (never hard-fail) |

- String enum only (`native` \| `none`) — **not** boolean.
- Declared: `adapters/registry.json`. Effective: adapter `Get-Capabilities` (may differ; see Antigravity).
- Missing/unknown → treat as `none`. Stubs/defaults must never mint `native`.

## Inventory × host spawn

Sources: official host product docs (primary), `adapters/registry.json`, SPAWN / `SUBAGENT-MODEL.md` / `orchestrate-*`.

| Agent id | Display | Product evidence | Registry `subagents` | Prefer when effective `native` |
|----------|---------|------------------|----------------------|--------------------------------|
| `cursor` | Cursor | Cursor **Task** (Orchestrated Delivery / `SUBAGENT-MODEL`) | `native` | Cursor Task |
| `claude` | Claude Code | Agent/Task in Claude Code | `native` | Agent / Task |
| `antigravity` | Antigravity | `invoke_subagent` (+ `define_subagent`, `/agents`, worktrees) since **2.0** — [docs](https://antigravity.google/docs/subagents), [CLI](https://antigravity.google/docs/cli/subagents) | `native` (declared) | Effective via probe → `invoke_subagent` or fallback |
| `codex` | Codex | Parallel spawn via prompt / `AGENTS.md` / skills; `.codex/agents/` — [codex/subagents](https://developers.openai.com/codex/subagents) | `native` | Spawn agents (prompt/skill) |
| `copilot` | GitHub Copilot | `/fleet` + `.github/agents/` — [GitHub Blog /fleet](https://github.blog/ai-and-ml/github-copilot/run-multiple-agents-at-once-with-fleet-in-copilot-cli/) | `native` | `/fleet` subagents |
| `opencode` | OpenCode | `mode: subagent` + **Task** tool — [opencode.ai/docs/agents](https://opencode.ai/docs/agents/) | `native` | OpenCode Task |
| `grok` | Grok Build | `spawn_subagent` + `[subagents]` — [docs.x.ai](https://docs.x.ai/build/settings/reference), [x.ai/cli](https://x.ai/cli) | `native` | `spawn_subagent` |
| `zcode` | ZCode | **Agent** tool + `~/.zcode/agents/` — [zcode subagents](https://zcode.z.ai/en/docs/subagents) | `native` | ZCode Agent tool |
| `hermes` | Hermes | Tool **`delegate_task`** (isolated child; optional `role=orchestrator`) — [delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation) | `native` | `delegate_task` |
| `openhands` | OpenHands | Canvas / ACP is not parent→child. SDK `TaskToolSet` is not Canvas. [Skills](https://docs.openhands.dev/overview/skills) | `none` | In-parent (SPAWN fallback) |


## Nesting matrix

| Agent id | Child can spawn child | Source | Evidence level | Checked on | Restriction type |
|----------|-----------------------|--------|----------------|------------|------------------|
| antigravity | unknown | unknown | unknown | - | unknown |
| claude | unknown | unknown | unknown | - | unknown |
| codex | unknown | unknown | unknown | - | unknown |
| copilot | unknown | unknown | unknown | - | unknown |
| cursor | unknown | unknown | unknown | - | unknown |
| grok | unknown | unknown | unknown | - | unknown |
| hermes | unknown | unknown | unknown | - | unknown |
| opencode | unknown | unknown | unknown | - | unknown |
| zcode | unknown | unknown | unknown | - | unknown |
| openhands | n/a | n/a | none | 2026-11-06 | n/a |

A prompt instruction is not a host block.

**Honesty:** promote/demote only with product evidence. Demote registry `native` → `none` only with a documented regression. Absence of a Spawn section in an adapter README does **not** by itself imply `none`.

**Anti-hallucination:** agents must use **only** their own host row from the portable SPAWN map (`core/skills/_shared/agents/SPAWN.md` § Use only the current host row). Hermes-only operability (`delegate_task` goal/context bridge) is appended to Hermes `AGENTS.md` at publish — it must **not** appear in core policy/router or in other adapters’ published `AGENTS.md` / rules.

## Antigravity dual-layer (version gate)

Before 2.0: Agent Manager with parallel agents in separate conversations — **not** hierarchical in-session delegation. Since 2.0: `invoke_subagent` (async, worktrees).

| Layer | Value | Role |
|-------|-------|------|
| `registry.json` | `native` | Declared product capability (2.0+) |
| `Get-Capabilities` | probe → `native` \| `none` | Effective on this machine |
| SPAWN / skills | Prefer native only if effective = `native` | Never hard-fail |

Probe fail-closed (`Resolve-AntigravitySubagentsCapability`). Order matches `core/skills/_shared/agents/SPAWN.md`:

1. Override `ADT_ANTIGRAVITY_SUBAGENTS` ∈ {`native`,`none`} wins.
2. Product version `>= 2.0.0` when known (`ADT_ANTIGRAVITY_PRODUCT_VERSION`).
3. Parseable `agy --version` `>= 1.0.0` as 2.0 harness proxy (CLI stays `1.x`; do **not** require CLI major ≥ 2).
4. Else `none` (missing binary, parse failure, or unknown).

## Behavior matrix

Caps and checklist: `core/skills/_shared/agents/SPAWN.md`.

**RN:** subagent-first = preference + fallback. Antigravity: use **effective** capability (probe), not registry alone.

## Specialists (`needs_*` → ROSTER)

O1 triage sets `needs_*` on `FEATURE.md`. Spawn map (flag → specialist / action / prompt): **`Flags (needs_*)` table** in `core/skills/_shared/agents/ROSTER.md` — do **not** copy that table into skills or this page. Point agents there.

**Custom subagent files:** `sync-agent` `Publish-Agents` copies a small roster-aligned set from `core/agents/` (`repo-analyst`, `architect`, `database`, `security`, `shell-runner`) into the host `agents/` directory when `agents=true`. Parent stays the main agent; these files teach *whom* to call. Always-on orchestrator policy already tells the parent to delegate. Do **not** duplicate every `*-developer` skill as an agent file. **OpenCode** and **Grok** publish with `agents: true`: `Publish-Agents` → `InstallRoot/agents/` (native OpenCode Task and Grok `spawn_subagent` remain). **Antigravity** and **Hermes** stay `agents: false` (`Publish-Agents` no-op; native `invoke_subagent` / `delegate_task` only). **OpenHands** still has `subagents=none` and still writes roster files under `.agents/agents/` — that path is an SDK/plugin roster, not Canvas Profile and not native spawn (SPAWN fallback in-parent).

## Task `model` (Eixo B/C — A≠B≠C)

See `core/skills/_shared/agents/SUBAGENT-MODEL.md` for axes B and C.
## Orchestrate parents

`orchestrate-analyze` / `deliver` / `develop` parents **coordinate**: goals, gates, scoped paths, receipts, synthesis. They **must not** implement application code — specialists (or stack `*-developer` / `sdd-develop`) own implementation. Receipt shape: `RECEIPT.md` (lazy-load).

## Related

| Path | Role |
|------|------|
| `core/skills/_shared/agents/SPAWN.md` | Canonical agent contract (when/how; anti-paste; child payload) |
| `core/skills/_shared/agents/LANGUAGE.md` | Two language surfaces; child prompts always en-US; paths + excerpt (no full PLAN dump) |
| `core/skills/_shared/agents/ROSTER.md` | Which roles / `needs_*` spawn map (O1) |
| `core/skills/_shared/agents/RECEIPT.md` | Specialist receipt schema |
| `core/skills/_shared/agents/SUBAGENT-MODEL.md` | Cursor Task `model` policy |
| `adapters/<id>/README.md` | Per-host Spawn / subagents honesty |
| [ADAPTERS.md](ADAPTERS.md) | Registry + publish surfaces |
