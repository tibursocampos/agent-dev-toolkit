# Portable spawn contract (Forma C + developers)

Canonical contract for **when** and **how** to spawn specialist children across supported hosts. Orthogonal to **which** roles (`ROSTER.md`), **receipt shape** (`RECEIPT.md`), and **Task model** (`SUBAGENT-MODEL.md`).

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`

**Path decision:** stay under `_shared/agents/` — not `core/router/` (router is L0 index only). Human host matrix: `docs/SPAWN.md`.

**Default preference (all adapters):** this chat stays **parent / orchestrator** (lean: goals, gates, paths, receipts, synthesis). Prefer specialist children **in parallel** when independent for analysis, multi-file edits, script/batch runs, long builds/tests, deep investigation, and non-trivial planning. **Thin trivial exception:** single-path Q&A or a one-file edit **with no risk of spreading** may stay **in-parent**. If analysis spans multiple files, OR a one-file change might extend to others, OR any doubt → spawn. Caps and fallback below still apply.

**Mandatory Read:** the parent **must Read this file** before `CreatePlan` / any plan that promises orchestration, Task, or subagents, and before the first non-trivial spawn vs in-parent decision in a chat. A plan that cites orchestration/Task/subagents without that Read = checklist fail. Thin trivial work may skip the Read.

Always-on policy: `core/policy/orchestrator-session.md`. Cursor publishes `.mdc`; other hosts use native always-on (CLAUDE.md / AGENTS.md / copilot-instructions / GUARDRAILS). OpenCode/ZCode get the router Parallel specialists body only (no rules file). Router index: `core/router/AGENTS.md` → Parallel specialists.

## Capability `subagents`

Read from `adapters/registry.json` (declared) and adapter `Get-Capabilities` (effective). Capability `subagents` is the string enum `native` | `none`.

| Value | Meaning |
|-------|---------|
| `native` | Host exposes Cursor **Task** or a documented equivalent spawn API |
| `none` | No Task/equivalent — use fallback paths below |

- Type is a **string enum** (`native` \| `none`), not a boolean.
- Missing key or unknown value → treat as `none` (safe degrade).
- Never claim `native` without host product evidence (see `docs/SPAWN.md` + each `adapters/<id>/README.md` Spawn section).
- **Antigravity:** prefer **effective** capability from `Get-Capabilities` (fail-closed version probe). Do not assume registry alone when the host may be pre-2.0.

## Host spawn equivalents

Prefer the host-native mechanism when effective `subagents` is `native`. Product links, registry values, and Antigravity probe: `docs/SPAWN.md`.

| Agent | Prefer when `native` |
|-------|----------------------|
| `cursor` | Cursor **Task** |
| `claude` | Agent / Task |
| `antigravity` | `invoke_subagent` (Antigravity **2.0+** only; else fallback) |
| `codex` | Spawn / parallel agents via prompt, skill, or `AGENTS.md` |
| `copilot` | `/fleet` (+ `.github/agents/` when useful) |
| `opencode` | OpenCode **Task** / `@` subagent |
| `grok` | `spawn_subagent` |
| `zcode` | ZCode **Agent** tool |

### Antigravity effective capability

| Layer | Role |
|-------|------|
| Registry `native` | Declared product line 2.0+ |
| `Get-Capabilities` probe | Effective `native` \| `none` (fail-closed) |
| This contract | Prefer native only when **effective** is `native` |

Probe order: `ADT_ANTIGRAVITY_SUBAGENTS` override → product version `>= 2.0.0` when known → parseable `agy --version` `>= 1.0.0` as 2.0 harness proxy (CLI stays `1.x`; do **not** require CLI major ≥ 2) → else `none`.

## Decision tree

```text
Need specialist work?
  ├─ trivial: single-path Q&A OR one-file edit with no spread risk → in-parent
  │  (always; no spawn for noise)
  ├─ analysis spans multiple files / one-file might extend / any doubt /
  │  script-batch / long build-test / deep investigation / non-trivial planning
  │    ├─ subagents == native → prefer Task / host equivalent (table above)
  │    └─ else                → fallback in-parent (O1 flags: write ANALYSIS/ARCH/SEC; never CONTINUITY substitute)
  │                             NEVER hard-fail only because Task is absent
  └─ *-developer trivial path → in-parent (always)
