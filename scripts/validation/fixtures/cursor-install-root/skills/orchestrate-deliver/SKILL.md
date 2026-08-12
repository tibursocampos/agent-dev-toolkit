---
name: orchestrate-deliver
description: Forma C O2: run sdd-spec then sdd-plan per approved US/TS; human-approve PRD/PLAN; emit multi-path handoff. No app code. Use when invoking /orchestrate-deliver.
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

# Skill: orchestrate-deliver

## Trigger

Invoke when the user asks for: `/orchestrate-deliver`, `orchestrate deliver`, `/orchestrate-deliver`, or Forma C O2 after an approved O1 backlog.

Required: full feature path (or resolvable `features/NNN-slug/`).

## Outcome

Under each approved story folder (`USnn` / `TSnn`):

1. `PRD/NNN_*.md` - via **`sdd-spec` contract** (what, not how)
2. `PLAN/PLAN_NNN_*.md` - via **`sdd-plan` contract** (baby steps)
3. Feature `CONTINUITY.md` - phase `deliver`, decisions, typed multi-path handoff, **Memory-bank** path + status

**Step 0 (required):** Memory Bank Gate (`MEMORY-BANK.md`, policy `auto`) **before** mode selection / story contracts. Resolve `bank_root` via `STORAGE.md` - never under `features/`. CONTINUITY remains the feature phase/handoff source; bank does not replace it.

**Human gate:** PRD/PLAN approval per story **or** batch (`sim` / `ajustar` / `cancelar`). Silence ≠ approval (RN01).

Orchestrator **does not** implement application code. **Does not** rewrite `sdd-spec` / `sdd-plan` process - load those skills and run their contracts per story. **Does not** call trackers.

## Lazy-load

| When | Path |
|------|------|
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Pipeline Forma C, confirm, paths | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage, manifest, feature tree | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/STORAGE.md` |
| Step 0 Memory Bank Gate | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Memory-bank create/refresh | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/memory-bank-init/SKILL.md` |
| CONTINUITY / FEATURE templates | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/templates/features/` |
| Spec contract | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/sdd-spec/SKILL.md` (+ `reference.md` as needed) |
| Plan contract | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/sdd-plan/SKILL.md` (+ `reference.md` as needed) |
| Modes, approval, handoff examples | `skills/orchestrate-deliver/reference.md` |
| Spawn native vs fallback (capability `subagents`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/agents/SPAWN.md` |
| Task subagent model (default omit; rare premium gate) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/rules/context-management.mdc` |

## Process

### Step -1b - Caveman Mode (Lite cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 1. Gate check

Report the Step -1 gate checklist in chat. Load `PIPELINE.md` (Forma C) and `SESSION.md`. **STOP** if any gate unchecked.

### 2. Resolve feature and storage

Load `STORAGE.md`. Run resolution with `$Workflow = classic`.

Accept feature path from invoke (preferred) or Glob under feature root:

- **repository** -> `$Cwd/features/NNN-slug/`; bank `$Cwd/memory-bank/`
- **global** -> `<classic.path>/features/NNN-slug/`; bank `<classic.path>/memory-bank/`

**Path sanitize (required):** normalize the invoke path (`\` -> `/`, trim trailing `/`, resolve `.`). Reject if it contains `..`, or if the resolved absolute path is **not** under `$Cwd/features/` (repository) or `<classic.path>/features/` (global). Ask again in pt-BR for a canonical path - do not Read/Write outside the feature root.

Repository mode: ensure SDD `.gitignore` per `STORAGE.md` (`/features/` + safety-net; **do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets) before writes under feature or bank roots. **Global:** do not edit `.gitignore`.

`Read` `FEATURE.md` + `CONTINUITY.md`. If missing: **STOP** - ask for O1 first:

```text
Não encontrei FEATURE.md / CONTINUITY.md em `{path}`.

1) /orchestrate-analyze - <full-feature-path>
2) cancelar
```

### 3. Step 0 - Memory Bank Gate

Follow `MEMORY-BANK.md` (policy default **`auto`**). Bank root = resolved `bank_root` - **not** under `features/`.

Confirm (pt-BR) before create/refresh; healthy -> selective read only. Update `CONTINUITY.md` Memory-bank path + status when create/refresh runs. If style changed or ARCH was approved this feature, do **not** leave status `fresh` (set `refreshed`; point-promote `architecture.md` if not already). Keep phase/handoff ownership in CONTINUITY - do not replace with bank body. Pass `bank_path` into parallel draft Task prompts as **read-only Prior context** (selective files only).

### 4. Preconditions (approved backlog)

Verify backlog is human-approved:

| Signal | Accept |
|--------|--------|
| `FEATURE.md` **Status** | `approved` (or stories listed as approved) |
| CONTINUITY | O1 handoff / note that backlog was approved with **sim** |

If still `draft` or approval unclear: **STOP** - do not invent approval:

```text
Backlog ainda não aprovado em `{feature-path}`.

