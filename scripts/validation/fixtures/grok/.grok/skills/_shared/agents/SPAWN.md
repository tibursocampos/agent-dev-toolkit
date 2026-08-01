# Portable spawn contract (Forma C + developers)

Canonical contract for **when** and **how** to spawn specialist children across Tier 1 hosts. Orthogonal to **which** roles (`ROSTER.md`), **receipt shape** (`RECEIPT.md`), and **Task model** (`SUBAGENT-MODEL.md`).

Install path after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/agents/SPAWN.md`

**Path decision:** stay under `_shared/agents/` — not `core/router/` (router is L0 index only). Human Tier-1 matrix: `docs/SPAWN.md`.

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
  ├─ trivial (*-developer)     → in-parent (always)
  ├─ subagents == native       → prefer Task / host equivalent (table above)
  └─ else                      → fallback in-parent or documented handoff
                                 NEVER hard-fail only because Task is absent
```

| Consumer | Prefer when `native` | Fallback when `none` |
|----------|----------------------|----------------------|
| `orchestrate-analyze` / `deliver` / `develop` | Task (or host equivalent) per roster/caps | Same specialist work **in-parent**, or handoff note in CONTINUITY / chat |
| `code-review` multi-angle | Parallel specialist Tasks / host equivalents | Sequential in-parent angles |
| `*-developer` medium/complex | Up to **2** children | Same outcome in-parent |

**RN:** Subagent-first = **preference + fallback**, never hard-require Task.

## Child payload (minimum)

When spawning (native path):

1. Pass **scoped paths** (files/dirs the child may read/write).
2. Require end-of-pass **receipt** per `RECEIPT.md` (lazy-load that file — do not paste its body).
3. Point to role prompt under `skills/_shared/agents/prompts/` when Forma C roster applies.
4. **Do not** paste guideline packs, full SKILL bodies, or large policy dumps into the child prompt.

## Limits

| Context | Cap |
|---------|-----|
| `*-developer` children | **≤ 2** concurrent / per task wave |
| `orchestrate-*` parallel Tasks | **≤ 4** concurrent (existing skill caps; wave if more) |
| `qa_checklist` | **No** Task — CONTINUITY/STORY only (`ROSTER.md`) |

Model selection on Cursor Task: follow `SUBAGENT-MODEL.md` (omit `model` by default).

## Receipt and synthesis

- Child ends with receipt rows (Caveman ON: required; OFF: still prefer tight bullets).
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
| `ROSTER.md` | Which specialist roles / `needs_*` |
| `RECEIPT.md` | Receipt schema + refusal tokens |
| `SUBAGENT-MODEL.md` | Task `model` parameter policy |
| `ROUTING.md` | Stack → `*-developer` |
| `docs/SPAWN.md` | Tier-1 host matrix, product evidence, Antigravity probe |

## Acceptance mapping

| PRD | Covered here |
|-----|----------------|
| CA1 | Native vs fallback for orchestrate / code-review; no Task hard-fail |
| CA2 | Developer ≤2; paths + receipt; no guideline paste; trivial in-parent; `none` → in-parent |
