---
name: orchestrate-analyze
description: Orchestrated Delivery O1: triage a feature, spawn conditional Task specialists, write FEATURE.md + CONTINUITY + US/TS under features/NNN-slug/. No app code. Use when invoking /orchestrate-analyze.
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

**Human gate:** backlog must be explicitly approved (`sim` / `ajustar` / `cancelar`) before O2. **Silence is not approval** (RN01). Do **not** mark approved if required specialist folders are missing or cited non-feature `.md` was not promoted (pointer-only = fail O1). When greenfield / `needs_domain` without an established style, an **architecture confirm gate** (ARCH draft → **sim** → ARCH approved) runs after the architect pass and before treating style as selected (`references/arch-confirm.md`). Brownfield skips **style re-pick** only — still write mirror ARCH.

Orchestrator **does not** implement application code. When a `needs_*` flag (or brownfield) is true, specialists **must** write notes under story `ANALYSIS/` / `ARCH/` / `SEC/` (folder on disk required). `REFINE/` remains on demand. Do **not** route those notes to CONTINUITY as a substitute.

Does **not** write PRD/PLAN (that is O2 via `sdd-spec` / `sdd-plan` contracts). Does **not** call trackers.

**Mental map (ids unchanged):** O1 ≈ **explore** (FEATURE, stories, specialists). O2 ≈ FEATURE+PRD+CHANGE; O3 ≈ apply. See `CHANGE-CONTRACT.md`.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Pipeline Orchestrated Delivery, confirm, paths | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage, manifest, feature tree | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Step 1 triage — intent classification (before Step 0 when not full O1) | `{{TOOLKIT_ROOT}}/skills/orchestrate-analyze/references/intent-classification.md` |
| Step 0 Memory Bank Gate | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Memory-bank create/refresh | `{{TOOLKIT_ROOT}}/skills/memory-bank-init/SKILL.md` |
| Roster, `needs_*`, triage table | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md` |
| Spawn native vs fallback (capability `subagents`) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Task subagent model (default omit; rare premium gate) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack routing (implement later) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROUTING.md` |
| Templates | `{{TOOLKIT_ROOT}}/skills/_shared/templates/features/{FEATURE,CONTINUITY,TREE}.md`, `.../story/STORY.md` |
| Specialist prompts | `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/{repo_analyst,architect,security,database,impact,risk,generate-story}.md` — **one file per spawned specialist** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/orchestrate-analyze/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/orchestrate-analyze/references/<section>.md` |
| Scorecard rubric (reuse) | `{{TOOLKIT_ROOT}}/skills/refine-story/references/scorecard-rubric.md` |
| Scorecard template (optional shape) | `{{TOOLKIT_ROOT}}/skills/refine-story/references/scorecard-template.md` |
| Story sizing (synthesis / merge policy) | `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/story-sizing.md` |
| Persona / Product intent (US only) | `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/persona-context.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |

**Never by default:** do not preload all specialist prompts, all templates, or ROSTER+SPAWN+SUBAGENT-MODEL+ROUTING+MEMORY-BANK together. Do not dump guideline packs into Task child prompts. Do not preload `persona-context.md` except when synthesizing **User Story** Product intent.

