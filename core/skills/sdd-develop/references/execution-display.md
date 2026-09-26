# Execution display

Chat-only. Load this file at `sdd-develop` step 0 before any code edit, and again at step 7. `orchestrate-develop` loads it before each spawn and after each receipt.

Render in the user chat language (`LANGUAGE.md`). Weight tokens stay `Low`, `Medium`, `High`, or `Very high`. Never a duration. Do not save the table in the PLAN.

The table shape is `LIVE-STAGE-TABLE.md`. Redraw the whole table when a row closes. One heartbeat line during a long operation, and only that line:

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
