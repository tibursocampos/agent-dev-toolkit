# Live progress tables

Chat-only progress projections. Render in the user's chat language (`LANGUAGE.md`). Do not persist these tables in PLAN, FEATURE, STORY, or CONTINUITY. For Classic SDD and O1/O2/O3, the PLAN's single execution table remains the only persisted implementation progress source.

## One owner per active flow

Only the owner below renders the contextual progress table. Internal skills and delegated children return their result to that owner; they do not render another progress table while the parent flow is active. A directly invoked skill owns its own table. When a parent delegates a direct Classic step, the parent reconciles the result and renders the current complete table.

| Invocation | Table owner |
|---|---|
| O1 (`adt-orchestrate-analyze`) | O1 |
| O2 (`adt-orchestrate-prepare`) with internal spec/plan | O2, across all selected stories and phases |
| O3 (`adt-orchestrate-implement`) with internal develop | O3, across PLAN steps and any requested closeout |
| Direct Classic `adt-sdd-spec`, `adt-sdd-plan`, or `adt-sdd-develop` | The directly invoked skill, or its delegating parent after reconciliation |
| ADT flow with internal stages | ADT flow |
| Direct ADT stage | The directly invoked stage |

Reuse existing invocation context to determine whether a skill is internal or direct. Do not add persisted flags, files, receipts, or protocols for table ownership.

## Display points

Render the complete current table:

1. At start, after identifying the work and initial state.
2. When a meaningful state changes, including after reconciling a specialist result.
3. When presenting a decision that blocks affected work.
4. After the answer is incorporated and work advances. Combine this with the state-change redraw when they are consecutive.
5. On resume, based on the current canonical artifacts.
6. At close or handoff.

Do not repeat an identical table for adjacent events in one response. A question, comparison, or survey may have its own table if it does not repeat progress state. Do not invent a heartbeat when no meaningful state changed.

## Table content

- **O1:** show understanding, needed investigation, story division/synthesis, and readiness for planning. Keep facts, inferences, suggestions, and decisions distinguishable in evidence.
- **O2:** use one row per story and relevant phase so PRD drafting, planning, and the single approval of the complete explicitly listed PLAN set remain visible in one table. Independent stories may progress while another is blocked. Internal spec/plan calls do not display another table.
- **O3 and Classic develop:** project every PLAN step, its dependencies, state, evidence/validation, and blocker or next action. Include closeout activities in this same contextual table when closeout is part of the requested scope; do not add a competing progress table.
- **Classic spec/plan:** show the stages of the directly invoked skill. A call made inside O2 is represented by the owning O2 story row.
- **ADT:** preserve the flow's existing external summary and direct-stage presentations. When coordinated by ADT flow, internal stage details belong in the corresponding flow row; internal stages do not draw a competing table. ADT's independent lifecycle remains governed by its own contracts.

Use clear state labels appropriate to the chat language (`pending`, `in progress`, `blocked`, `completed`). Evidence states what happened or points to the relevant artifact. A blocked row names the cause and affected work. Do not imply success when a step is blocked or validation is unavailable.

## O1 — `adt-orchestrate-analyze`

Show one stage table with rows for understanding the demand, targeted investigation (when needed), story division and synthesis, and handoff/readiness for planning. Do not add a cumulative checkpoint table. Optional analysis artifacts appear as evidence in the relevant row.

## O2 — `adt-orchestrate-prepare`

Show one cumulative table for the full O2 run. Repeat story rows for each eligible US/TS, identifying the story and its current phase: read/reconcile context, draft and substantively review PRD, plan, present the complete explicitly listed PLAN set for one approval, and reconcile readiness/handoff. Include conditional work only when it applies. Drafting/writing artifacts is preparation; do not show a separate write-approval gate. Approval does not recur for every story or document. Do not pair this table with a second cumulative checkpoint.

In continuous story preparation, reconcile a completed story and continue to the next eligible independent story without asking an extra continue question. Stop for a material blocker or decision that affects the next work.

## Classic `adt-sdd-spec` and `adt-sdd-plan`

Each direct invocation shows one stage table for that skill. Drafting, review, persistence, and handoff can be represented as relevant phases, but document writing is not a separate approval gate. `adt-sdd-plan` ends at handoff; it does not start implementation automatically. If invoked inside O2, suppress this table and update O2's story row.

## O3 and direct Classic `adt-sdd-develop`

Show one row for every PLAN step, with ID, step, dependencies, state, evidence/validation, and blocker/next action. Never omit completed rows or collapse ranges. Start from a re-read PLAN. After a child returns, reconcile its result and persisted PLAN state before redrawing or dispatching the next serial step. When closeout is requested/in scope, add its activities as rows to the same table; do not display a second closeout progress table.

## Other existing flows

The remaining sections preserve tables used by Backlog Refine and other direct skills; they do not create a second table for the flows above.

### adt-requirement-review: open questions

Columns: `id`, `severity`, `owner`, `question`, matching the skill and report template. One row per question. Resolved items stay in the Q&A history, not in the table once closed by the operator; pending and blocked questions appear. Render the full table at a stop and at close.

### adt-refine-story (feature, tech, split): stage table

Columns: `stage`, `status`, `what_happened`.

| Stage |
|---|
| Workspace and mode |
| Mode playbook (feature, tech, or split) |
| Clarify (question blocks) |
| Quality scorecard |
| Requirement review |
| Envelope status refresh |
| Validation |
| Persistence (when requested) |
| Handoff |

At close, render the scorecard with each criterion (`criterion`, `status`, `evidence`) in all three modes.

### adt-split-story-checklist: groups

Columns: `group`, `step_ids` (Steps), `wave`, `status`. Render in chat when the checklist is summarized and at its redraw points. Never collapse groups.

### ADT delivery (`adt-delivery-flow`, `adt-delivery-refine`, `adt-delivery-plan`, `adt-delivery-implement`)

Rows and weights are in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md`. Preserve ADT's external stage summary and direct-stage tables. The flow is sole display owner while it runs internal stages.
