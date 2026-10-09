# Execution display

Chat-only. Load this file at `sdd-develop` step 0 before any code edit, and again at step 7. `orchestrate-develop` loads it before each spawn and after each receipt.

Render in the user chat language (`LANGUAGE.md`). Weight tokens stay `Low`, `Medium`, `High`, or `Very high`. Never a duration.

## Operator chat (`step_by_step`)

Before the step, the chat shows three things and then waits:

1. A narrative summary of the step.
2. What the PLAN says to do for that step.
3. The blocking question. It follows `core/policy/guardrails.md` § Open questions without a written deadline.

With a valid receipt, the chat adds one short result. Name the step, the status (`done`, `blocked`, or `failed`), and the tests. Do not add a second status vocabulary.

These leave the operator chat in `step_by_step` and in `continuous`:

- The stage-weight table (stage, analysis weight, status — Etapa, Peso, Estado) and any redraw of that table.
- The `Develop:` heartbeat line.
- A ledger dump (claim payload, raw ledger, or a substitute for the step ledger).

The progress table inside the PLAN file stays. Update it in the same edit that changes the step status.

## Step ledger at close

When a step closes, show the existing PLAN step ledger for every step. Columns: Step ID, Step, Dependencies, Analysis weight, Status, Evidence. In the user chat language those headers are Step ID, Passo, Dependências, Peso, Estado, Evidência. Do not replace that ledger with the stage-weight table.

Also show the `- [ ]` / `- [x]` rows for the active `STEP n` in `REFINE/tasks.md`. When the step is `COMPLETED`, set its glyph to `☑` and mark those boxes `- [x]`. Analysis weight is qualitative. It is not effort and not a duration.

Do not narrate skill reads, agent names, or waits. Do not invent events, streaming, or a heartbeat cadence.

## Receipt order

For O3 reconciliation, the parent’s order is fixed: validate the child receipt; persist and re-read the PLAN checkpoint and progress table; show the step ledger and, for a valid receipt, the short result; then evaluate the next spawn. The stage-weight table is not part of that order. The PLAN ledger/checkpoint, PLAN-LEDGER claim, short result, and `CONTINUITY.md` remain separate artifacts with separate owners and moments. A receipt whose `status` is outside `done`, `blocked`, and `failed`, or an implementation outside the PLAN acceptance, blocks the step: describe the deviation in one question, do not delegate the next step, do not invent a fix, and do not rewrite the PLAN. Receipt status `COMPLETED` is outside that allow list. Missing or failed receipt validation pauses the step and dependents; no success state or next spawn is inferred.

## Checkpoint before the first edit

In `step_by_step`, the checkpoint is the narrative summary, what the PLAN says to do, and the blocking question. Also name the step id when the summary does not already name it.

If the step was `BLOCKED`, the first line states the recorded block and that it is no longer in the file. Without that line, do not start.

## Failure

```text
{code}: {cause}. Next action: {action}.
```

Allowed codes: `plan_stale`, `step_blocked`, `ledger_partial`. The step becomes `BLOCKED` with the cause in the PLAN. Dependents stay `PENDING`.

Render the sentence in the user chat language. Keep the code in English.
