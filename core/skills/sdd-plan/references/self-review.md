# Plan self-review

Run this list on the draft. Fix what fails. Run the list again. If the second pass still fails, stop without writing the PLAN. `validate-plan` runs after a successful write. It does not replace this review.

**sim** at confirm-before-write comes only after both passes succeed.

Do not write a draft that still has an open question. The saved Open decisions section stays empty.

## Checklist

- One story slice: the STORY and the closed PRD for this plan.
- `AGENTS.md`: when missing, record `not_found` and continue. Absence does not block.
- Current repository evidence outranks `memory-bank` when they disagree.
- Every PRD acceptance criterion maps to a step and a test. A criterion with no evidence is `BLOCKED`. Any `BLOCKED` row blocks the write.
- No invented existing path or symbol. An existing path was read. A new path is `proposed`.
- Actions are only `CREATE`, `MODIFY`, `REMOVE`, or `NO_CHANGE`.
- `Dependency and execution graph` is one Mermaid `flowchart`. Each step id from `REFINE/tasks.md` appears once.
- Step status tokens are only `PENDING`, `IN_PROGRESS`, `BLOCKED`, `COMPLETED`, `SKIPPED`. A new plan is `NOT_STARTED` with progress `0/N` and every step `PENDING`.
- Execution checkpoint: last mode `NOT_STARTED`, active step, next eligible, portability `NOT_STARTED`. Portable paths only.
- Each test has a precondition, an action, and an assertion.
- A validation command appears only when the repo already shows it. Do not claim it already ran.
- Risks have evidence. No production code. No duration.
- Filled prose follows the chat language (`LANGUAGE.md`). Tokens stay English.
