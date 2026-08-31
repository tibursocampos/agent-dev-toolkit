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

**Human gate:** backlog must be explicitly approved (`sim` / `ajustar` / `cancelar`) before O2. **Silence is not approval** (RN01). Do **not** mark approved if required specialist folders are missing or cited non-feature `.md` was not promoted (pointer-only = fail O1). When greenfield / `needs_domain` without an established style, an **architecture confirm gate** (ARCH draft → **sim** → ARCH approved) runs after the architect pass and before treating style as selected (SKILL §7b). Brownfield skips **style re-pick** only — still write mirror ARCH.

Orchestrator **does not** implement application code. When a `needs_*` flag (or brownfield) is true, specialists **must** write notes under story `ANALYSIS/` / `ARCH/` / `SEC/` (folder on disk required). `REFINE/` remains on demand. Do **not** route those notes to CONTINUITY as a substitute.

Does **not** write PRD/PLAN (that is O2 via `sdd-spec` / `sdd-plan` contracts). Does **not** call trackers.

## Lazy-load

| When | Path |
|------|------|
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Pipeline Orchestrated Delivery, confirm, paths | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage, manifest, feature tree | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Step 0 Memory Bank Gate | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Memory-bank create/refresh | `{{TOOLKIT_ROOT}}/skills/memory-bank-init/SKILL.md` |
| Roster, `needs_*`, triage table | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md` |
| Spawn native vs fallback (capability `subagents`) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Task subagent model (default omit; rare premium gate) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack routing (implement later) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROUTING.md` |
| Templates | `{{TOOLKIT_ROOT}}/skills/_shared/templates/features/{FEATURE,CONTINUITY,TREE}.md`, `.../story/STORY.md` |
| Specialist prompts | `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/{repo_analyst,architect,security,database,impact,risk,generate-story}.md` |
| Triage tables, boundaries, NuGet example | `skills/orchestrate-analyze/reference.md` |
| Scorecard rubric (reuse) | `skills/refine-story/reference.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |

## Process

### Step -1b - Caveman Mode (Lite cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 1. Gate check

Report the Step -1 gate checklist in chat. Load `PIPELINE.md` (Orchestrated Delivery) and `SESSION.md`. **STOP** if any gate unchecked.

### 2. Resolve storage

Load `STORAGE.md`. Run resolution with `$Workflow = classic`. Resolve feature root and bank root:

- **repository** -> feature `$Cwd/features/`; bank `$Cwd/memory-bank/`
- **global** -> feature `<classic.path>/features/`; bank `<classic.path>/memory-bank/`

**Path sanitize (required)** for any invoke / allocated feature path: normalize (`\` -> `/`, trim trailing `/`, resolve `.`). Reject if it contains `..`, or if the resolved absolute path is **not** under the feature root above. Ask again in pt-BR for a canonical path - do not Read/Write outside the feature root.

If first run for this repo: ask storage (pt-BR) per `STORAGE.md` and persist manifest. Confirm target workspace. Do **not** invent a feature path outside the resolved root.

Repository mode: ensure SDD `.gitignore` patterns per `STORAGE.md` (includes `/features/`; **do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets) when writing under `features/` or `memory-bank/` (do not weaken toolkit patterns; never ignore `skills/`). **Global mode:** do not edit project `.gitignore`.

### 3. Step 0 - Memory Bank Gate

Follow `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` (policy default **`auto`**). Bank root = resolved `bank_root` from step 2 - **never** under `features/NNN-slug/`.

Before any bank write: confirm (pt-BR) per MEMORY-BANK.md / guardrails (`sim` / `ajustar` / `cancelar`). Healthy bank -> selective read only (no write). Explicit `skip` / `skip-memory-bank` -> log and continue (exception only).

Record `bank_path` + status (`fresh` | `created` | `refreshed` | skipped) for CONTINUITY (steps 6 and 8). After ARCH **sim** (step 7b): **point-promote** `memory-bank/architecture.md` (if not already) and set status `refreshed` — not a full inventory refresh (`MEMORY-BANK.md`).

**Must not:** dump the entire bank into the parent prompt; create bank under `features/`; write app code during Step 0.

### 4. Collect description and triage

Ask for (or reuse Prior context): goal, current behavior, constraints, known repos/areas. Use selective memory-bank facts as Prior context - do not re-ask what the bank already states clearly.

If the user cites a `.md` **outside** `features/` (including Cursor `.cursor/plans/` or any host plans dir): **Read** it and **promote** per `PIPELINE.md` § Promote — copy rich content (DDL, JSON, mermaid, tables, OpenAPI) into memory-bank phase 2 (`database-schema.md`, `api-contracts.md`, `component-catalog.md`, `config-examples.md` as relevant) and/or story `ARCH|SEC|ANALYSIS`. A citation is not Prior context until promote is done. Pointer-only / bibliography-only → **fail O1** (do not mark backlog approved). Allow Read of cited plans; never treat `.cursor/plans/` as O3 input.

Set and record:

| Dimension | Values |
|-----------|--------|
| Complexity | `trivial` \| `medium` \| `complex` |
| Nature | `greenfield` \| `brownfield` \| `operational` |
| Scope | `backend` \| `frontend` \| `fullstack` |

Set `needs_*` flags (`needs_api`, `needs_domain`, `needs_database`, `needs_frontend`, `needs_security`, `needs_devops`) using the **canonical table in `ROSTER.md`** (do not fork a second mapping here). Optional NuGet/examples: `reference.md`.

**TE01 - ambiguous flags:** ask at most a few high-cost questions (pt-BR). Do **not** invent architecture in the orchestrator. Prefer `false` until evidence or user confirms - **except** auth / secrets / PII / feed-token / supply-chain signals -> ask explicitly or set `needs_security=true`.

Suggest path (RF01):

| Complexity | Suggestion |
|------------|------------|
| `trivial` | Shortcut `developer` / stack `*-developer` (step 5) |
| `medium` | Classic SDD (`sdd-spec` -> `sdd-plan` -> `sdd-develop`) **or** continue O1 if multi-story |
| `complex` | Continue full O1 (this skill) |

### 5. Trivial shortcut

If `trivial`: recommend skipping full O1 write:

```text
Escopo trivial. Prefere atalho?

