# orchestrate-deliver - reference

Modes, approval gates, path layout, CONTINUITY checklist, handoff examples, and boundaries for `skills/orchestrate-deliver/SKILL.md`. Keep `SKILL.md` lean; use this file for extended detail.

---

## Preconditions checklist

Before any PRD/PLAN write:

- [ ] Gate check reported; `write_confirmed` / user **sim** for this O2 run (O2 writes PRD/PLAN - not develop `step_confirmed`)
- [ ] Feature path resolved (`STORAGE.md`, `$Workflow = classic`)
- [ ] **Step 0** Memory Bank Gate done (`MEMORY-BANK.md`, policy `auto`; `skip` only with explicit flag)
- [ ] `FEATURE.md` + `CONTINUITY.md` exist (Memory-bank path/status updated if create/refresh)
- [ ] Backlog human-approved (FEATURE/stories `approved`, or explicit **sim** in this session recorded)
- [ ] Story list from `US*/STORY.md` + `TS*/STORY.md`
- [ ] Flag-gated required siblings present (`ANALYSIS/` / `ARCH/` / `SEC/` when FEATURE `needs_*` or brownfield) — else **STOP** / return to O1; do **not** Write PRD/PLAN; max-3 gap questions do not replace this gate
- [ ] Mode chosen: **série** or **paralelo** (user asked; not assumed)

If backlog not approved -> hand off to O1; do not invent approval (RN01).
If required siblings missing -> **STOP** / return to O1; do not Write PRD/PLAN.

---

## Step 0 - Memory Bank Gate (CA4 / CT3)

Same contract as O1 (`MEMORY-BANK.md`). Run after feature resolve, **before** mode selection.

| Check | Pass |
|-------|------|
| Bank path | Resolved `bank_root` via `STORAGE.md` |
| Healthy bank | Selective read; status `fresh` unless style changed / ARCH approved this feature → then `refreshed` (point-promote `architecture.md` if not already); no full inventory rewrite |
| Missing/stale | Confirm -> create/refresh; status `created`/`refreshed` |
| Gitignore | Repository only; global = no `.gitignore` edit |
| CONTINUITY | Path + status only; phase/handoff still CONTINUITY-owned |
| Children | Parallel draft Tasks get `memoryBankPath` read-only |
| Forma A | Memory-bank **not** required (CA7) |
| End refresh | **No** full inventory (O2 does not change app code). Do **not** exit `fresh` if style changed / ARCH approved this feature |

---

## Mode comparison (RF03)

| | **Série** | **Paralelo** |
|--|-----------|--------------|
| Who drafts / writes | Parent runs contracts end-to-end (Write after **sim**) | Task children **draft only** when `subagents=native` (no disk Write); parent Writes after **sim**. Else **fallback** série **in-parent** (`SPAWN.md`) |
| Order | Spec -> plan -> (optional approve) -> next | Children concurrent; parent aggregates drafts then writes |
| Deps | Natural - finish dependency stories first | Block spawn until deps have PRD+PLAN (or user waives **story order** only — not missing SEC/ARCH/ANALYSIS) |
| Context (RNF01) | Higher in parent | Parent lean (paths + draft summaries) |
| Confirm-before-write | Inline in parent | Always parent gate after aggregation |
| Best when | Few stories; tight review | Many independent stories; brownfield batch |

Document choice under CONTINUITY **Decisões**.

---

## Per-story path layout

```text
features/NNN-slug/
├── FEATURE.md
├── CONTINUITY.md
├── US01/
│   ├── STORY.md
│   ├── PRD/
│   │   └── NNN_short_slug.md          # sdd-spec contract
│   └── PLAN/
│       └── PLAN_NNN_short_slug.md     # sdd-plan contract
└── TS01/
    ├── STORY.md
    ├── PRD/
    │   └── NNN_ts01_slug.md
    └── PLAN/
        └── PLAN_NNN_ts01_slug.md
```

| O2 writes | O2 does **not** write |
|-----------|------------------------|
| `…/PRD/*.md`, `…/PLAN/*.md` via sdd contracts | App/test source |
| Updates to `CONTINUITY.md` / status fields | Repo-root `PRD/` / `PLAN/` |
| | Implementation via `sdd-develop` / O3 (handoff only) |

`NNN` in PRD/PLAN filenames **matches** feature `NNN`. Prefer short English slug per story.

Artifact prose default **pt-BR**; identifiers and skill names **English**.

---

## Contract reuse (do not fork)

| Stage | Load and follow | Output |
|-------|-----------------|--------|
| Spec | `skills/sdd-spec/SKILL.md` | Canonical PRD under story `PRD/` |
| Plan | `skills/sdd-plan/SKILL.md` | Canonical PLAN under story `PLAN/` |

