# Execution display

Chat-only. Load this file at `sdd-develop` step 0 before any code edit, and again at step 7. `orchestrate-develop` loads it before each spawn and after each receipt.

The table standard (state keys, glyphs, label map, completeness) is `LIVE-STAGE-TABLE.md`. Render in the user chat language (`LANGUAGE.md`) using its label map. Never a duration.

## PLAN-step table

Development flows (direct `sdd-develop` and O3) use one table: the PLAN-step table from `LIVE-STAGE-TABLE.md`. Columns, in order: `step_id`, `step`, `dependencies`, `status`, `evidence`, `next_action`. Header text comes from the label map (pt-BR: ID do passo, Passo, Dependências, Estado, Evidência, Próxima ação / responsável; English: Step ID, Step, Dependencies, Status, Evidence, Next action / owner). Status cells use the standard state labels and ASCII glyphs.

Rule: render every PLAN step as its own row. Never summarize consecutive rows, show only the changed row, or omit completed rows.

Example:

| Step ID | Step | Dependencies | Status | Evidence | Next action / owner |
|---------|------|--------------|--------|----------|---------------------|
| S1 | Resolve skill references | none | `[x]` completed | focused validator, PASS | none |
| S2 | Define evidence gate | S1 | `[~]` in progress | n/a | step child |
| S3 | Update the index | S2 | `[ ]` pending | n/a | after S2 |

The weighted stage table (stage, analysis weight, status) is not for development flows. Do not render it or any redraw of it in `step_by_step` or `continuous`.

## Display points (any pacing)

The same full table appears in `step_by_step` and in `continuous`. Pacing never changes the table requirement.

1. At the start of the run, before the first edit or spawn (the step to run is `in_progress`, the rest as persisted).
2. On each step state change.
3. When a blocker or failure becomes observable. Stop at `blocked`; do not imply success.
4. At close, after the PLAN is re-read (next section).

## Operator chat (`step_by_step`)

Before the step, the chat shows the PLAN-step table and then three things, and waits:

1. A narrative summary of the step.
2. What the PLAN says to do for that step.
3. The blocking question. It follows `core/policy/guardrails.md` § Open questions without a written deadline.

With a valid receipt, the chat adds one short result next to the table. Name the step, the status (`done`, `blocked`, or `failed`), and the tests. Do not add a second status vocabulary.

These leave the operator chat in `step_by_step` and in `continuous`:

- The weighted stage table and any redraw of it.
- The `Develop:` heartbeat line.
- A claim payload, raw ledger dump, or any substitute for the PLAN-step table.

The progress table inside the PLAN file stays, with its persisted structure unchanged. Update it in the same edit that changes the step status.

## Step table at close

### Classic / direct

After every direct Classic step closes, whether it ran in the parent or a delegated specialist, the parent MUST:

1. Re-read the persisted PLAN after the child returns. Reconcile the completed step row and checkpoint against the child's report; a child-provided table or prose summary is not the source of truth.
2. Render the complete current PLAN-step table, one row per step, with the columns above.
3. State `Next eligible step: <step id and title>` or `Next eligible step: none — <closeout or blocker>` from the re-read PLAN.
4. Only after this table may a parent in `continuous` start the next direct step. This applies in both `step_by_step` and `continuous`.

Do not omit unchanged steps, summarize consecutive steps, or show only the just-closed step. If the PLAN cannot be re-read or its checkpoint conflicts with the child's report, stop with `ledger_partial`; do not infer success or start another step.

### Orchestrated / O3

For O3, use the PLAN-step table in `LIVE-STAGE-TABLE.md`. Render one row for every PLAN step before the first spawn, and redraw the complete projection after each child return and checkpoint reconciliation, before evaluating another spawn. That projection is the O3 operator-facing table; do not also dump the raw PLAN ledger or the weighted stage table. Track O3 closeout gates separately. Keep the persisted PLAN progress table as the durable state.

Show checklist rows only when applicable to the resolved invocation context. In `direct`, do not read or require `REFINE/tasks.md`; if the invocation explicitly adopted a related checklist, show only its rows for this step. In `orchestrated`, show only the scoped task rows provided by the O3 parent; missing required rows remain a block/return to O2. When the step is `COMPLETED`, set the persisted step marker per the PLAN template and mark applicable rows `- [x]`.

Do not narrate skill reads, agent names, or waits. Do not invent events, streaming, or a heartbeat cadence.

## Receipt order

For O3 reconciliation, the parent’s order is fixed: validate the child receipt; read and reconcile the PLAN checkpoint already persisted by the child; show the PLAN-step table and, for a valid receipt, the short result; then evaluate the next spawn. The child `sdd-develop` session is the sole writer of its step row and checkpoint; the parent is read-only for those fields. A missing or conflicting checkpoint returns to its owner for correction in a fresh invocation and blocks dependent steps. The weighted stage table is not part of that order. The PLAN ledger/checkpoint, PLAN-LEDGER claim, short result, and `CONTINUITY.md` remain separate artifacts with separate owners and moments. Before reconciliation, consume only the validator’s canonical receipt projection: the producer emits `done`, and the guard normalizes the supported `complete` / `completed` aliases to `done`. After normalization, canonical status must be one of `done`, `blocked`, or `failed`; any unknown status or implementation outside the PLAN acceptance blocks the step: describe the deviation in one question, do not delegate the next step, do not invent a fix, and do not rewrite the PLAN. Do not copy the PLAN row label `COMPLETED` into the receipt. Missing or failed receipt validation pauses the step and dependents; no success state or next spawn is inferred.

## Checkpoint before the first edit

In `step_by_step`, the checkpoint is the PLAN-step table, the narrative summary, what the PLAN says to do, and the blocking question. Also name the step id when the summary does not already name it.

If the step was `BLOCKED`, the first line states the recorded block and that it is no longer in the file. Without that line, do not start.

## Failure

```text
{code}: {cause}. Next action: {action}.
```

Allowed codes: `plan_stale`, `step_blocked`, `ledger_partial`. The step becomes `BLOCKED` with the cause in the PLAN. Dependents stay `PENDING`.

Render the sentence in the user chat language. Keep the code in English.
