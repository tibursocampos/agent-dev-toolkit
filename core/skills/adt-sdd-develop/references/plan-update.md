# Update the PLAN

The PLAN progress table is the only persisted implementation progress record. Each step has one row with dependencies, state, evidence/validation, and blocker/next action.

## Before implementation

1. Re-read the canonical PLAN and confirm the approved scope and requested step.
2. Confirm dependencies and any previously recorded blocker are resolved.
3. Change only the target row to `IN_PROGRESS`, preserving other rows and user edits; save and re-read the PLAN before changing code.

## When the step closes

1. Finish implementation and applicable validation.
2. Update the same row to `COMPLETED` when acceptance and required checks pass, or `BLOCKED` when a concrete blocker remains.
3. Record concise observed evidence, validation outcomes and limits, and a concrete next action. Keep dependent rows `PENDING` when blocked.
4. Re-read the PLAN and confirm the row and surrounding table agree with the reported result.
5. Render the full current contextual table using `execution-display.md`.

Do not add or synchronize a progress counter, header status, progress bar, detailed-step status, checklist, SESSION state, claim, or CONTINUITY checkpoint. Detailed step text describes the objective and acceptance but does not duplicate progress.

## Ownership

The implementer of a direct step updates that step's row. When a direct step is delegated, its implementer reports the result and the parent reconciles the saved PLAN before displaying the complete table or advancing. For O3, the child returns its scoped result and the parent reconciles the PLAN and owns the serial queue. Do not treat a receipt as sufficient evidence without checking the implementation and PLAN row.

## Completion

The PLAN is complete when all included steps and required validation are complete, with no unresolved material blocker. Do not require a separate whole-PLAN close authorization or close a companion PRD by rigid title/status grammar. Preserve existing related artifacts and update them only when the approved PLAN explicitly includes that work.