Prior context for each story: `STORY.md` + `REFINE/` when present (optional / on demand) + `ANALYSIS|ARCH|SEC` when FEATURE flags (or brownfield) require them (**not** optional in that case) + feature `FEATURE.md` / `CONTINUITY.md`. Prefer promoted siblings/bank over re-asking. Max **3** gap questions if Prior context incomplete (`PIPELINE.md`). Max-3 gap questions do **not** replace the required-siblings STOP: missing `ANALYSIS/` / `ARCH/` / `SEC/` when flags require them → **STOP** / return to O1; do **not** Write PRD/PLAN.

Parent must **not** invent a shorter “PRD lite” process that skips confirm-before-write or acceptance sections required by those skills.

---

## Approval gates (RN01)

### Mode selection

```text
O2 em `{feature-path}` - {N} histórias.

Modo de execução?

1) série - uma história por vez (spec -> plan -> aprovação)
2) paralelo - Task por história (filho só rascunha PRD/PLAN; Write só no pai após sim); agregação e aprovação no pai
3) cancelar
```

### PRD/PLAN approval

```text
PRD/PLAN O2 prontos para aprovação.

Escopo: (por história | lote completo)

Posso marcar como aprovados?
(sim / ajustar / cancelar)
```

| Scope | When |
|-------|------|
| **Por história** | User wants tight control; série default after each story |
| **Lote** | N > 1 and user chose batch after parallel (or after all série drafts). One **sim** authorizes **only** paths listed in the approval table; clear/reset `write_confirmed` after the batch (do not reuse stale gate for unlisted paths) |

Parallel Task cap: **≤4** concurrent story drafts per `SPAWN.md`; wave or prefer série when N>4. If `subagents=none` or Task unavailable → **fallback** série **in-parent** (never hard-fail).

Silence / emoji / “ok” without **sim** is **not** approval.

---

## CONTINUITY update checklist

Update `CONTINUITY.md` when:

- [ ] Mode série|paralelo chosen
- [ ] Each story PRD+PLAN landed (or batch milestone)
- [ ] Before / after human approval gate
- [ ] Final multi-path handoff emitted
- [ ] Context ≥40% pause (TE02)

| Field | Rule |
|-------|------|
| **Phase** | `deliver` during/after O2 |
| **Last agent** | `orchestrate-deliver` |
| **Memory-bank** | Path + `fresh`\|`refreshed`\|`created` from Step 0; **not** `fresh` if style changed / ARCH approved this feature |
| **Estado atual** | ≤10 lines; which stories done/pending |
| **Decisões** | Append mode + approval scope |
| **Pendências** | Stories still missing PRD/PLAN or approval |
| **Handoff tipado** | Full `/…` lines with **portable paths** (`STORAGE.md` § Portable path) |
| **What not to write** | Full PRD/PLAN bodies, guideline dumps, app code, memory-bank body |

---

## Example handoff - 2 stories (CA4 / RF04)

Feature: `features/004-nuget-extract/`  
Stories approved in O1: `TS01` (package extract), `TS02` (App A consumer).  
Mode: paralelo. After approval:

```text
## Handoff O2 -> develop

Feature: features/004-nuget-extract/

| Story | PRD | PLAN |
|-------|-----|------|
| TS01 | features/004-nuget-extract/TS01/PRD/004_nuget_package.md | features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md |
| TS02 | features/004-nuget-extract/TS02/PRD/004_app_a_consumer.md | features/004-nuget-extract/TS02/PLAN/PLAN_004_app_a_consumer.md |

### Manual (one PLAN step per session)
/sdd-develop - features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md - Step 1
/sdd-develop - features/004-nuget-extract/TS02/PLAN/PLAN_004_app_a_consumer.md - Step 1

### Orchestrated (O3)
/orchestrate-develop - features/004-nuget-extract/
```

Global storage: same pattern with InstallRoot-relative portable paths (`sdd/<repo-id>/features/...`) — never OS absolute embeds in CONTINUITY / PRD / PLAN.

---

## Boundaries vs O1 / sdd-* / O3

| Aspect | O1 `orchestrate-analyze` | O2 `orchestrate-deliver` | Forma A `sdd-spec`/`sdd-plan` | O3 `orchestrate-develop` |
|--------|--------------------------|--------------------------|-------------------------------|--------------------------|
| Purpose | Triage + US/TS backlog | PRD+PLAN per approved story | One story PRD or PLAN | Implement PLAN steps |
| Input | Feature description | Approved `features/NNN-slug/` | Story/requirements | Approved PLAN paths |
| Output | FEATURE + CONTINUITY + STORY | PRD + PLAN per US/TS | Single PRD or PLAN | Code + PLAN checkboxes |
| Contracts | Specialists (`needs_*`) | **Reuses** sdd-spec / sdd-plan | Is the contract | **Reuses** sdd-develop |
| App code | No | No | No | Children only; parent no |