```

| Consumer | Prefer when `native` | Fallback when `none` |
|----------|----------------------|----------------------|
| `orchestrate-analyze` | Task (or host equivalent) per roster when flag true / brownfield | **in-parent write** to story `ANALYSIS/` / `ARCH/` / `SEC/` — **never skip**; never substitute a CONTINUITY handoff note for `needs_api` / `needs_domain` / `needs_database` / `needs_security` / brownfield |
| `orchestrate-deliver` / `develop` | Task (or host equivalent) per roster/caps | Same specialist work **in-parent** (never hard-fail) |
| `code-review` multi-angle | Parallel specialist Tasks / host equivalents | Sequential in-parent angles |
| `*-developer` medium/complex | Up to **2** children | Same outcome in-parent |
| Parent general chat (analysis / multi-file / long build-test) | Specialist Task when independent work is heavy | Same work in-parent |

`needs_frontend` / `needs_devops` stay CONTINUITY-only (no Task, no specialist folder). Required O1 folders missing → do **not** approve the backlog.

**RN:** Subagent-first = **preference + fallback**, never hard-require Task. Parent stays orchestrator per `orchestrator-session` policy.

## Child payload (minimum)

When spawning (native path):

1. Pass **scoped paths** (files/dirs the child may read/write).
2. Require end-of-pass **receipt** per `RECEIPT.md` (lazy-load that file — do not paste its body). Prefer receipt even when Caveman OFF.
3. Point to role prompt under `skills/_shared/agents/prompts/` when Forma C roster applies.
4. Pass **role + receipt requirement + scoped paths** only. Child prompts, execution style, and returns are **Caveman-scoped** (inherit parent intensity from `{{SDD_ROOT}}/preferences.json`; contract: `skills/_shared/caveman/CAVEMAN.md`). Expand context only when the task truly needs richer detail (security dumps, ambiguous architecture, user asked for full detail) — Auto-Clarity / never-compress still apply.
5. **Do not** paste guideline packs, full SKILL bodies, or large policy dumps into the child prompt.
6. Task `model`: omit by default (same as parent session) — `SUBAGENT-MODEL.md`.

## Limits

| Context | Cap |
|---------|-----|
| `*-developer` children | **≤ 2** concurrent / per task wave |
| `orchestrate-*` parallel Tasks | **≤ 4** concurrent (existing skill caps; wave if more) |
| `qa_checklist` | **No** Task — CONTINUITY/STORY only (`ROSTER.md`) |

Model selection on Cursor Task: follow `SUBAGENT-MODEL.md` (omit `model` by default — **same model as parent session**).

## Receipt and synthesis

- Child I/O is Caveman-scoped: prompts, style, and returns honor Caveman when ON; end with receipt rows (Caveman ON: required; OFF: still prefer receipt / tight bullets).
- Parent synthesizes into CONTINUITY / chat — **facts and paths only**.
- Do not dump full specialist transcripts into CONTINUITY.

## Must not

- Hard-fail when `subagents` is `none` or Task tool is unavailable
- Mint `native` in registry without host Task/equivalent
- Paste `_shared/*-guidelines/`, rules, or pipeline bodies into child prompts
- Exceed developer ≤2 or orchestrate ≤4 caps without user-approved wave/série
- Replace ROSTER / RECEIPT / SUBAGENT-MODEL — **load them** when needed
- Edit twins (`cursor-dev-toolkit` / `antigravity-dev-toolkit`)

## Cross-refs (lazy-load)

| File | Use |
|------|------|
| `core/policy/orchestrator-session.md` | Always-on parent/orchestrator policy |
| `ROSTER.md` | Which specialist roles / `needs_*` |
| `RECEIPT.md` | Receipt schema + refusal tokens (Caveman-scoped child returns) |
| `SUBAGENT-MODEL.md` | Task `model` parameter policy (default = parent session model) |
| `ROUTING.md` | Stack → `*-developer` |
| `skills/_shared/caveman/CAVEMAN.md` | Child prompt/style/return compression |
| `docs/SPAWN.md` | Host spawn matrix, product evidence, Antigravity probe |

## Acceptance mapping

| PRD | Covered here |
|-----|----------------|
| CA1 | Native vs fallback for orchestrate / code-review; no Task hard-fail |
| CA2 | Developer ≤2; paths + receipt; no guideline paste; trivial in-parent; `none` → in-parent |
