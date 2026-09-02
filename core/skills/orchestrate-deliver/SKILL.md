---
name: orchestrate-deliver
description: Orchestrated Delivery O2: run sdd-spec then sdd-plan per approved US/TS; human-approve PRD/PLAN; emit multi-path handoff. No app code. Use when invoking /orchestrate-deliver.
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

# Skill: orchestrate-deliver

## Trigger

Invoke when the user asks for: `/orchestrate-deliver`, `orchestrate deliver`, `/orchestrate-deliver`, or Orchestrated Delivery O2 after an approved O1 backlog.

Required: full feature path (or resolvable `features/NNN-slug/`).

## Outcome

Under each approved story folder (`USnn` / `TSnn`):

1. `PRD/NNN_*.md` - via **`sdd-spec` contract** (what, not how)
2. `PLAN/PLAN_NNN_*.md` - via **`sdd-plan` contract** (baby steps)
3. Feature-root `CHANGE.md` - **required when FEATURE Nature is brownfield** (ADDED \| MODIFIED \| REMOVED vs current `memory-bank/` docs; **greenfield** must not force an empty stub) — `CHANGE-CONTRACT.md` / `sdd-spec`
4. Feature `CONTINUITY.md` - phase `deliver`, decisions, typed multi-path handoff, **Memory-bank** path + status

**Mental map (ids unchanged):** O2 ≈ **FEATURE + PRD + CHANGE** (then PLAN). O1 ≈ explore; O3 ≈ apply. Skill ids stay `orchestrate-*`.

**Step 0 (required):** Memory Bank Gate (`MEMORY-BANK.md`, policy `auto`) **before** mode selection / story contracts. Resolve `bank_root` via `STORAGE.md` - never under `features/`. CONTINUITY remains the feature phase/handoff source; bank does not replace it.

**Human gate:** PRD/PLAN approval per story **or** batch (`sim` / `ajustar` / `cancelar`). Silence ≠ approval (RN01).