1) Voltar ao O1: /orchestrate-analyze - <full-feature-path>
2) Você confirma aprovação agora? (sim / cancelar)
```

Only continue after explicit **sim** (then record in CONTINUITY) or O1 re-approval.

Discover stories: Glob `US*/STORY.md` and `TS*/STORY.md` under the feature. Build work list (id, title, path, deps from STORY if present). Skip stories already having both PRD+PLAN unless user asks to refresh.

**Required siblings STOP (flag-gated):** If FEATURE `needs_*` is true (or nature is brownfield) and the story lacks the matching sibling folder/files (`ANALYSIS/` / `ARCH/` / `SEC/` per `ROSTER.md` / `PIPELINE.md` § Feature / story siblings): **STOP**. Return to O1. Do **not** Write PRD/PLAN. Max-3 gap questions do **not** replace this gate. Waive-deps remains for **story order**, not for missing SEC/ARCH/ANALYSIS.

```text
Faltam pastas obrigatórias em `{story-path}` (FEATURE needs_* / brownfield).

O2 não grava PRD/PLAN sem ANALYSIS|ARCH|SEC quando a flag correspondente é true. Max-3 perguntas de gap não substituem este gate.

1) Voltar ao O1: /orchestrate-analyze - <full-feature-path>
2) cancelar
```

### 5. Choose mode (RF03)

Ask (pt-BR) - never assume. Only after the required-siblings STOP in step 4 has passed:

```text
O2 em `{feature-path}` - {N} histórias.

Modo de execução?

1) série - uma história por vez (spec -> plan -> aprovação)
2) paralelo - Task por história (filho só rascunha PRD/PLAN; Write só no pai após sim); agregação e aprovação no pai
3) cancelar
```

| Choice | Behavior |
|--------|----------|
| **1 série** | Parent runs contracts sequentially; lower context risk |
| **2 paralelo** | Prefer Task when `subagents=native` (`SPAWN.md`): one Task per story for **drafts only**; parent aggregates, gates `sim`, then **parent** writes via `sdd-spec` / `sdd-plan`. Concurrent Task cap **≤4** per `SPAWN.md`; if N>4, wave ≤4 or prefer série. If `subagents=none` or Task unavailable → **fallback** to série **in-parent** (same contracts; never hard-fail) |
| **3** | Stop; no writes |

Document the choice in `CONTINUITY.md` (decisões). Before any paralelo Task wave: load `SPAWN.md` and consult capability `subagents`.

**Model (`SUBAGENT-MODEL.md`):** omit Task `model` by default. Premium slug only after the rare hard-task gate + user **sim**; **não** / silence → omit `model`.

### 6. Per-story contracts (reuse, do not rewrite)

For each story in the work list:

**Target paths** (`PIPELINE.md` canonical):

```text
features/NNN-slug/{USnn|TSnn}/PRD/NNN_*.md
features/NNN-slug/{USnn|TSnn}/PLAN/PLAN_NNN_*.md
```

**Input to contracts:** `STORY.md` + `REFINE/` when present (on demand) + `ANALYSIS|ARCH|SEC` when FEATURE flags (or brownfield) require them + feature `FEATURE.md` / `CONTINUITY.md` + selective `memory-bank/` paths from Step 0 (Prior context - max 3 gap questions total per story if needed). Prefer promoted siblings/bank over re-asking.

**Per-story STOP:** if this story still lacks a flag-gated required sibling (`ANALYSIS/` / `ARCH/` / `SEC/`): **STOP** that story — do **not** Write PRD/PLAN; return to O1. Max-3 gap questions do **not** replace this gate.

| Stage | Contract | Must follow |
|-------|----------|-------------|
| Spec | `sdd-spec` | Confirm-before-write; pt-BR PRD; no PLAN; no app code |
| Plan | `sdd-plan` | Requires PRD on disk; baby-step PLAN; no app code |

**Série:** for story S: load `sdd-spec` -> write PRD after **sim** -> load `sdd-plan` -> write PLAN after **sim** -> optional per-story approval (step 7) -> next story.

**Paralelo (native only):** when `subagents=native`, spawn Task with prompt that: (1) reads story siblings + **memory-bank path** (read-only, selective), (2) drafts PRD then PLAN content for **that story only** (in the Task return - markdown bodies or structured sections), (3) returns **intended** paths + 5-bullet summary + draft text, (4) **must not** `Write` PRD/PLAN to disk. Parent aggregates drafts -> presents for approval (step 7) -> on **sim**, parent runs `sdd-spec` / `sdd-plan` contracts and performs the only disk writes. Else (**fallback**): run série **in-parent** — do not hard-fail for missing Task.

Respect story **deps**: do not parallelize a story before its dependency stories have PRD+PLAN (or user explicitly waives). Waive-deps is for **story order** only — not for missing `SEC/` / `ARCH/` / `ANALYSIS`.

### 7. Approval - per story or batch (RN01)

After drafts exist (or after each story in série), present summary table (id, PRD path, PLAN path, 3 bullets). Ask (pt-BR):

```text
PRD/PLAN O2 prontos para aprovação.

Escopo: (por história | lote completo)