Escalate **to Forma A alone** when only one story and user skips O2 batching.

Escalate **to O1** when backlog not approved, stories missing, or flag-gated required siblings (`ANALYSIS/` / `ARCH/` / `SEC/`) are missing.

Do **not** claim `sdd-develop` one-step contract changed.

---

## Task child prompt skeleton (paralelo)

Give each child:

1. Full story path + feature path
2. Instruction: draft PRD then PLAN content for **this story only** using `sdd-spec` / `sdd-plan` structure - **do not** `Write` files to disk
3. Prior-context files to Read (list paths; do not paste bodies)
4. Intended canonical paths for PRD and PLAN (for the return payload)
5. Return format: `{ storyId, prdPath, planPath, prdDraft, planDraft, bullets[≤5], blockedReason? }`
6. Must not: app code; other stories; expand roster; disk Write of PRD/PLAN

Parent merges drafts -> human **sim** -> parent runs `sdd-spec` / `sdd-plan` contracts and performs the only disk writes.

---

## Canonical invoke strings

```text
/orchestrate-deliver - <portable-feature-path>
```

```text
/orchestrate-analyze - <portable-feature-path>
```

```text
/sdd-develop - <portable-plan-path> - Step 1
```

```text
/orchestrate-develop - <portable-feature-path>
```

```text
/sdd-spec
/sdd-plan - <portable-prd-path>
```

---

## Process — Caveman (Lite cap)

1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

---

## Process — Resolve feature and storage

Load `STORAGE.md`. Run resolution with `$Workflow = classic`.

Accept feature path from invoke (preferred) or Glob under feature root:

- **repository** -> `$Cwd/features/NNN-slug/`; bank `$Cwd/memory-bank/`
- **global** -> `<classic.path>/features/NNN-slug/`; bank `<classic.path>/memory-bank/`

**Path sanitize (required):** normalize the invoke path (`\` -> `/`, trim trailing `/`, resolve `.`). Reject if it contains `..`, or if the resolved absolute path is **not** under `$Cwd/features/` (repository) or `<classic.path>/features/` (global). Ask again in pt-BR for a canonical path - do not Read/Write outside the feature root.

Repository mode: ensure SDD `.gitignore` per `STORAGE.md` (`/features/` + safety-net; **do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets) before writes under feature or bank roots. **Global:** do not edit `.gitignore`.

`Read` `FEATURE.md` + `CONTINUITY.md`. If missing: **STOP** - ask for O1 first:

```text
Não encontrei FEATURE.md / CONTINUITY.md em `{path}`.

1) /orchestrate-analyze - <portable-feature-path>
2) cancelar
```

---

## Process — Preconditions (approved backlog + siblings)

Verify backlog is human-approved:

| Signal | Accept |
|--------|--------|
| `FEATURE.md` **Status** | `approved` (or stories listed as approved) |
| CONTINUITY | O1 handoff / note that backlog was approved with **sim** |

If still `draft` or approval unclear: **STOP** - do not invent approval:

```text
Backlog ainda não aprovado em `{feature-path}`.

1) Voltar ao O1: /orchestrate-analyze - <portable-feature-path>
2) Você confirma aprovação agora? (sim / cancelar)
```

Only continue after explicit **sim** (then record in CONTINUITY) or O1 re-approval.

Discover stories: Glob `US*/STORY.md` and `TS*/STORY.md` under the feature. Build work list (id, title, path, deps from STORY if present). Skip stories already having both PRD+PLAN unless user asks to refresh.

**Required siblings STOP (flag-gated):** If FEATURE `needs_*` is true (or nature is brownfield) and the story lacks the matching sibling folder/files (`ANALYSIS/` / `ARCH/` / `SEC/` per `ROSTER.md` / `PIPELINE.md` § Feature / story siblings): **STOP**. Return to O1. Do **not** Write PRD/PLAN. Max-3 gap questions do **not** replace this gate. Waive-deps remains for **story order**, not for missing SEC/ARCH/ANALYSIS.

```text
Faltam pastas obrigatórias em `{story-path}` (FEATURE needs_* / brownfield).

O2 não grava PRD/PLAN sem ANALYSIS|ARCH|SEC quando a flag correspondente é true. Max-3 perguntas de gap não substituem este gate.