**Progressive load:** contracts first (`PIPELINE.md` + `STORAGE.md`); fan-out only on trigger (`MEMORY-BANK.md` at Step 0, `ROSTER.md` when setting `needs_*`, `SPAWN.md` before Task, **one** prompt per spawn, **one** `references/<section>.md` per Process step — never full `reference.md` when a section file exists (`SKILL-REFERENCE-RETRIEVAL.md`).

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
| Step 1 intent classification (triage entry) | `references/intent-classification.md` |
| Step 0 Memory Bank detail | `references/memory-bank-gate.md` |
| Triage / collect / trivial / NuGet | `references/triage.md` |
| Spawn / specialist map | `references/spawn-map.md` |
| ARCH confirm gate | `references/arch-confirm.md` |
| Scaffold / synthesize / CONTINUITY | `references/story-synthesis.md` |
| Boundaries / handoff strings | `references/boundaries-handoff.md` |
| Caveman / storage / approval / context | `references/process-common.md` |
| Must not (full) | `references/must-not.md` |
| Scorecard /100 → STORY | `{{TOOLKIT_ROOT}}/skills/refine-story/references/scorecard-rubric.md` |
| Story sizing / merge policy | `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/story-sizing.md` |
| Product intent (US Who/Job/Outcome) | `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/persona-context.md` |

## Process

Read `references/<section>.md` for procedural tables, prompts, and checklists under each step — **not** full `reference.md`. Do not skip gates.

### Step -1b - Caveman Mode (Lite cap)
Apply Lite caveman prefs when active. Read `references/process-common.md` § Process — Caveman (Lite cap).

### 1. Gate check
Report the Step -1 gate checklist in chat. Load `PIPELINE.md` (Orchestrated Delivery) and `SESSION.md`. **STOP** if any gate unchecked.

### 2. Resolve storage
Load `STORAGE.md` (`$Workflow = classic`); resolve feature + bank roots; path sanitize; gitignore per STORAGE. Read `references/process-common.md` § Process — Resolve storage.

### 3. Intent classification (Step 1 triage entry)
Load `references/intent-classification.md`. Classify input (Existing Feature \| New Feature \| Product Initiative \| Problem/Need \| Idea); map to Classic SDD vs Backlog Refine vs full O1. On early handoff (`/refine-story`, `/sdd-spec`, `/developer`), confirm (pt-BR) and **STOP** — skip Step 0 unless operator chooses to continue O1 anyway. Record intent when continuing full O1.

### 4. Step 0 - Memory Bank Gate
Follow `MEMORY-BANK.md` (policy default **`auto`**). Bank root = resolved `bank_root` — **never** under `features/NNN-slug/`. Confirm before bank write; healthy → selective read only. Record path + status for CONTINUITY; after ARCH **sim** point-promote `architecture.md` and set `refreshed`. Read `references/memory-bank-gate.md`.

### 5. Collect description and triage
Ask/reuse Prior context; promote cited non-feature `.md` per `PIPELINE.md`. Set complexity/nature/scope + `needs_*` via `ROSTER.md` (TE01 / RF01). Read `references/triage.md` (after intent from step 3).

### 6. Trivial shortcut
If `trivial`: offer shortcut (read `references/triage.md` § Process — Trivial shortcut). Continue O1 only if user chooses **2**.

### 7. Allocate NNN-slug and scaffold tree
Glob next NNN; confirm portable path; scaffold templates + flag-gated `ANALYSIS/` / `ARCH/` / `SEC/`. Read `references/story-synthesis.md`.

### 8. Spawn Task specialists (conditional, parallel)
SPAWN first; spawn per ROSTER when `native`; fallback in-parent write; cap ≤4; omit Task `model` by default. Read `references/spawn-map.md`.

### 8b. Architecture confirm gate (greenfield / `needs_domain`)
ARCH draft → operator **sim** / ajustar / cancelar → approved + point-promote. Brownfield: skip style re-pick only; still write mirror ARCH. Read `references/arch-confirm.md`.

### 9. Synthesize artifacts
Load `story-sizing.md`; apply **merge policy** (merge file/layer fragments; split when >~8 refine steps or independent consumers). Merge into FEATURE / CONTINUITY / STORY (scorecard via `refine-story/references/scorecard-rubric.md`). `FEATURE.md` story table must include **Rationale** and **Product intent** per row (Who/Job/Outcome or `n/a`; lazy-load `persona-context.md` for User Stories only). Read `references/story-synthesis.md`.

### 10. Human backlog approval (RN01)
Required folders + promote first; present backlog; **sim** / ajustar / cancelar (silence ≠ approval). Read `references/process-common.md` § Process — Backlog approval + O2 handoff and `references/arch-confirm.md` § Approval gate copy.

### 11. Approve -> CONTINUITY + O2 handoff
On **sim**: approve statuses; typed O2 handoff. Read `references/process-common.md` § Process — Backlog approval + O2 handoff and `references/boundaries-handoff.md` § Canonical handoff strings.

### 12. Context pressure (TE02 / RNF02)
Honor `context-management.mdc`; persist CONTINUITY; resume invoke. Read `references/process-common.md` § Process — Context pressure.

## Must not

Enforce the full list in `references/must-not.md`. Critical always-on: no app code; no PRD/PLAN; no skip Step 0 / backlog **sim** / ARCH confirm; no missing `ANALYSIS|ARCH|SEC` when flags require them; no hard-fail when Task unavailable (fallback in-parent write); portable paths only.

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
