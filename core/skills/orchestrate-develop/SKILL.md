---
name: orchestrate-develop
description: Orchestrated Delivery O3: one Task subagent per PLAN step (sdd-develop contract); parent never writes app code. Updates CONTINUITY; handoff to code-review. Use when invoking /orchestrate-develop.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (required for orchestrate-*)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: orchestrate-develop

## Trigger

Invoke when the user asks for: `/orchestrate-develop`, `orchestrate develop`, `/orchestrate-develop`, or Orchestrated Delivery O3 after O2 handoff.

Required: full feature path **or** a specific `PLAN/PLAN_NNN_*.md` path under a story.

## Outcome

1. Pending PLAN step(s) executed via Task children when `subagents=native` (`SPAWN.md`), each following the **`sdd-develop` contract** (one PLAN step per child / session); when `subagents=none` or Task unavailable → **fallback** handoff to manual `/sdd-develop` (parent never writes app code; never hard-fail)
2. Feature `CONTINUITY.md` updated (phase `develop`, progress, typed next invoke, **Memory-bank** path + status)
3. Handoff to `code-review` (`- single` or `- multi-angle`; skill asks if omitted) and/or next step / next story

**Step 0 (required):** Memory Bank Gate (`MEMORY-BANK.md`, policy `auto`) **before** building the step queue / spawning children. Resolve `bank_root` via `STORAGE.md`. CONTINUITY stays the feature phase/handoff source.

**Step N (after code changes):** when at least one develop child succeeded with app file changes, run `memory-bank-init` mode **`refresh-light`** at `bank_root` before final handoff (`MEMORY-BANK.md` Step N). Confirm (pt-BR) first.

**Parent orchestrator never** writes application code, never marks multiple PLAN steps done in one child, and never bypasses `sdd-develop` gates (`step_confirmed`, tests before complete).

**Alternative (always valid):** user runs manual `/sdd-develop - <portable-plan-path> - Step N` without this skill (RF05 / CA5). Manual Classic SDD does **not** require memory-bank (CA7).

**Mental map (ids unchanged):** O3 ≈ **apply** (implement PLAN steps via `sdd-develop`). O1 ≈ explore; O2 ≈ FEATURE+PRD+CHANGE. See `CHANGE-CONTRACT.md`.

**Evidence verifier (REQ-005 / CA4):** children record `features/NNN-slug/EVD/` + `STATE.md` and run `validate-evidence` inside `sdd-develop`. **Verifier ≠ O3** — do **not** use O3 / Task parallelism as the evidence verifier mechanism (sequential script gate only). Levels: `off` \| `cheap` \| `standard` \| `strict`. Contract: `EVD-STATE-CONTRACT.md`.

