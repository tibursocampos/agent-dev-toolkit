# O3 command flow

1. Read the shared authorization, scope, and path-safety contracts.
2. Resolve the canonical feature and PLAN path(s); inspect existing PLAN state and relevant partial work.
3. Reuse the recorded PLAN approval. Resolve the cadence (`step_by_step` or `continuous`) only if no valid choice is recorded.
4. Build the eligible queue from PLAN order and dependencies. Display the complete O3 table once for the current state.
5. Dispatch one child for the first eligible step, or hand off that one step to manual `adt-sdd-develop` if child dispatch is unavailable.
6. Inspect the child's result and acceptance evidence. Update the PLAN row only when the step is complete; re-read the PLAN and display the full table after reconciliation.
7. Stop after one reconciled step for `step_by_step`. For `continuous`, continue serially through eligible steps until completion or a real blocker.
8. On resume, re-read the PLAN and inspect partial work. If another conversation may still own active implementation on the same PLAN, stop and resolve ownership.
9. Run closeout only when requested, adding its activities to the same contextual progress table.

See `execution-modes.md`, `develop-modes.md`, `plan-acquisition.md`, `plan-contract.md`, `step-queue-spawn.md`, and `continuity-handoff.md` for the relevant details. Do not load retired parallelism, SESSION, claim, or preflight procedures.
