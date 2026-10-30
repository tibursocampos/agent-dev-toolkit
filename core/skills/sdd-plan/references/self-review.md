# Plan self-review

Run this list on the draft. Fix what fails. Run the list again. If the second pass still fails, stop without writing the PLAN. `validate-plan` runs after a successful write. It does not replace this review.

**sim** at confirm-before-write comes only after both passes succeed.

Do not write a draft that still has an open question. When nothing is open, the saved Open decisions section is exactly one sentence (`No open decision.` or the content-language equivalent). An empty heading fails the review.

## Checklist

- One approved canonical PRD scope. Consult a STORY or checklist only when the context contract makes it required or direct planning explicitly adopts a linked/supplied optional sibling.
- `AGENTS.md`: when missing, record `not_found` and continue. Absence does not block.
- Current repository evidence outranks `memory-bank` when they disagree.
- Every PRD acceptance criterion maps to a step and a proportional validation or existing-coverage disposition. A criterion with no sufficient evidence is `BLOCKED`; do not invent a redundant test to fill the matrix. Any `BLOCKED` row blocks the write.
- The readiness contract is separate from `READY`: `READY` closes clarification questions only. Before implementation, the DoR has complete REQ→CA→step mapping, planned validations, explicit scope/OOS and dependencies, and no unresolved implementation-affecting decision.
- The PLAN distinguishes planned validation from execution evidence. Step/US DoD cannot be satisfied by a planned check, clarification `READY`, or an unrecorded result.
- No invented existing path or symbol. An existing path was read. A new path is `proposed`.
- Actions are only `CREATE`, `MODIFY`, `REMOVE`, or `NO_CHANGE`.
- The invocation context is explicit and is not inferred from optional siblings. In `orchestrated`, each validated `REFINE/tasks.md` step id appears once as a PLAN graph node and every blocking dependency is an arrow. In `direct`, graph nodes use PLAN-native IDs unless an explicitly linked valid checklist is adopted; preserve adopted IDs/dependencies and do not invent checklist rows/IDs. Direct planning does not require task boxes. In either context, every real blocking dependency is represented and isolated nodes have no dependencies.
- Step status tokens are only `PENDING`, `IN_PROGRESS`, `BLOCKED`, `COMPLETED`, `SKIPPED`. A new plan is `NOT_STARTED` with progress `0/N` and every step `PENDING`.
- Section titles in the saved file follow content-language. `## Execution policy` stays English. Do not leave mixed English/Portuguese headings.
- `Open decisions`: when none remain, write exactly one sentence in content-language, `Nenhuma decisão em aberto.` or `No open decision.` That sentence is not an open decision. Do not leave the heading with an empty body.
- Do not author `REFINE/tasks.md`. In `orchestrated`, acquire a required missing checklist through `references/checklist-acquisition.md` and validate output before this review; missing or invalid required input blocks it. In `direct`, checklist absence is expected and does not block review.
- In `orchestrated`, each PLAN step has at least one `- [ ]` row in `tasks.md` with the same `STEP n`. In `direct`, no task-box correspondence is required; claim it only when an explicitly linked valid checklist was adopted. Keep content approval, write authorization, and implementation authorization distinct, and preserve the existing step/session gates.
- Each step block is visually separated: heading, one field per line, then `---`. Status line uses `☐` `◐` `☑` `⊘` `⚠` plus the English token.
- The step states symbols, the change, what not to touch, and the acceptance text. A contract signature and a short excerpt of existing code are allowed. A new method body is not.
- For each material flow, the plan cites current source paths and sections/symbols actually read, identifies each source's role, and traces applicable source/producer, selection/route, receiver, and effect. Unproven links name the sources checked and remain “not demonstrated”; a receiver does not imply a publisher or integration. A negative route is included when material, and a non-applicable role has a reason.
- The test strategy reuses sufficient existing coverage and adds checks only for distinct missing behavior or composition value; it records the primary proof boundary, disposition, owner, checkpoint, and proof limits for each REQ/CA behavior.
- Execution checkpoint: last mode `NOT_STARTED`, active step, next eligible, portability `NOT_STARTED`. Portable paths only.
- Each test has a precondition, an action, and an assertion.
- A validation command appears only when the repo already shows it. Do not claim it already ran.
- Risks have evidence. No production code. No duration.
- Filled prose follows the chat language (`LANGUAGE.md`). Tokens stay English.