**Living loop / TRACE (REQ-006 / CA5):** at feature-wave close, children (or the final develop child) append `features/NNN-slug/TRACE.jsonl` and run **converge → sync current → archive**, then `validate-trace -RequireArchiveComplete`. Parent must **not** use O3 parallelism as the archive verifier. Contract: `TRACE-ARCHIVE-CONTRACT.md`.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Pipeline Orchestrated Delivery, paths | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Step 0 Memory Bank Gate | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Memory-bank create/refresh | `{{TOOLKIT_ROOT}}/skills/memory-bank-init/SKILL.md` |
| Develop contract (source of truth) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/SKILL.md` + `{{TOOLKIT_ROOT}}/skills/sdd-develop/reference.md` |
| SESSION gates | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md` |
| CONTINUITY template | `{{TOOLKIT_ROOT}}/skills/_shared/templates/features/CONTINUITY.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/references/<section>.md` |
| Spawn native vs fallback (capability `subagents`) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Task subagent model (default omit; rare premium gate) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Code review (ask mode) | `{{TOOLKIT_ROOT}}/skills/code-review/SKILL.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |

**Never by default:** do not preload `sdd-develop` + all developer guideline packs into the parent, or paste guideline bodies into develop children. Parent loads contracts and SPAWN; children load `sdd-develop` for their one step.

**Progressive load:** `PIPELINE.md` + `STORAGE.md` first; fan-out to `MEMORY-BANK.md` at Step 0, `SPAWN.md` before spawn, `sdd-develop` contract into the child prompt path only, and **one** `references/<section>.md` per Process step — never full `reference.md` when a section file exists (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Gate / Orchestrated Delivery | `PIPELINE.md` |
| Feature / PLAN / bank roots | `STORAGE.md` |
| Step 0 Memory Bank | `MEMORY-BANK.md` |
| Before Task / fallback to manual develop | `SPAWN.md` |
| Child implement contract | `{{TOOLKIT_ROOT}}/skills/sdd-develop/SKILL.md` |
| Preconditions / Step 0 / Step N refresh-light | `references/preconditions.md` |
| Anti-bypass checklist (CA5) | `references/anti-bypass.md` |
| Step queue / spawn child / Task skeleton | `references/step-queue-spawn.md` |
| Step 5.5 post-implement verifier (`verify_mode`) | `references/step-verifier.md` |
| Safe parallelism | `references/parallelism.md` |
| CONTINUITY / handoff / stop conditions | `references/continuity-handoff.md` |
| Contract reuse / boundaries / invoke strings | `references/contract-boundaries.md` |
| Caveman / resolve feature / PLAN set | `references/process-common.md` |
| Must not (full) | `references/must-not.md` |
| Review handoff | `{{TOOLKIT_ROOT}}/skills/code-review/SKILL.md` |

## Process

Read `references/<section>.md` for procedural tables, prompts, and checklists under each step — **not** full `reference.md`. Do not skip gates.

### Step -1b - Caveman Mode (Full cap)
Apply Full caveman prefs when active. Read `references/process-common.md` § Process — Caveman (Full cap).

### 1. Gate check
Report the Step -1 gate checklist in chat. Load `PIPELINE.md` (Orchestrated Delivery) and `SESSION.md`. **STOP** if any gate unchecked. Ask user **sim** before spawning the first develop child.

### 2. Resolve feature / PLAN set
Load `STORAGE.md`; resolve feature + `bank_root`; path sanitize; build PLAN queue or **STOP** if missing. Read `references/process-common.md` § Process — Resolve feature / PLAN set.

### 3. Step 0 - Memory Bank Gate
Follow `MEMORY-BANK.md` (policy default **`auto`**). Bank root = resolved `bank_root` - **not** under `features/`. Pass **`bank_path`** into every develop child as read-only Prior context. Read `references/preconditions.md` § Step 0 - Memory Bank Gate.

### 4. Build step queue (deps)
Parse pending steps; respect Deps; present queue; wait for **sim**. Read `references/step-queue-spawn.md`.

### 5. Spawn exactly one step child (CA5)
SPAWN first; one Task = one PLAN step = full `sdd-develop` contract; omit Task `model` by default; fallback to manual `/sdd-develop` when Task unavailable. Parent updates CONTINUITY only after child returns. Read `references/step-queue-spawn.md` and `references/anti-bypass.md`.

### 5.5 Post-implement verifier (opt-in)
When `preferences.json` has `verify_mode: true`, spawn a **read-only verifier child** after a successful implementer return and **before** CONTINUITY update / next spawn. Default `verify_mode` is `false` — skip when unset. Read `references/step-verifier.md`.

### 6. Safe parallelism (optional)
Default **serial**. Parallel only when all independence conditions + user **sim** + distinct SESSION files; cap ≤4. Read `references/parallelism.md`.

### 7. Stop conditions
Stop on story/feature done, context pressure, child blocked, or **cancelar**. Read `references/continuity-handoff.md` § Process — Stop conditions.

### 8. CONTINUITY
Update phase / Memory-bank / estado / handoff at each milestone. Read `references/continuity-handoff.md`.

### 9. Step N - Memory Bank refresh-light (after code changes)
When a child changed app files: confirm → `refresh-light` → CONTINUITY `refreshed` (or skip). Read `references/continuity-handoff.md` § Process — Step N refresh-light and `references/preconditions.md` § Step N - refresh-light.

### 10. Handoff - code-review + manual alternative
Emit review + manual `/sdd-develop` + continue O3 strings. Read `references/continuity-handoff.md` § Handoff copy.

## Anti-bypass checklist (must enforce)

Parent and children **must not** bypass CA5. Enforce the full table in `references/anti-bypass.md` before every spawn and before marking any step done. Critical: parent writes **no** app code; one child = one PLAN step; **sim** before next spawn; PLAN-scoped SESSION files for parallel children.

## Must not

Enforce the full list in `references/must-not.md`. Critical always-on: no parent app code; no multi-step children; no hard-fail when Task unavailable (fallback `/sdd-develop`); portable paths only.

## Handoff

| Situation | Next |
|-----------|------|
| Next PLAN step | New chat -> `orchestrate-develop` **or** `sdd-develop - <plan> - Step N` |
| Story/feature done | `/code-review` (pass `- single` / `- multi-angle`, or let skill ask) |
| Missing PLAN | `orchestrate-deliver` / `sdd-plan` |
| Prefer no orchestrator | Manual `sdd-develop` only |

### Canonical strings

```text
/orchestrate-develop - <portable-feature-path>
```

```text
/sdd-develop - <portable-plan-path> - Step N
```

```text
/code-review
/code-review - multi-angle
```
