## Preconditions checklist

Before any PRD/PLAN write:

- [ ] Gate check reported; `write_confirmed` / user **sim** for this O2 run (O2 writes PRD/PLAN - not develop `step_confirmed`)
- [ ] Feature path resolved (`STORAGE.md`, `$Workflow = classic`)
- [ ] **Step 0** Memory Bank Gate done (`MEMORY-BANK.md`, policy `auto`; `skip` only with explicit flag)
- [ ] `FEATURE.md` + `CONTINUITY.md` exist (Memory-bank path/status updated if create/refresh)
- [ ] Backlog human-approved (FEATURE/stories `approved`, or explicit **sim** in this session recorded)
- [ ] Story list from `US*/STORY.md` + `TS*/STORY.md`
- [ ] Flag-gated required siblings present (`ANALYSIS/` / `ARCH/` / `SEC/` when FEATURE `needs_*` or brownfield) — else **STOP** / return to O1; do **not** Write PRD/PLAN; max-3 gap questions do not replace this gate
- [ ] The parent FEATURE has no open question (`open_question`). A story whose feature is still open does not enter O2.
- [ ] Clarification readiness: no unanswered question on the required story files, including `MINOR`, at the O2 story-files gate — else **STOP** that story with `open_question` (`readiness-severity.md` § Open-question gate). Presence of sibling folders ≠ READY (**RN02**). Dual plane: readiness ≠ `step_confirmed`
- [ ] Mode chosen: **série** or **paralelo** (user asked; not assumed)
- [ ] Any blocking approval/question is `answered` for its current scope; `presented`, `pending`, queued delivery, or resumed-but-unprocessed state keeps dependent work blocked (`approval-gates.md` § Observable question and answer lifecycle)

If backlog not approved -> hand off to O1; do not invent approval (RN01).
If required siblings missing -> **STOP** / return to O1; do not Write PRD/PLAN.
If open **B**/**I** or any other unanswered question at the O2 gates -> **STOP** Write; stop code `open_question`; do not proceed to PRD/PLAN. A story whose FEATURE still has an open question does not enter O2.

When a conversation resumes after interruption, reload the active gate and its scope before continuing. A received or redelivered message is not an answer until parsed against that gate. If the answer is missing, ambiguous, or for another scope, remain blocked and ask the active question again. Host UI delivery/queue behavior is outside toolkit control; use the explicit textual answer path when a native control is unavailable and report unobservable delivery/processing as `SKIPPED` evidence.

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
| Children | Parallel draft Agent calls get `memoryBankPath` read-only |
| Classic SDD | Memory-bank **not** required (CA7) |
| End refresh | **No** full inventory (O2 does not change app code). Do **not** exit `fresh` if style changed / ARCH approved this feature |

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

Discover stories: Glob `US*/STORY.md` and `TS*/STORY.md` under the feature. Build the ordered work list (id, title, path, deps from STORY if present), then reconcile each story against its canonical artifacts and the required O2 gates. Resume an existing story at its **next pending gate**: story-file readiness, PRD/spec and contestation, required checklist, PLAN and its required validation, then applicable approval and checkpoint reconciliation. Artifact presence alone does not mean that a story or gate is complete; a draft, unaccepted output, missing required validation, or pending approval must resume at the owning gate.

Skip a story only when all required O2 work for that story is complete and accepted under its owner contracts, required contestation/checklist/validation results are recorded, and every applicable approval is recorded for the exact outputs. Do not infer completion from PRD+PLAN paths, stale `CONTINUITY.md`, a prior story's approval, or an O3 implementation status. If a gate is unresolved, resume there; if it is blocked, preserve the blocker and keep independent eligible stories in the queue. Recompute the eligible queue from canonical feature/story artifacts and dependencies after each completed story. A refresh request follows the owning contracts for the named outputs.

**Required siblings STOP (flag-gated):** If FEATURE `needs_*` is true (or nature is brownfield) and the story lacks the matching sibling folder/files (`ANALYSIS/` / `ARCH/` / `SEC/` per `ROSTER.md` / `PIPELINE.md` § Feature / story siblings): **STOP**. Return to O1. Do **not** Write PRD/PLAN. Max-3 gap questions do **not** replace this gate. Waive-deps remains for **story order**, not for missing SEC/ARCH/ANALYSIS.

**Brownfield sufficiency STOP:** For brownfield stories, inspect the required analysis content against `{{TOOLKIT_ROOT}}/skills/_shared/agents/BROWNFIELD-ANALYSIS.md` and the story's affected scope. Before accepting a brownfield analysis artifact, run `{{TOOLKIT_ROOT}}/scripts/validation/Invoke-O2BrownfieldPreflight.ps1 -AnalysisPath <portable-analysis-path>` on the artifact used for sufficiency. The command returns `ALLOW` only when the document-level validator passes; `BLOCK` or a nonzero exit blocks this story and names the table field/line and supported correction. The preflight and validator only normalize recognized aliases in memory and never edit the artifact. Required artifacts must provide relevant repository-backed conventions/impacts, evidence paths, confidence, a trace of each material current behavior through its applicable flow links, a comparison of local reuse/extension against the proposal, affected areas, and material gaps in the format owned by that artifact. A flow link or reuse claim without supporting evidence remains `GAP`; a receiver alone does not demonstrate its producer, and static inspection does not demonstrate runtime activation. Presence of `ANALYSIS/` or `ARCH/` alone does not pass. If evidence is inferred, conflicting, or a material technical gap could change the dependent PRD/PLAN, target more repository inspection when feasible; if still unresolved, **STOP** this story before PRD/PLAN and return the technical gap to O1 for targeted analysis. Do not turn a technical pattern lookup into a product clarification question when the product behavior is already clear. Product/contract decisions that remain unanswered continue to use `open_question` and existing readiness rules. Keep independent eligible stories moving; O2 consumes evidence and does not rewrite specialist-owned analysis. This is a relevance-based sufficiency gate, not a fixed number of files or layers to scan.

```text
Faltam pastas obrigatórias em `{story-path}` (FEATURE needs_* / brownfield).

O2 não grava PRD/PLAN sem ANALYSIS|ARCH|SEC quando a flag correspondente é true. Max-3 perguntas de gap não substituem este gate.

1) Voltar ao O1: /orchestrate-analyze - <portable-feature-path>
2) cancelar
```

See also § Preconditions checklist.

---

## Clarification readiness STOP (REQ-004 / REQ-005 / RN02 / TE01)

After presence siblings pass, evaluate open questions on FEATURE / STORY / REFINE / Prior notes using `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/readiness-severity.md` (+ `clarify-depth.md`):

| Outcome | Action |
|---------|--------|
| **READY** (no unanswered question at the O2 gates, including `MINOR`) | Continue toward mode selection / per-story Write |
| **`open_question`** (any unanswered question, including `MINOR`) | **STOP** this story. Do not write PRD or PLAN |

**RN02:** `ANALYSIS/` / `ARCH/` / `SEC/` on disk does **not** imply READY.

**Dual plane:** do not treat SESSION `step_confirmed` / PLAN step Complete as clarification READY.

```text
Status: NEEDS_CLARIFICATION

Paths (portable):
- features/NNN-slug/…
- features/NNN-slug/USnn/STORY.md

Open B/I/MINOR:
- [B|I|MINOR] <sharp question>

1) Responder B/I (refine-story / O1) e reavaliar READY
2) cancelar

O2 não grava PRD/PLAN com B/I/MINOR abertos. Presence de pasta ≠ READY.
```
