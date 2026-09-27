# Plan self-review

Run this list on the draft. Fix what fails. Run the list again. If the second pass still fails, stop without writing the PLAN. `validate-plan` runs after a successful write. It does not replace this review.

**sim** at confirm-before-write comes only after both passes succeed.

Do not write a draft that still has an open question. When nothing is open, the saved Open decisions section is exactly one sentence (`No open decision.` or the content-language equivalent). An empty heading fails the review.

## Checklist

- One story slice: the STORY and the closed PRD for this plan.
- `AGENTS.md`: when missing, record `not_found` and continue. Absence does not block.
- Current repository evidence outranks `memory-bank` when they disagree.
- Every PRD acceptance criterion maps to a step and a test. A criterion with no evidence is `BLOCKED`. Any `BLOCKED` row blocks the write.
- No invented existing path or symbol. An existing path was read. A new path is `proposed`.
- Actions are only `CREATE`, `MODIFY`, `REMOVE`, or `NO_CHANGE`.
- Each step id in `REFINE/tasks.md` appears once as a node **and** every blocking dependency is an arrow. A node list with no edges is invalid when any step has a dependency. Isolated nodes are only the steps whose dependency is `none`.
- Step status tokens are only `PENDING`, `IN_PROGRESS`, `BLOCKED`, `COMPLETED`, `SKIPPED`. A new plan is `NOT_STARTED` with progress `0/N` and every step `PENDING`.
- Section titles in the saved file follow content-language. `## Execution policy` stays English. Do not leave mixed English/Portuguese headings.
- `Open decisions`: when none remain, write exactly one sentence in content-language, `Nenhuma decisão em aberto.` or `No open decision.` That sentence is not an open decision. Do not leave the heading with an empty body.
- Do not author `REFINE/tasks.md`. Read it. If `medium`/`complex` and the file is missing, stop.
- Each PLAN step has at least one `- [ ]` row in `tasks.md` with the same `STEP n`. A step without those boxes fails the review.
- Each step block is visually separated: heading, one field per line, then `---`. Status line uses `☐` `◐` `☑` `⊘` `⚠` plus the English token.
- The step states symbols, the change, what not to touch, and the acceptance text. A contract signature and a short excerpt of existing code are allowed. A new method body is not.
- Execution checkpoint: last mode `NOT_STARTED`, active step, next eligible, portability `NOT_STARTED`. Portable paths only.
- Each test has a precondition, an action, and an assertion.
- A validation command appears only when the repo already shows it. Do not claim it already ran.
- Risks have evidence. No production code. No duration.
- Filled prose follows the chat language (`LANGUAGE.md`). Tokens stay English.
