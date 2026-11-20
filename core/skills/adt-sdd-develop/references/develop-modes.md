# Classic develop cadence

`step_by_step` and `continuous` describe how Classic SDD advances through the approved PLAN. They are independent of O3's serial dispatch policy and of the toolkit's `orchestrator_mode` preference.

## Resolve the cadence once

Use a cadence stated in the current invocation or recorded in the approved PLAN. Otherwise ask once at implementation start and use that choice for the run. Reuse a still-valid choice on resume. Existing CONTINUITY may provide optional context but is not required and does not override a current explicit choice.

| Cadence | Behavior |
|---|---|
| `step_by_step` | Implement one eligible PLAN step, update and re-read its canonical progress row, show the complete contextual table and result, then wait before starting another step. |
| `continuous` | Implement eligible steps serially while the work remains within the approved PLAN and no material blocker occurs. Re-read and reconcile the PLAN row after each step before proceeding. |

Unknown or conflicting cadence is resolved with one focused question; do not silently invent another mode. A new plan approval is needed only when a material change affects its outcome, acceptance, scope, access, or implementation decisions.

## Rules for both cadences

- Verify the approved PLAN, requested scope, completed dependencies, step acceptance, and applicable validation semantically. Exact labels or formatting are not authorization gates.
- The PLAN progress table is the only persisted implementation state. Do not create session flags, claim files, counters, separate checkpoints, or progress mirrors.
- A step may be completed when its acceptance is met and its applicable required validation has passed; record the evidence in the same row.
- Stop for a real blocker, failed required validation, or material scope change. Do not add adjacent work.
- In O3, `continuous` still means the parent dispatches serially, one child per step. `adt-sdd-develop` does not dispatch the next O3 step.

## Report shape

Use the full contextual PLAN-step table and a concise result. The table is a chat projection; do not copy it into another artifact.
