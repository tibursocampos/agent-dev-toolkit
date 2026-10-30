# sdd-spec — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process. Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `CAVEMAN.md` |
| -1 | Pipeline + STORAGE; `invocation_context`; load provenance | `PIPELINE.md`, `STORAGE.md`, `INVOCATION-CONTEXTS.md`, `CONTRACT-PROVENANCE.md` |
| 0 | Workspace; detect stack; resolve NNN / US01 default | `STORAGE.md` |
| 1 | Requirements (gap questions in question blocks of ≤5; selective retrieval; required siblings STOP) | `SELECTIVE-RETRIEVAL.md`; `PIPELINE.md` § Prior |
| 2–5 | Confirm repo, explore, clarify (question blocks of ≤5), technical analysis | — |
| 5.5 | Challenge vagueness + **product depth** + REQ (`agreed` vs `invented`); no how/code | `references/challenge-vagueness.md`, `references/req-tracking.md`; lazy `feature-altitude.md`, `invest-and-story-quality.md`, `gherkin-budget.md`, `clarify-depth.md`, `product-evidence-lite.md`; `anti-task-shatter.md` only if titles task-shaped; `CONTRACT-PROVENANCE.md` |
| 6.75 | Approve PRD content (**sim** / **ajustar** / **cancelar**). Approval does not authorize a write | `PIPELINE.md` |
| 6.8 | Open-question gate on story siblings (STORY, required ANALYSIS / ARCH / SEC). Ask every open question in question blocks of ≤5. **sim** does not close `open_question` | `readiness-severity.md` § Open-question gate |
| 6.9 | Confirm before write (**sim**) | `PIPELINE.md` |
| 7 | Write PRD only when step 6.9 is clear (Agent + sim); portable paths | `references/template-usage.md`, `references/filename-numbering.md`, `references/storage-gitignore.md` |
| 7.5 | Structural validate (`validate-prd`; CHANGE when brownfield) | `references/validate-prd.md`, `references/validate-change.md` |

## Stage table

Standard, state keys, glyphs, and label map: `LIVE-STAGE-TABLE.md` (§ sdd-spec). Columns, in order: `stage`, `status`, `weight`, `what_happened`. Headers and state labels follow the user chat language; glyphs are the ASCII ones from the standard.

| Stage | Weight | Covers step |
|-------|--------|-------------|
| Resolve workspace and requirements | Medium | -1, 0, 1 |
| Explore the repo | High | 2-5 (repo exploration, technical analysis) |
| Clarify (question blocks) | Medium | 2-5 (question blocks) |
| Draft | High | 5.5 |
| Review | High | 5.5 (vagueness, product depth, REQ contract) |
| Content gate | Low | 6.75, 6.8 |
| Preview | Low | 6.9 (summary before the write question) |
| Write gate | Low | 6.9 (write confirmation) |
| Persist | Low | 7, 7.5 |

You must render the full table at each of these points:

1. When the flow starts: first row `in_progress`, the rest `pending`.
2. Before each gate (each question to the operator).
3. After each gate answer.
4. On each row state change.
5. On a blocker or failure: stop the redraw at `blocked`, name the cause, and do not present a successful table.
6. At close or handoff.

Completeness: always render the full table with every row. Do not summarize rows, show only the changed row, or omit completed rows. `skipped` requires a reason in `what_happened`.

Gate answers use **sim** / **ajustar** / **cancelar**. Do not save this table in the PRD.

Quality: `references/quality-checklist.md`. Language: `references/product-docs-language.md`, `references/english-override.md`.
