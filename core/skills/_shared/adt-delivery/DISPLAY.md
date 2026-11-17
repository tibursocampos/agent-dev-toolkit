# ADT delivery - progress display

Generic table ownership and display points are defined in `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md`; this file owns the ownership and suppression rule for the coordinated ADT flow, and lists its rows and rules. Render in the user chat language per `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`.

## Coordinated flow ownership

When `adt-delivery-flow` runs a stage skill, the flow owns the single progress table for the run and the internal stage skill suppresses its own table. Put the stage's current detail in the corresponding flow row. A stage invoked directly owns its own table. The coordinator and routing reference this contract rather than restating the ownership rule.

## Rows per skill

Rows follow the Process steps of each skill (`SKILL.md`). A row may cover more than one step; the step numbers after the weight say which.

### adt-delivery-flow - stage table (weight in parentheses)

Table kind: stage table. Column keys: `stage`, `status`, `weight`, `what_happened`.

1. Storage and feature (Low) - Step 1
2. Demand triage (Medium) - Step 2
3. Refinement (High) - Step 3, the refine stage
4. Plan and approval (High) - Step 4, the plan stage and its one approval
5. Execution choices: branch, cadence, review mode (Low) - Step 5, asked at the start of implement
6. Implementation (Very high) - Step 5, the implement stage steps; while implementation is active, report the active PLAN step ID and its current evidence or next action in this row
7. Closeout: validation, review, quality checks (High) - Step 5, the closeout of implement

### adt-delivery-refine - stage table

Table kind: stage table. Column keys: `stage`, `status`, `weight`, `what_happened`.

1. Storage, feature and entry check (Low) - Steps 1 and 2
2. Memory-bank (Low) - Step 4
3. Specialist triage (Medium) - Step 5
4. Guidelines (Medium) - Step 6
5. Clarify and evidence (Very high) - Step 7
6. Record in the plan (Low) - Step 8
7. Handoff to planning (Low) - Step 9

### adt-delivery-plan - stage table

Table kind: stage table. Column keys: `stage`, `status`, `weight`, `what_happened`.

1. Inputs and selected plan (Low) - Steps 1 and 2, ledger check `refine=done`
2. Context: memory-bank and guidelines (Medium) - Step 4
3. Source and specialist triage (High) - Step 5
4. Draft steps with criterion-to-test map (High) - Step 6
5. Planner self-check (Medium) - Step 7
6. Approval (Low) - Step 8
7. Handoff (Low) - Step 9

### adt-delivery-implement - one progress table

- Show one row for EVERY step S1..Sn of the approved PLAN. Never summarize, merge or omit rows. When closeout is in scope, append its activities to this same table; do not draw a second progress table. Use columns that can represent both step and closeout rows: `id`, `step_or_activity`, `dependencies`, `status`, `evidence`, `next_action_or_owner`.
- Append closeout rows in the order of `adt-delivery-implement/references/closeout.md`:
  1. Criterion map (closeout step 0)
  2. Final validation (closeout step 1)
  3. Code review (closeout step 2)
  4. Rerun after review changes (closeout step 3)
  5. Security pass, when needed (closeout step 4)
  6. Quality checks (closeout step 5)
  7. AI-trace scan (closeout step 6)
  8. Report written (`CODE-REVIEW.md` and the plan's Closeout)

## ADT rules

- Display point 1 (Start) is drawn at a named step of each skill, after the state it shows is resolved: flow Step 1 (after Step 0), refine Step 3, plan Step 3, implement Step 2 (before the first edit). Read this file at that step; it is a mandatory read, not a lazy one.
- One table per progress update: when `adt-delivery-flow` runs a stage, only the flow's table is shown; the stage skill does not draw its own. A skill invoked directly owns its own table.
- Analysis mode: the flow stage table ends at row 3 (Refinement); rows 4 to 7 are not drawn.
- Use the display points in `LIVE-STAGE-TABLE.md`: initial state, meaningful transition (including blocking decisions and reconciled answers/results), resume, and close/handoff. Combine adjacent events into one redraw. In `adt-delivery-implement`, show the full table in both `step_by_step` and `continuous`; pacing never changes the row set.
- Before the first edit of an implementation start: show the PLAN-step table, a short summary of the next step and what the plan says to do. In `step_by_step`, wait for the answer.
- After a child or specialist returns: re-read the persisted `PLAN.md`, reconcile it with the result, then redraw the owning table. A child-drawn table or a prose summary does not count.
- The table is chat only and is never written into `PLAN.md`. The persisted record is the Progress ledger of the Operational record (`{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-TEMPLATE.md`), updated in the same edit that changes a step status.
- Weight is qualitative only (Low, Medium, High, Very high). Never durations, estimates or story points.
- Do not narrate skill reads, agent names, tool calls or waits. Do not invent a heartbeat. Never expose hidden reasoning.
- At `blocked`, or on a failed result shown as a blocked row, redraw with the blocked row and stop. Never imply success.
- On resume, redraw the table as at the start (display point 1) with every row set from the persisted state.
