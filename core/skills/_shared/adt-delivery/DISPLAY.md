# ADT delivery - progress display

The display standard, columns, glyphs, label map and the six display points are defined only in `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md`; this file lists rows and ADT rules. Render in the user chat language per `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`.

## Rows per skill

### adt-delivery-flow - stage table (weight in parentheses)

Table kind: stage table. Column keys: `stage`, `status`, `weight`, `what_happened`.

1. Storage and feature (Low)
2. Specialist triage (Medium)
3. Refinement (High)
4. Plan and approval (High)
5. Execution choices: branch, cadence, review mode (Low)
6. Implementation (Very high)
7. Final validation and code review (High)

### adt-delivery-refine - stage table

Table kind: stage table. Column keys: `stage`, `status`, `weight`, `what_happened`.

1. Storage and feature (Low)
2. Clarify outcome and scope (Medium)
3. Repository evidence (Very high)
4. Specialist triage (Medium)
5. Record in the plan (Low)
6. Handoff to planning (Low)

### adt-delivery-plan - stage table

Table kind: stage table. Column keys: `stage`, `status`, `weight`, `what_happened`.

1. Inputs and selected plan (Low)
2. Repository analysis (High)
3. Draft steps and validation (High)
4. Planner self-check (Medium)
5. Approval (Low)

### adt-delivery-implement - PLAN-step table plus closeout table

- PLAN-step table: one row for EVERY step S1..Sn of the approved PLAN. Never summarize, merge or omit rows. Column keys: `step_id`, `step`, `dependencies`, `status`, `evidence`, `next_action`.
- Closeout table: column keys `gate`, `status`, `owner`, `evidence`. Rows, in order:
  1. Approval still valid
  2. Branch and baseline recorded
  3. Final validation
  4. Code review
  5. Fixes and focused recheck
  6. Review report written

## ADT rules

- One table per moment: when `adt-delivery-flow` runs a stage, only the flow's stage table is shown; the stage skill does not draw its own. A skill invoked directly draws its own table.
- Analysis mode: the flow stage table ends at row 3 (Refinement); rows 4 to 7 are not drawn.
- The six display points (LIVE-STAGE-TABLE section 3) apply in every pacing. In `adt-delivery-implement` the full PLAN-step table appears in both `step_by_step` and `continuous`; pacing never changes the table.
- Before the first edit of an implementation start: show the PLAN-step table, a short summary of the next step and what the plan says to do. In `step_by_step`, wait for the answer.
- After a child or specialist returns: re-read the persisted `PLAN.md`, reconcile it with the receipt, then redraw the owning table. A child-drawn table or a prose summary does not count.
- The table is chat only and is never written into `PLAN.md`. The persisted record is the Progress ledger of the Operational record (`{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-TEMPLATE.md`), updated in the same edit that changes a step status.
- Weight is qualitative only (Low, Medium, High, Very high). Never durations, estimates or story points.
- Do not narrate skill reads, agent names, tool calls or waits. Do not invent a heartbeat. Never expose hidden reasoning.
- At `blocked`, or on a `failed` receipt shown as a `blocked` row, redraw with the blocked row and stop. Never imply success.
- On resume, redraw the table as at the start (display point 1) with every row set from the persisted state.