1) /developer  (ou *-developer do stack)
2) Continuar O1 mesmo assim (gravar feature tree)
3) cancelar
```

Only continue to step 6+ if the user explicitly chooses **2**.

### 6. Allocate NNN-slug and scaffold tree

1. Glob existing `NNN` under `features/*/` only (workspace + global feature root) per `STORAGE.md`. Next = max + 1. Do **not** number from root/flat `PRD/` or `PLAN/`.
2. Propose `NNN-slug` (kebab-case) and **full path**.
3. Confirm before first Write (pt-BR): **“Posso gravar a árvore em `{path}`? (sim / ajustar / cancelar)”** - silence ≠ approval.
4. Create from templates: `FEATURE.md`, `CONTINUITY.md` (include **Memory-bank** path + status from Step 0), story folders `USnn`/`TSnn` as needed. Under the story (never at repo root): create `ANALYSIS/` / `ARCH/` / `SEC/` when the matching FEATURE `needs_*` (or brownfield) is true — **required on disk**, not on demand. `REFINE/` remains **optional / on demand**. Do **not** create `PRD/` / `PLAN/` yet (O2). Do **not** create `memory-bank/` under the feature path.

### 7. Spawn Task specialists (conditional, parallel)

**SPAWN first:** load `SPAWN.md`; consult capability `subagents` (`native` \| `none`). Prefer Task when `native`; if `subagents=none` or Task unavailable → **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` — **never skip** required folders; never substitute a CONTINUITY handoff note for `needs_api` / `needs_domain` / `needs_database` / `needs_security` / brownfield. Never hard-fail for missing Task. Concurrent Task cap **≤4** per `SPAWN.md` (wave if more; do not invent a new cap). `needs_frontend` / `needs_devops` stay CONTINUITY-only (no Task).

Spawn a Task subagent **only** when `subagents=native` **and** `ROSTER.md` canonical `needs_*` / brownfield rules say so. Load prompt from `skills/_shared/agents/prompts/`. When multiple specialists apply, spawn **in parallel** within the SPAWN ≤4 cap; if more flags apply, batch in waves of ≤4 or ask (pt-BR) to run série.

**Model (`SUBAGENT-MODEL.md`):** omit Task `model` by default (inherit parent / Auto). Ask about a premium slug **only** for very hard work per that contract; on **não** / silence, spawn without `model`. Never pick a costlier model alone.

| Signal (see ROSTER) | Specialist | Prompt |
|---------------------|------------|--------|
| `needs_api` or brownfield / impact unclear | `repo_analyst` → `ANALYSIS/` | `prompts/repo_analyst.md` |
| `needs_domain`, contract-heavy API, **greenfield**, or **brownfield** (mirror; skip style re-pick only) | `architect` → `ARCH/` | `prompts/architect.md` |
| `needs_database` or brownfield with persistence | `database` → `ARCH/` DB slice | `prompts/database.md` |
| `needs_security` | `security` → `SEC/` | `prompts/security.md` |
| `needs_frontend` | *(no O1 specialist)* - CONTINUITY note only; route at implement via `ROUTING.md` |
| `needs_devops` | short CONTINUITY note only (no Task) | - |
| Story drafting aid | use `generate-story` patterns | `prompts/generate-story.md` |
| Optional stage notes | `impact` / `risk` | `prompts/impact.md`, `prompts/risk.md` |

Parent keeps lean context: synthesis + paths. Specialists must **not** write app code. Do **not** call `*-developer` to implement. `qa_checklist` is CONTINUITY/STORY only - never spawn a Task for it.

### 7b. Architecture confirm gate (greenfield / `needs_domain`)

When nature is **`greenfield`** **or** `needs_domain=true` **and** no established in-repo / approved ARCH style:

1. Architect returns an ARCH **draft** only (four sections per `prompts/architect.md`; may use `templates/features/story/ARCH/architecture-decision.md`).
2. Parent presents the draft and asks (pt-BR):

```text
Rascunho ARCH (estilo proposto) em `{story-arch-path}`.

Posso gravar o ARCH aprovado com este estilo?
(sim / ajustar / cancelar)
```

3. Act on the answer:

| Answer | Action |
|--------|--------|
| **sim** | Persist ARCH **approved**; record style id in CONTINUITY; **point-promote** / update `memory-bank/architecture.md` (if not already) so it is not left draft / `needs-confirm`; set Memory-bank status `refreshed`; continue step 8 |
| **ajustar** | Revise proposal with architect (or in-parent); re-present; ask again |
| **cancelar** | Leave draft; do **not** treat style as selected |
| *(silence / other)* | **not** approval — keep `needs-confirm.`; wait |

4. **Until sim:** do not write final ARCH; do not invent a silent default style (including vertical-slice). Brownfield with an established style: **skip this confirm gate** (style re-pick / style-id only) — still spawn `architect` and `database` (when persistence is in scope) and write a **mirror** ARCH slice (layers, DDL, EF vs Dapper or equivalent, pipeline). Do **not** skip ARCH because a style already exists.

Canonical details: `ROSTER.md` architecture confirm gate + `reference.md` § Architecture confirm gate.

### 8. Synthesize artifacts

Merge specialist notes + user input + **promoted** canonical bodies (not pointers) into:

1. **FEATURE.md** - overview, story index, all `needs_*`, status `draft`
2. **CONTINUITY.md** - phase `analyze`, decisions, flags, open items, **Memory-bank** path + status (`fresh` \| `refreshed` \| `created`; **`refreshed`** after ARCH **sim** / point-promote). Schema/product forks: pointers to `ANALYSIS/` / `ARCH/` only — not the full open-decision list.
3. **STORY.md** per US/TS - template structure; BDD Given/When/Then; deps; scorecard summary (rubric from `refine-story/reference.md`; map /100 -> 1-5 in STORY table)

Use `generate-story` prompt patterns for drafts. Prefer pt-BR artifact prose; paths/ids English. CONTINUITY references the bank only - **do not** paste bank body into CONTINUITY. PLAN magro (O2): bodies stay in bank/ARCH/ANALYSIS; PLAN cites the canonical path — if that path is missing, create the canonical file first.

### 9. Human backlog approval (RN01)

Before asking: required specialist folders must exist on disk for true flags / brownfield (`ANALYSIS/` / `ARCH/` / `SEC/` per `ROSTER.md`); cited non-feature `.md` must be promoted (not pointer-only). Else **fail O1** — do not present the backlog as ready and do **not** mark approved.

Present the backlog (feature summary + story table + scorecard highlights). Ask (pt-BR):

```text
Backlog O1 pronto em `{feature-path}`.

Posso marcar como aprovado e seguir para O2?
(sim / ajustar / cancelar)
```

| Answer | Action |
|--------|--------|
| **sim** | status -> `approved`; continue step 10 |
| **ajustar** | revise stories/flags; re-present; ask again |
| **cancelar** | leave `draft`; do not hand off to O2 |
| *(silence / other)* | **not** approval - wait |

### 10. Approve -> CONTINUITY + O2 handoff

On **sim**:

1. Update `FEATURE.md` / story statuses to `approved` as appropriate.
2. Update `CONTINUITY.md`: phase stays `analyze` until O2 starts (or set handoff-ready note); `Last agent` = `orchestrate-analyze`; keep Memory-bank fields; typed handoff string.
3. Offer O2 (document series vs parallel as **O2 choice** - do not implement O2 here):

```text
/orchestrate-deliver - <full-feature-path>
```

Example:

```text
/orchestrate-deliver - features/004-nuget-extract/
```

Remind (pt-BR): O2 will ask série vs paralelo for per-story PRD/PLAN.

### 11. Context pressure (TE02 / RNF02)

Honor `{{TOOLKIT_ROOT}}/rules/context-management.mdc` thresholds (checkpoint / hard stop). When pressure is high:

1. Persist latest `CONTINUITY.md` (estado atual short per CONTINUITY template, decisões, pendências, exact next `/…`).
2. Offer session handoff - same phase, resume with feature path:

```text
/orchestrate-analyze - <full-feature-path>
```

Do **not** paste full specialist dumps into the parent chat.

## Must not

- Skip Step 0 Memory Bank Gate (unless explicit user `skip-memory-bank`)
- Create or place `memory-bank/` under `features/NNN-slug/`
- Duplicate memory-bank body into CONTINUITY (path + status only)
- Dump entire memory-bank into the parent orchestrator context
- Write application/production code or tests (`*.cs`, `*.tsx`, `*.ts`, `*.js`, `*.vue`, `*.py`, migrations, etc.)
- Call `*-developer` / `developer` to **implement** code (suggesting the trivial shortcut is allowed)
- Skip human backlog approval or treat silence as `sim`
- Skip the architecture confirm gate on greenfield / `needs_domain` (no established style), or write final ARCH / pick a silent style default before operator **sim**
- Skip `architect` / `database` (or skip writing mirror ARCH) on brownfield — skip **style re-pick / confirm gate** only
- Leave `memory-bank/architecture.md` draft / `needs-confirm` after ARCH **sim** (point-promote that file; not a full inventory refresh)
- Pile unresolved product/schema choices only in CONTINUITY when `needs_database` / `needs_domain` (write them under `ANALYSIS/` / `ARCH/`; CONTINUITY may pointer only)
- Approve backlog when required `ANALYSIS/` / `ARCH/` / `SEC/` folders are missing for true flags / brownfield
- Treat pointer-only cited `.md` as promoted; treat `.cursor/plans/` as O3 input
- Write PRD/PLAN (O2 owns that via `sdd-spec` / `sdd-plan` contracts)
- Create external work-item tracker or org-only compliance content
- Create ~40 agent files or expand the roster beyond `ROSTER.md`
- Modify toolkit `.gitignore` as part of porting this skill into the toolkit repo; at runtime follow `STORAGE.md` only for consumer repo SDD patterns
- Change the `sdd-develop` one-step-per-session contract
- Create `REFINE/` / `ANALYSIS/` / `ARCH/` / `SEC/` / `PRD/` / `PLAN/` at **repo root**
- Resolve feature paths outside `$Cwd/features/` or `<classic.path>/features/`, or accept `..` segments
- Pass Task `model` without `SUBAGENT-MODEL.md` gate + user **sim** (or user-named slug); ask model on routine spawns
- Hard-fail when `subagents` is `none` or Task is unavailable (use **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` per `SPAWN.md`; never skip required folders)
- Exceed orchestrate ≤4 concurrent Tasks without user-approved wave/série (`SPAWN.md`)
- Paste guideline packs into Task child prompts

## Handoff

| Situation | Next |
|-----------|------|
| Backlog approved | `/orchestrate-deliver - <full-feature-path>` |
| Context pause mid-O1 | `/orchestrate-analyze - <full-feature-path>` |
| Trivial after triage | `/developer` or stack `*-developer` |
| Single clear story, skip O2 multi | `/sdd-spec` (Classic SDD) after STORY exists |
| Informal single item only | `/refine-story` (Backlog Refine) |

### Canonical O2 handoff (exact pattern)

```text
/orchestrate-deliver - <full-feature-path>
```
