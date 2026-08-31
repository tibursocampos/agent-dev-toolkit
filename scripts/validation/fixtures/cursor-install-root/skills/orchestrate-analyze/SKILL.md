---
name: orchestrate-analyze
description: Orchestrated Delivery O1: triage a feature, spawn conditional Task specialists, write FEATURE.md + CONTINUITY + US/TS under features/NNN-slug/. No app code. Use when invoking /orchestrate-analyze.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/rules/guardrails.mdc`
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

# Skill: orchestrate-analyze

## Trigger

Invoke when the user asks for: `/orchestrate-analyze`, `orchestrate analyze`, `/orchestrate-analyze`, or Orchestrated Delivery analysis for a complex / multi-story / brownfield feature.

Optional: pasted feature description, existing notes path, or prior refine output.

## Outcome

Under the resolved classic feature root (`STORAGE.md`, `$Workflow = classic`):

1. `features/NNN-slug/FEATURE.md` - triage, scope, nature, complexity, `needs_*`
2. `features/NNN-slug/CONTINUITY.md` - phase, decisions, typed handoff, **Memory-bank** path + status (`fresh` \| `refreshed` \| `created`; **`refreshed`** after ARCH **sim** / point-promote)
3. `features/NNN-slug/USnn/STORY.md` and/or `TSnn/STORY.md` - BDD + scorecard summary + deps

**Step 0 (required):** Memory Bank Gate (`MEMORY-BANK.md`, policy `auto`) **before** triage. Resolve `bank_root` via `STORAGE.md` (`$Cwd/memory-bank/` or `<classic.path>/memory-bank/`) - **never** under `features/NNN-slug/`.

**Human gate:** backlog must be explicitly approved (`sim` / `ajustar` / `cancelar`) before O2. **Silence is not approval** (RN01). Do **not** mark approved if required specialist folders are missing or cited non-feature `.md` was not promoted (pointer-only = fail O1). When greenfield / `needs_domain` without an established style, an **architecture confirm gate** (ARCH draft → **sim** → ARCH approved) runs after the architect pass and before treating style as selected (`reference.md` § Architecture confirm gate). Brownfield skips **style re-pick** only — still write mirror ARCH.

Orchestrator **does not** implement application code. When a `needs_*` flag (or brownfield) is true, specialists **must** write notes under story `ANALYSIS/` / `ARCH/` / `SEC/` (folder on disk required). `REFINE/` remains on demand. Do **not** route those notes to CONTINUITY as a substitute.

Does **not** write PRD/PLAN (that is O2 via `sdd-spec` / `sdd-plan` contracts). Does **not** call trackers.

**Mental map (ids unchanged):** O1 ≈ **explore** (FEATURE, stories, specialists). O2 ≈ FEATURE+PRD+CHANGE; O3 ≈ apply. See `CHANGE-CONTRACT.md`.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Pipeline Orchestrated Delivery, confirm, paths | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage, manifest, feature tree | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/STORAGE.md` |
| Step 0 Memory Bank Gate | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Memory-bank create/refresh | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/memory-bank-init/SKILL.md` |
| Roster, `needs_*`, triage table | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/agents/ROSTER.md` |
| Spawn native vs fallback (capability `subagents`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/agents/SPAWN.md` |
| Task subagent model (default omit; rare premium gate) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack routing (implement later) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/agents/ROUTING.md` |
| Templates | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/templates/features/{FEATURE,CONTINUITY,TREE}.md`, `.../story/STORY.md` |
| Specialist prompts | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/agents/prompts/{repo_analyst,architect,security,database,impact,risk,generate-story}.md` — **one file per spawned specialist** |
| Process details, triage, NuGet, Must not | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/orchestrate-analyze/reference.md` |
| Scorecard rubric (reuse) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/refine-story/reference.md` |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/rules/context-management.mdc` |

**Never by default:** do not preload all specialist prompts, all templates, or ROSTER+SPAWN+SUBAGENT-MODEL+ROUTING+MEMORY-BANK together. Do not dump guideline packs into Task child prompts.

**Progressive load:** contracts first (`PIPELINE.md` + `STORAGE.md`); fan-out only on trigger (`MEMORY-BANK.md` at Step 0, `ROSTER.md` when setting `needs_*`, `SPAWN.md` before Task, **one** prompt per spawn, `reference.md` for Process step details / triage / NuGet / architecture-confirm / Must not).

## Reference routing

| Situation | Path |
|-----------|------|
| Gate / Orchestrated Delivery / promote | `PIPELINE.md` |
| Feature root / bank root / portable paths | `STORAGE.md` |
| Step 0 Memory Bank | `MEMORY-BANK.md` |
| Set `needs_*` / brownfield spawn rules | `ROSTER.md` |
| Before any Task / fallback | `SPAWN.md` |
| Premium Task `model` gate (rare) | `SUBAGENT-MODEL.md` |
| Implement-later stack hint | `ROUTING.md` |
| Process steps / triage / NuGet / ARCH confirm / Must not | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/orchestrate-analyze/reference.md` |
| Scorecard /100 → STORY | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/refine-story/reference.md` |

## Process

Read `reference.md` for procedural tables, prompts, and checklists under each step. Do not skip gates.

### Step -1b - Caveman Mode (Lite cap)
Apply Lite caveman prefs when active. Details: `reference.md` § Process — Caveman (Lite cap).

### 1. Gate check
Report the Step -1 gate checklist in chat. Load `PIPELINE.md` (Orchestrated Delivery) and `SESSION.md`. **STOP** if any gate unchecked.

### 2. Resolve storage
Load `STORAGE.md` (`$Workflow = classic`); resolve feature + bank roots; path sanitize; gitignore per STORAGE. Details: `reference.md` § Process — Resolve storage.

### 3. Step 0 - Memory Bank Gate
Follow `MEMORY-BANK.md` (policy default **`auto`**). Bank root = resolved `bank_root` — **never** under `features/NNN-slug/`. Confirm before bank write; healthy → selective read only. Record path + status for CONTINUITY; after ARCH **sim** point-promote `architecture.md` and set `refreshed`. Details: `reference.md` § Step 0 - Memory Bank Gate.

### 4. Collect description and triage
Ask/reuse Prior context; promote cited non-feature `.md` per `PIPELINE.md`. Set complexity/nature/scope + `needs_*` via `ROSTER.md` (TE01 / RF01). Details: `reference.md` § Process — Collect description / promote + § Triage decision table.

### 5. Trivial shortcut
If `trivial`: offer shortcut (details: `reference.md` § Process — Trivial shortcut). Continue O1 only if user chooses **2**.

### 6. Allocate NNN-slug and scaffold tree
Glob next NNN; confirm portable path; scaffold templates + flag-gated `ANALYSIS/` / `ARCH/` / `SEC/`. Details: `reference.md` § Process — Allocate NNN-slug and scaffold + § Feature tree layout.

### 7. Spawn Task specialists (conditional, parallel)
SPAWN first; spawn per ROSTER when `native`; fallback in-parent write; cap ≤4; omit Task `model` by default. Details: `reference.md` § Process — Spawn Task specialists + § Flag -> specialist mapping.

### 7b. Architecture confirm gate (greenfield / `needs_domain`)
ARCH draft → operator **sim** / ajustar / cancelar → approved + point-promote. Brownfield: skip style re-pick only; still write mirror ARCH. Details: `reference.md` § Process — Architecture confirm answers + § Architecture confirm gate.

### 8. Synthesize artifacts
Merge into FEATURE / CONTINUITY / STORY (scorecard via `refine-story/reference.md`). Details: `reference.md` § Process — Synthesize artifacts + § CONTINUITY update checklist.

### 9. Human backlog approval (RN01)
Required folders + promote first; present backlog; **sim** / ajustar / cancelar (silence ≠ approval). Details: `reference.md` § Process — Backlog approval + O2 handoff + § Approval gate copy.

### 10. Approve -> CONTINUITY + O2 handoff
On **sim**: approve statuses; typed O2 handoff. Details: `reference.md` § Process — Backlog approval + O2 handoff + § Canonical handoff strings.

### 11. Context pressure (TE02 / RNF02)
Honor `context-management.mdc`; persist CONTINUITY; resume invoke. Details: `reference.md` § Process — Context pressure.

## Must not

Enforce the full list in `reference.md` § Must not (full). Critical always-on: no app code; no PRD/PLAN; no skip Step 0 / backlog **sim** / ARCH confirm; no missing `ANALYSIS|ARCH|SEC` when flags require them; no hard-fail when Task unavailable (fallback in-parent write); portable paths only.

## Handoff

| Situation | Next |
|-----------|------|
| Backlog approved | `/orchestrate-deliver - <portable-feature-path>` |
| Context pause mid-O1 | `/orchestrate-analyze - <portable-feature-path>` |
| Trivial after triage | `/developer` or stack `*-developer` |
| Single clear story, skip O2 multi | `/sdd-spec` (Classic SDD) after STORY exists |
| Informal single item only | `/refine-story` (Backlog Refine) |

### Canonical O2 handoff (exact pattern)

```text
/orchestrate-deliver - <portable-feature-path>
```
