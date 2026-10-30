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
- A claim payload, raw ledger, or any substitute for the PLAN step ledger.

The progress table inside the PLAN file stays. Update it in the same edit that changes the step status.

## Step ledger at close

### Classic / direct

After every direct Classic step closes—whether it ran in the parent or a delegated specialist—the parent MUST:

1. Re-read the persisted PLAN after the child returns. Reconcile the completed step row and checkpoint against the child's report; a child-provided table or prose summary is not the source of truth.
2. Render the complete current PLAN step ledger to the operator, including every step row and all columns: Step ID, Step, Dependencies, Analysis weight, Status, Evidence. In Portuguese, use Step ID, Passo, Dependências, Peso, Estado, Evidência.
3. State `Next eligible step: <step id and title>` or `Next eligible step: none — <closeout or blocker>` from the re-read PLAN.
4. Only after this table may a parent in `continuous` start the next direct step. This applies in both `step_by_step` and `continuous`; pacing never changes the ledger requirement.

Do not omit unchanged steps, summarize consecutive steps, or show only the just-closed step. If the PLAN cannot be re-read or its checkpoint conflicts with the child's report, stop with `ledger_partial`; do not infer success or start another step.

Example with mixed state:

| Step ID | Step | Dependencies | Analysis weight | Status | Evidence |
|---------|------|--------------|-----------------|--------|----------|
| S1 | Resolve skill references | none | Medium | COMPLETED | focused validator — PASS |
| S2 | Define evidence gate | S1 | High | PENDING | — |

**Next eligible step:** S2 — Define evidence gate

Do not replace this ledger with the stage-weight table.

### Orchestrated / O3

For O3, use the `orchestrate-develop (O3) — PLAN-step progress table` in `LIVE-STAGE-TABLE.md`. Render one row for every PLAN step at queue start and redraw the complete projection after each child return and checkpoint reconciliation, before evaluating another spawn. That projection at step close is the O3 operator-facing ledger; do not also dump the raw PLAN ledger or weighted stage table. Track O3 closeout gates separately. Keep the persisted PLAN progress table as the durable state.

Show checklist rows only when applicable to the resolved invocation context. In `direct`, do not read or require `REFINE/tasks.md`; if the invocation explicitly adopted a related checklist, show only its rows for this step. In `orchestrated`, show only the scoped task rows provided by the O3 parent; missing required rows remain a block/return to O2. When the step is `COMPLETED`, set the step glyph to `☑` and mark applicable rows `- [x]`. Analysis weight is qualitative. It is not effort and not a duration.

Do not narrate skill reads, agent names, or waits. Do not invent events, streaming, or a heartbeat cadence.

## Receipt order

For O3 reconciliation, the parent’s order is fixed: validate the child receipt; read and reconcile the PLAN checkpoint already persisted by the child; show the step ledger and, for a valid receipt, the short result; then evaluate the next spawn. The child `sdd-develop` session is the sole writer of its step row and checkpoint; the parent is read-only for those fields. A missing or conflicting checkpoint returns to its owner for correction in a fresh invocation and blocks dependent steps. The stage-weight table is not part of that order. The PLAN ledger/checkpoint, PLAN-LEDGER claim, short result, and `CONTINUITY.md` remain separate artifacts with separate owners and moments. Before reconciliation, consume only the validator’s canonical receipt projection: the producer emits `done`, and the guard normalizes the supported `complete` / `completed` aliases to `done`. After normalization, canonical status must be one of `done`, `blocked`, or `failed`; any unknown status or implementation outside the PLAN acceptance blocks the step: describe the deviation in one question, do not delegate the next step, do not invent a fix, and do not rewrite the PLAN. Do not copy the PLAN row label `COMPLETED` into the receipt. Missing or failed receipt validation pauses the step and dependents; no success state or next spawn is inferred.

## Checkpoint before the first edit

In `step_by_step`, the checkpoint is the narrative summary, what the PLAN says to do, and the blocking question. Also name the step id when the summary does not already name it.

If the step was `BLOCKED`, the first line states the recorded block and that it is no longer in the file. Without that line, do not start.

## Failure

```text
{code}: {cause}. Next action: {action}.
```

Allowed codes: `plan_stale`, `step_blocked`, `ledger_partial`. The step becomes `BLOCKED` with the cause in the PLAN. Dependents stay `PENDING`.

Render the sentence in the user chat language. Keep the code in English.
