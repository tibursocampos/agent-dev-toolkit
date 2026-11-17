# O3 PLAN contract

The approved PLAN is the authority for O3 scope, ordered steps, dependencies, acceptance, validation, and persisted implementation progress.

## Before dispatch

- Confirm the requested PLAN belongs to the feature/story scope and is the approved plan for the work.
- Interpret its step order, dependencies, acceptance, validation, and current state semantically. Do not require exact metadata wording, section grammar, or a structural validator as an authorization token.
- Dispatch only the first pending step whose dependencies are complete.
- Reuse the approval for the unchanged scope. If behavior, acceptance, scope, access, or a material implementation decision changes, stop and seek a decision before affected work.

## After a child returns

- Compare the changed paths and evidence with that step's acceptance and required checks.
- `done` is eligible for reconciliation only when those conditions are met; the parent updates the PLAN row and re-reads the PLAN.
- `blocked` or `failed` keeps dependent work from advancing. Record the factual reason and next action.
- Unknown, missing, or conflicting information calls for a focused clarification. Never treat a well-formed receipt as completion proof.

Do not use SESSION flags, PLAN claims, preflight output, or CONTINUITY as a substitute for the approved PLAN or its evidence. Do not mark multiple steps complete from one child result or introduce duration/effort estimates as gates.