Orchestrator **does not** implement application code. **Does not** rewrite `sdd-spec` / `sdd-plan` process - load those skills and run their contracts per story. **Does not** call trackers.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Command playbook (step discovery after gates) | `{{TOOLKIT_ROOT}}/skills/orchestrate-deliver/references/command.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Pipeline Orchestrated Delivery, confirm, paths | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Invocation contexts (`direct` vs `orchestrated`, `IC-DIRECT-ORCHESTRATED`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` |
| Storage, manifest, feature tree | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Step 0 Memory Bank Gate | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Memory-bank create/refresh | `{{TOOLKIT_ROOT}}/skills/memory-bank-init/SKILL.md` |
| CONTINUITY / FEATURE templates | `{{TOOLKIT_ROOT}}/skills/_shared/templates/features/` |
| Spec contract | `{{TOOLKIT_ROOT}}/skills/sdd-spec/SKILL.md` (+ `{{TOOLKIT_ROOT}}/skills/sdd-spec/reference.md` as needed) |
| Plan contract | `{{TOOLKIT_ROOT}}/skills/sdd-plan/SKILL.md` (+ `{{TOOLKIT_ROOT}}/skills/sdd-plan/reference.md` as needed) |
| CHANGE brownfield / current | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md` |
| Preflight PRD→PLAN→CHANGE (`REQ-004` / CA4) | `{{TOOLKIT_ROOT}}/skills/orchestrate-deliver/references/preflight-prd-plan-change.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/orchestrate-deliver/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/orchestrate-deliver/references/<section>.md` |
| Spawn native vs fallback (capability `subagents`) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Task subagent model (default omit; rare premium gate) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |

**Never by default:** do not preload `references/command.md` before Step -1 gates; do not preload both `sdd-spec` and `sdd-plan` full bodies plus all templates and SPAWN/SUBAGENT-MODEL before mode selection. Load contracts when running that story stage; load SPAWN only when choosing paralelo / spawning drafts.

**Progressive load:** `PIPELINE.md` + `STORAGE.md` first; after gates load `references/command.md` for step discovery; fan-out to `MEMORY-BANK.md` at Step 0, then `sdd-spec` → `sdd-plan` per story, and **one** `references/<section>.md` per Process step — never full `reference.md` when a section file exists (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Command playbook (step discovery) | `references/command.md` |
| Gate / Orchestrated Delivery / siblings STOP | `PIPELINE.md` |
| Feature / bank roots | `STORAGE.md` |
| Step 0 Memory Bank | `MEMORY-BANK.md` |
| Before paralelo Task wave | `SPAWN.md` |
| Write PRD (after **sim**) | `{{TOOLKIT_ROOT}}/skills/sdd-spec/SKILL.md` |
| Write PLAN (after **sim**) | `{{TOOLKIT_ROOT}}/skills/sdd-plan/SKILL.md` |
| Preconditions / Step 0 / siblings STOP | `references/preconditions.md` |
| Mode série vs paralelo | `references/mode-selection.md` |
| Per-story contracts / Task child skeleton | `references/per-story-contracts.md` |
| Approval gates / answers | `references/approval-gates.md` |
| CONTINUITY / handoff / cross-artifact | `references/continuity-handoff.md` |
| Preflight PRD→PLAN→CHANGE before O3 | `references/preflight-prd-plan-change.md` |
| Caveman / resolve / context pressure | `references/process-common.md` |
| Boundaries / Must not | `references/boundaries-must-not.md` |

## Process

After gates: **Read `references/command.md`** for ordered step discovery (do not dump this Process section into child prompts). Then load `references/<section>.md` for the current step only — **not** full `reference.md`. Do not skip gates.

### Step -1b - Caveman Mode (Lite cap)
Apply Lite caveman prefs when active. Read `references/process-common.md` § Process — Caveman (Lite cap).

### 1. Gate check
Report the Step -1 gate checklist in chat. Load `PIPELINE.md` (Orchestrated Delivery) and `SESSION.md`. **STOP** if any gate unchecked.

### 1b. Resolve invocation context
Load `INVOCATION-CONTEXTS.md`. This skill defaults to `orchestrated` (`IC-DIRECT-ORCHESTRATED`). Apply orchestrated observable rules; pass `invocation_context: orchestrated` into per-story `sdd-spec` / `sdd-plan` runs and Task drafts (path cite only).

### 2. Resolve feature and storage
Load `STORAGE.md`; resolve feature + bank roots; path sanitize; **STOP** if FEATURE/CONTINUITY missing. Read `references/process-common.md` § Process — Resolve feature and storage.

### 3. Step 0 - Memory Bank Gate
Follow `MEMORY-BANK.md` (policy default **`auto`**). Bank root = resolved `bank_root` - **not** under `features/`. Update CONTINUITY Memory-bank fields; pass `bank_path` into parallel draft Tasks read-only. Read `references/preconditions.md` § Step 0 - Memory Bank Gate.

### 4. Preconditions (approved backlog)
Verify backlog **sim**/approved; discover stories; **STOP** if flag-gated `ANALYSIS|ARCH|SEC` missing. Read `references/preconditions.md`.

### 5. Choose mode (RF03)
Ask série vs paralelo (never assume); load `SPAWN.md` before paralelo; omit Task `model` by default. Read `references/mode-selection.md`.

### 6. Per-story contracts (reuse, do not rewrite)
Run `sdd-spec` then `sdd-plan` per story (série in-parent, or paralelo draft-only children + parent Write after **sim**). Per-story STOP if required siblings missing. Read `references/per-story-contracts.md`.

### 7. Approval - per story or batch (RN01)
Present summary; **sim** / ajustar / cancelar (por história | lote). Read `references/approval-gates.md`.

### 8. CONTINUITY + multi-path handoff (RF04)
Update CONTINUITY phase `deliver`; run **cross-artifact analyze** (`CHANGE-CONTRACT.md`: Nature↔CHANGE, complexity↔TASKS, validate-change when CHANGE exists); run **preflight PRD→PLAN→CHANGE** (`references/preflight-prd-plan-change.md` / `Invoke-PrdPlanChangePreflight.ps1`) and **STOP** O3 handoff on block; emit manual `sdd-develop` + O3 handoff paths only when allow. Read `references/continuity-handoff.md`.

### 9. Context pressure (TE02 / RNF02)
Honor `context-management.mdc`; persist CONTINUITY; resume invoke. Read `references/process-common.md` § Process — Context pressure.

## Must not

Enforce the full list in `references/boundaries-must-not.md`. Critical always-on: no app code; no PRD/PLAN without required siblings; no child disk Write of PRD/PLAN; no silence-as-**sim**; no hard-fail when Task unavailable (fallback série in-parent); portable paths only; do not ignore `IC-DIRECT-ORCHESTRATED` (`INVOCATION-CONTEXTS.md`).

## Handoff

| Situation | Next |
|-----------|------|
| All stories approved | `/orchestrate-develop - <portable-feature-path>` **or** per-story `sdd-develop` |
| Context pause mid-O2 | `/orchestrate-deliver - <portable-feature-path>` |
| Backlog not approved | `/orchestrate-analyze - <portable-feature-path>` |
| Required siblings missing | `/orchestrate-analyze - <portable-feature-path>` (do not Write PRD/PLAN) |
| Single story only (skip O2) | `/sdd-spec` then `sdd-plan` (Classic SDD) |

### Canonical develop handoffs

```text
/sdd-develop - <portable-plan-path> - Step 1
```

```text
/orchestrate-develop - <portable-feature-path>
```
