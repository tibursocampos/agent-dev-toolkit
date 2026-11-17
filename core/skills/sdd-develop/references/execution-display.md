# sdd-develop progress display

Use `LIVE-STAGE-TABLE.md` for the one contextual table owner and display points. Render the full current PLAN-step projection in the user's chat language. The PLAN progress table remains the only persisted implementation state.

## PLAN-step table

Show one row for every PLAN step, including completed and blocked steps. Use columns for step ID, step, dependencies, state, evidence/validation, and blocker/next action. Do not collapse steps, show only the changed row, or add a second checkpoint table.

Render the complete table:

1. At the beginning, after the PLAN and initial states are known.
2. When a meaningful step state changes or a specialist result is reconciled.
3. When a decision blocks affected work and after its answer is incorporated.
4. On resume and at close or handoff.

Combine adjacent events into one display; do not repeat identical tables or invent heartbeat updates. A question or comparison may use its own table only when it does not duplicate progress state.

## Step-by-step behavior

Before the first edit, show the full table and a concise summary of the selected step and its PLAN acceptance. The approved PLAN authorizes its stated scope; do not ask the user to approve each step again. After a completed step, show the updated full table and result, then stop before starting another step.

## Continuous behavior

After each step, re-read and reconcile the PLAN, render the updated full table, then continue to the next eligible step covered by the approved scope. Stop at completion or a real blocker. When a direct step is delegated, the parent validates the relevant result and reconciles the PLAN before continuing; a receipt alone does not establish completion.

## O3 ownership

When this skill runs inside O3, the parent owns and renders the contextual table after reconciling each serial child result. The child returns its result without drawing a competing table or dispatching another step.

## Blocked step

Record the concrete cause and affected dependents in the PLAN row, keep dependent steps pending, show the complete table, and state the next action. Do not infer success or advance past the blocker.
