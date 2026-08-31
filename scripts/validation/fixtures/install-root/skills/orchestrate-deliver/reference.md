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
- [ ] Mode chosen: **série** or **paralelo** (user asked; not assumed)

If backlog not approved -> hand off to O1; do not invent approval (RN01).

---

## Step 0 - Memory Bank Gate (CA4 / CT3)

Same contract as O1 (`MEMORY-BANK.md`). Run after feature resolve, **before** mode selection.

| Check | Pass |
|-------|------|
| Bank path | Resolved `bank_root` via `STORAGE.md` |
| Healthy bank | Selective read; status `fresh`; no rewrite |
| Missing/stale | Confirm -> create/refresh; status `created`/`refreshed` |
| Gitignore | Repository only; global = no `.gitignore` edit |
| CONTINUITY | Path + status only; phase/handoff still CONTINUITY-owned |
| Children | Parallel draft Tasks get `memoryBankPath` read-only |
| Classic SDD | Memory-bank **not** required (CA7) |
| End refresh | **No** (O2 does not change app code) |

---

## Mode comparison (RF03)

| | **Série** | **Paralelo** |
|--|-----------|--------------|
| Who drafts / writes | Parent runs contracts end-to-end (Write after **sim**) | Task children **draft only** when `subagents=native` (no disk Write); parent Writes after **sim**. Else **fallback** série **in-parent** (`SPAWN.md`) |
| Order | Spec -> plan -> (optional approve) -> next | Children concurrent; parent aggregates drafts then writes |
| Deps | Natural - finish dependency stories first | Block spawn until deps have PRD+PLAN (or user waives) |
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

Prior context for each story: `STORY.md` + optional `REFINE|ANALYSIS|ARCH|SEC` + feature `FEATURE.md` / `CONTINUITY.md`. Max **3** gap questions if Prior context incomplete (`PIPELINE.md`).

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
| **Memory-bank** | Path + `fresh`\|`refreshed`\|`created` from Step 0 |
| **Estado atual** | ≤10 lines; which stories done/pending |
| **Decisões** | Append mode + approval scope |
| **Pendências** | Stories still missing PRD/PLAN or approval |
| **Handoff tipado** | Full `/…` lines with **full paths** |
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

Same pattern with absolute paths when the invoke used absolute feature roots (global storage).

---

## Boundaries vs O1 / sdd-* / O3

| Aspect | O1 `orchestrate-analyze` | O2 `orchestrate-deliver` | Classic SDD `sdd-spec`/`sdd-plan` | O3 `orchestrate-develop` |
|--------|--------------------------|--------------------------|-------------------------------|--------------------------|
| Purpose | Triage + US/TS backlog | PRD+PLAN per approved story | One story PRD or PLAN | Implement PLAN steps |
| Input | Feature description | Approved `features/NNN-slug/` | Story/requirements | Approved PLAN paths |
| Output | FEATURE + CONTINUITY + STORY | PRD + PLAN per US/TS | Single PRD or PLAN | Code + PLAN checkboxes |
| Contracts | Specialists (`needs_*`) | **Reuses** sdd-spec / sdd-plan | Is the contract | **Reuses** sdd-develop |
| App code | No | No | No | Children only; parent no |

Escalate **to Classic SDD alone** when only one story and user skips O2 batching.

Escalate **to O1** when backlog not approved or stories missing.

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
/orchestrate-deliver - <full-feature-path>
```

```text
/orchestrate-analyze - <full-feature-path>
```

```text
/sdd-develop - <full-plan-path> - Step 1
```

```text
/orchestrate-develop - <full-feature-path>
```

```text
/sdd-spec
/sdd-plan - <full-prd-path>
```

---

## Explicit exclusions

Do **not** introduce:

- Application or test source writes in O2
- Forked “mini-spec” that skips sdd-spec/sdd-plan gates
- External work-item tracker CLI/API commands
- External work-item tracker or org-only compliance fields
- Assumed série/paralelo without asking
- Changes to `sdd-develop` one-PLAN-step-per-session contract
- Spec Kit / worktree multi-US changes (out of Orchestrated Delivery MVP)
- Repo-root `PRD/` / `PLAN/` new writes
