# PLAN execution contract

Use the approved PLAN as the source for implementation scope, step order, acceptance, validation, and progress. Evaluate meaning rather than exact headings, IDs, or formatting.

## Before implementation

- Resolve the canonical PLAN path and the requested step.
- Confirm one explicit approval covers the intended outcome, scope, access, and implementation decisions. A recorded note is useful evidence; no exact token, hash, flag, or approval status is required.
- Confirm the step's dependencies are complete and its acceptance is clear enough to evaluate.
- Identify applicable validation and any material unresolved decision. A checklist or sidecar is optional unless the current invocation explicitly adopted it.

If a missing or conflicting item could materially change scope, behavior, acceptance, access, or implementation, stop only the affected work and name the needed decision or evidence.

## Step lifecycle

1. Set the step's single PLAN progress row to `IN_PROGRESS` and re-read it before implementation.
2. Implement only the approved step. Follow repository conventions and preserve existing work.
3. Run validation that is required by the PLAN and relevant to acceptance/risk. Do not impose an automated test for every criterion or repeat unchanged checks for ceremony.
4. Set the same row to `COMPLETED` only when acceptance is met and applicable required validation passed. Record concise evidence and the next action. On a blocker or failed required check, set `BLOCKED`, record the cause, and keep dependent steps pending.
5. Re-read the saved PLAN before reporting or continuing. No separate progress header, counter, checkpoint, SESSION flag, task-state table, or claim is required.

`step_by_step` stops after one completed step. `continuous` may advance to the next eligible step within the already approved scope. Both modes execute steps serially.

## O3 child

The O3 parent assigns one PLAN step per child and owns queue eligibility and next dispatch. The child returns the role-specific receipt in `RECEIPT.md`; the parent checks it against the result and persisted PLAN before advancing. A receipt does not replace PLAN evidence or establish completion by itself.
