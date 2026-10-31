# sdd-plan — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process. Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `CAVEMAN.md` |
| -1 | Pipeline + STORAGE; `invocation_context` | `PIPELINE.md`, `STORAGE.md`, `INVOCATION-CONTEXTS.md` |
| 0 | Workspace; stack; classic feature root | `STORAGE.md` |
| 1 | Resolve PRD (canonical path only) | `references/filename-numbering.md` |
| 2–4 | Resolve `direct` vs `orchestrated`: direct derives PLAN-native steps from the approved PRD and never acquires O1 checklist inputs; O2 validates/acquires its required checklist through its owner, then preserves those IDs. Two self-reviews before preview | `references/checklist-acquisition.md`, `references/baby-step-sizing.md`, `references/self-review.md`, `references/challenge-vagueness.md`, `references/plan-magro.md`; `LIVE-STAGE-TABLE.md` § sdd-plan |
| 5.5 | PLAN storage path | `references/storage-gitignore.md` |
| 5.75 | Confirm before write (**sim**) | `PIPELINE.md` |
| 6 | Write PLAN (Agent + sim; magro; Execution policy; Mapa REQ) | `references/template-usage.md`, `references/plan-magro.md` |
| 6.5 | Structural validate (`validate-plan`) | `references/validate-plan.md` |
| 7 | Validate with user; handoff develop | `references/quality-checklist.md`, `references/status-legend.md` |

## Stage table

Standard, state keys, glyphs, and label map: `LIVE-STAGE-TABLE.md` (§ sdd-plan). Columns, in order: `stage`, `status`, `weight`, `what_happened`. Headers and state labels follow the user chat language; glyphs are the ASCII ones from the standard.

| Stage | Weight | SKILL step |
|-------|--------|------------|
| Resolve PRD | Medium | 1 |
| Explore the repo | Very high | 2-4 item 5 (repository evidence) |
| Draft | High | 2-4 items 1-3 (derive steps, REQ map) |
| Review 1 | High | 2-4 item 4, first pass |
| Review 2 | High | 2-4 item 4, second pass |
| Content gate | Low | 5.75 |
| Preview | Low | 5.9 (summary before the write question) |
| Write gate | Low | 5.9 (write confirmation) |
| Persist | Low | 6, 6.5 |

You must render the full table at each of these points:

1. When the flow starts: first row `in_progress`, the rest `pending`.
2. Before each gate (each question to the operator), including the content gate and the write gate.
3. After each gate answer.
4. On each row state change, including the start and end of Review 1 and Review 2.
5. On a blocker or failure (a failed second review, an open question, a failed validation): stop the redraw at `blocked`, name the cause, and do not present a successful table.
6. At close or handoff.

Completeness: always render the full table with every row. Do not summarize rows, show only the changed row, or omit completed rows. `skipped` requires a reason in `what_happened`.

Gate answers use **sim** / **ajustar** / **cancelar**. Do not save this table in the PLAN.

Selective retrieval: `references/selective-retrieval.md`. Product docs language: `references/product-docs-language.md`.