Posso marcar como aprovados?
(sim / ajustar / cancelar)
```

Offer **por história** vs **lote** when N > 1.

| Answer | Action |
|--------|--------|
| **sim** (por história) | Set `write_confirmed` as needed per artifact write; write that story's PRD/PLAN; clear `write_confirmed` after; mark story deliver status; continue |
| **sim** (lote) | **One** batch `sim` authorizes Write for **only** the PRD/PLAN paths listed in the approval table. Parent writes that set (serie within parent); set/clear `write_confirmed` around the batch (or per artifact if contracts require). Do **not** reuse a stale `write_confirmed=true` from an earlier story for unlisted paths |
| **ajustar** | Revise named story via sdd-spec/sdd-plan contract; re-ask |
| **cancelar** | Leave drafts; do not emit O3 / develop handoff as approved |
| *(silence)* | **not** approval - wait |

### 8. CONTINUITY + multi-path handoff (RF04)

On approval:

1. Update `CONTINUITY.md`: **Phase** = `deliver`; **Last agent** = `orchestrate-deliver`; keep **Memory-bank** path + status from Step 0 (`refreshed` if this run refreshed, or if style changed / ARCH was approved this feature — do **not** exit `fresh` in that case); estado atual short per CONTINUITY template; append decisão (série|paralelo); typed handoff with **full paths**.
2. Optionally update `FEATURE.md` / story statuses to reflect deliver done.
3. Emit handoff block listing every PLAN (and PRD) path:

```text
## Handoff O2 -> develop

### Manual (Forma A per story)
/sdd-develop - <full-plan-path-US01> - Step 1
/sdd-develop - <full-plan-path-TS01> - Step 1

### Orchestrated (O3)
/orchestrate-develop - <full-feature-path>
```

Remind (pt-BR): O3 is optional; `sdd-develop` one-step contract unchanged. Forma A (`sdd-spec` -> `sdd-plan` -> `sdd-develop`) does **not** require memory-bank (CA7). User picks one path per story/session.

### 9. Context pressure (TE02 / RNF02)

Honor `context-management.mdc` thresholds. When pressure is high:

1. Persist `CONTINUITY.md` (estado, decisões, which stories done/pending, exact next invoke).
2. Offer resume:

```text
/orchestrate-deliver - <full-feature-path>
```

Do **not** paste full PRD/PLAN bodies into the parent chat.

## Must not

- Skip Step 0 Memory Bank Gate (unless explicit user `skip-memory-bank`)
- Create `memory-bank/` under `features/NNN-slug/` or replace CONTINUITY with bank body
- Dump entire memory-bank into parent or child prompts
- Write application/production code or tests (`*.cs`, `*.tsx`, `*.ts`, `*.js`, `*.vue`, `*.py`, migrations, etc.)
- Call `*-developer` / `developer` / `sdd-develop` / `orchestrate-develop` to **implement** (handoff strings only)
- Rewrite or fork the `sdd-spec` / `sdd-plan` process into a parallel undocumented flow
- Skip human approval or treat silence as `sim`
- Write PRD/PLAN when FEATURE `needs_*` (or brownfield) is true and the story lacks matching `ANALYSIS/` / `ARCH/` / `SEC/` — **STOP** / return to O1; max-3 gap questions do not replace this gate
- Treat waive-deps as a waiver for missing `SEC/` / `ARCH/` / `ANALYSIS` (waive-deps is **story order** only)
- Exit O2 with Memory-bank status `fresh` if style changed or ARCH was approved this feature (set `refreshed`; point-promote `architecture.md` if not already)
- Write PRD/PLAN at repo root or outside the story folder
- Create external work-item tracker or org-only compliance content
- Change the `sdd-develop` one-step-per-session contract
- Create `REFINE/` / `ANALYSIS/` / `ARCH/` / `SEC/` / `PRD/` / `PLAN/` at **repo root**
- Assume série vs paralelo without asking
- Let parallel Task children `Write` PRD/PLAN to disk (parent-only writes after **sim**)
- Resolve feature paths outside `$Cwd/features/` or `<classic.path>/features/`, or accept `..` segments
- Require memory-bank for Forma A / manual `sdd-*` (CA7 - gate is Forma C `orchestrate-*` only)
- Pass Task `model` without `SUBAGENT-MODEL.md` gate + user **sim** (or user-named slug); ask model on routine story drafts
- Hard-fail when `subagents` is `none` or Task is unavailable (use **fallback** série **in-parent** per `SPAWN.md`)
- Exceed orchestrate ≤4 concurrent Tasks without user-approved wave/série (`SPAWN.md`)
- Paste guideline packs into Task child prompts

## Handoff

| Situation | Next |
|-----------|------|
| All stories approved | `/orchestrate-develop - <full-feature-path>` **or** per-story `sdd-develop` |
| Context pause mid-O2 | `/orchestrate-deliver - <full-feature-path>` |
| Backlog not approved | `/orchestrate-analyze - <full-feature-path>` |
| Required siblings missing | `/orchestrate-analyze - <full-feature-path>` (do not Write PRD/PLAN) |
| Single story only (skip O2) | `/sdd-spec` then `sdd-plan` (Forma A) |

### Canonical develop handoffs

```text
/sdd-develop - <full-plan-path> - Step 1
```

```text
/orchestrate-develop - <full-feature-path>
```
