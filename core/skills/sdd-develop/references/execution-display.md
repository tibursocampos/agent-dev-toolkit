# Execution display

Chat-only. Load this file at `sdd-develop` step 0 before any code edit, and again at step 7. `orchestrate-develop` loads it before each spawn and after each receipt.

Render in the user chat language (`LANGUAGE.md`). Weight tokens stay `Low`, `Medium`, `High`, or `Very high`. Never a duration.

Two tables. Do not confuse them.

1. **Stage table** — chat only. Shape: `LIVE-STAGE-TABLE.md`. Do not save it in the PLAN.
2. **Step ledger** — the plan section `Implementation progress`, plus the `- [ ]` rows for the active `STEP n` in `REFINE/tasks.md`. Show both at the start of the step and again when the step closes. When the step is `COMPLETED`, set its glyph to `☑` and mark those boxes `- [x]`. Columns: Step ID, Step, Dependencies, Analysis weight, Status, Evidence. Update that section in the PLAN in the same edit that changes the step status. Analysis weight is qualitative. It is not effort and not a duration.

The stage table shape is `LIVE-STAGE-TABLE.md`. Redraw the whole stage table when a row closes. Redraw the step ledger when a step status changes. One heartbeat line during a long operation, and only that line:

```text
Develop: {table row} — {step id}
```

Do not narrate skill reads, agent names, or waits.

## Rows

Fixed order:

| Stage | Analysis weight |
|-------|-----------------|
| Re-check the plan against the repo | `High` when the step or PLAN cites persistence; otherwise `Medium` |
| Mark the step `IN_PROGRESS` and re-read the file | `Low` |
| Implement the step | `High` when acceptance cites more than one REQ; otherwise `Medium` |
| Focused validation of the step | `Medium` |
| Write the ledger and the checkpoint | `Low` |
| Step summary | `Low` |

## Checkpoint before the first edit

Show, in the user chat language:

- Step id and title
- Dependencies already `COMPLETED`
- Counts: pending, in progress, blocked, completed
- Mode `step_by_step` or `continuous`
- Current portability

If the step was `BLOCKED`, the first line states the recorded block and that it is no longer in the file. Without that line, do not start.

## Failure

```text
{code}: {cause}. Next action: {action}.
```

Allowed codes: `plan_stale`, `step_blocked`, `ledger_partial`. The step becomes `BLOCKED` with the cause in the PLAN. Dependents stay `PENDING`.

Render the sentence in the user chat language. Keep the code in English.