1) Voltar ao O1: /orchestrate-analyze - <portable-feature-path>
2) cancelar
```

See also § Preconditions checklist.

---

## Process — Choose mode (RF03)

Ask (pt-BR) - never assume. Only after the required-siblings STOP has passed — copy in § Approval gates (mode selection).

| Choice | Behavior |
|--------|----------|
| **1 série** | Parent runs contracts sequentially; lower context risk |
| **2 paralelo** | Prefer Task when `subagents=native` (`SPAWN.md`): one Task per story for **drafts only**; parent aggregates, gates `sim`, then **parent** writes via `sdd-spec` / `sdd-plan`. Concurrent Task cap **≤4** per `SPAWN.md`; if N>4, wave ≤4 or prefer série. If `subagents=none` or Task unavailable → **fallback** to série **in-parent** (same contracts; never hard-fail) |
| **3** | Stop; no writes |

Document the choice in `CONTINUITY.md` (decisões). Before any paralelo Task wave: load `SPAWN.md` and consult capability `subagents`.

**Model (`SUBAGENT-MODEL.md`):** omit Task `model` by default. Premium slug only after the rare hard-task gate + user **sim**; **não** / silence → omit `model`.

See also § Mode comparison (RF03).

---

## Process — Per-story contracts

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

**Série:** for story S: load `sdd-spec` -> write PRD after **sim** -> load `sdd-plan` -> write PLAN after **sim** -> optional per-story approval -> next story.

**Paralelo (native only):** when `subagents=native`, spawn Task with prompt that: (1) reads story siblings + **memory-bank path** (read-only, selective), (2) drafts PRD then PLAN content for **that story only** (in the Task return - markdown bodies or structured sections), (3) returns **intended** paths + 5-bullet summary + draft text, (4) **must not** `Write` PRD/PLAN to disk. Parent aggregates drafts -> presents for approval -> on **sim**, parent runs `sdd-spec` / `sdd-plan` contracts and performs the only disk writes. Else (**fallback**): run série **in-parent** — do not hard-fail for missing Task.

Respect story **deps**: do not parallelize a story before its dependency stories have PRD+PLAN (or user explicitly waives). Waive-deps is for **story order** only — not for missing `SEC/` / `ARCH/` / `ANALYSIS`.

See also § Contract reuse + § Task child prompt skeleton + § Per-story path layout.

---

## Process — Approval answers (RN01)

After drafts exist (or after each story in série), present summary table (id, PRD path, PLAN path, 3 bullets). Ask (pt-BR) — copy in § Approval gates.

Offer **por história** vs **lote** when N > 1.

| Answer | Action |
|--------|--------|
| **sim** (por história) | Set `write_confirmed` as needed per artifact write; write that story's PRD/PLAN; clear `write_confirmed` after; mark story deliver status; continue |
| **sim** (lote) | **One** batch `sim` authorizes Write for **only** the PRD/PLAN paths listed in the approval table. Parent writes that set (serie within parent); set/clear `write_confirmed` around the batch (or per artifact if contracts require). Do **not** reuse a stale `write_confirmed=true` from an earlier story for unlisted paths |
| **ajustar** | Revise named story via sdd-spec/sdd-plan contract; re-ask |
| **cancelar** | Leave drafts; do not emit O3 / develop handoff as approved |
| *(silence)* | **not** approval - wait |

---

## Process — CONTINUITY + multi-path handoff (RF04)

On approval:

1. Update `CONTINUITY.md`: **Phase** = `deliver`; **Last agent** = `orchestrate-deliver`; keep **Memory-bank** path + status from Step 0 (`refreshed` if this run refreshed, or if style changed / ARCH was approved this feature — do **not** exit `fresh` in that case); estado atual short per CONTINUITY template; append decisão (série|paralelo); typed handoff with **portable paths** (`STORAGE.md` § Portable path).
2. Optionally update `FEATURE.md` / story statuses to reflect deliver done.
3. Emit handoff block listing every PLAN (and PRD) path — § Example handoff + § Canonical invoke strings.

Remind (pt-BR): O3 is optional; `sdd-develop` one-step contract unchanged. Forma A (`sdd-spec` -> `sdd-plan` -> `sdd-develop`) does **not** require memory-bank (CA7). User picks one path per story/session.

See also § CONTINUITY update checklist.

---

## Process — Context pressure (TE02 / RNF02)

Honor `context-management.mdc` thresholds. When pressure is high:

1. Persist `CONTINUITY.md` (estado, decisões, which stories done/pending, exact next invoke).
2. Offer resume:

```text
/orchestrate-deliver - <portable-feature-path>
```

Do **not** paste full PRD/PLAN bodies into the parent chat.

---

## Must not (full)

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
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path

---

## Explicit exclusions

Do **not** introduce:

- Application or test source writes in O2
- Forked “mini-spec” that skips sdd-spec/sdd-plan gates
- External work-item tracker CLI/API commands
- External work-item tracker or org-only compliance fields
- Assumed série/paralelo without asking
- Changes to `sdd-develop` one-PLAN-step-per-session contract
- Spec Kit / worktree multi-US changes (out of Forma C MVP)
- Repo-root `PRD/` / `PLAN/` new writes
