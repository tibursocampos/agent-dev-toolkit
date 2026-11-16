# ADT delivery - plan lifecycle

Applies to the single feature `PLAN.md` used by `adt-delivery-flow`, `adt-delivery-plan` and `adt-delivery-implement`.

## Two parts of PLAN.md

- `## Normative content` = what was approved: goal and scope, exclusions, evidence, decisions, acceptance criteria, affected paths, steps, intended validation.
- `## Operational record` = status: approval note, run choices, progress, evidence of results, closeout.

## Approval

- One explicit approval from the operator covers the whole plan. Silence, a review, or approval of refinement alone is not approval.
- Record it in the Operational record as one free line: date and one sentence of the approved scope. Example: `- Approved 2026-11-14: scope is the CSV export for the admin report, no schema changes.`
- Re-approve when the scope changes materially. Wording and formatting changes do not need approval.
- When implementation reveals a material change, stop the affected step, tell the operator and ask. Continue only after renewed approval, recorded as a new date line.

## Run choices and stages (informational)

- `Mode: full | analysis`. `analysis` stops after refine.
- `Subagents: native | none` and `Model choice: inherit | reuse_saved | choose_model | n/a`, recorded once per run.
- `Stage ledger`: refine, plan, implement, updated as each stage finishes. Each stage checks the ledger in prose at its entry: planning needs `refine=done`; implementation needs `plan=approved`, `Mode: full` and the approval line. A missing condition is reported and the stage stops.

## Resume

- Read the plan and reconcile its recorded progress with the real tree (branch, working tree, evidence) before continuing.
- No approval note: present the Normative content and ask for approval.
- Interrupted work: keep partial work, blockers and the next action in the Operational record.

## Closeout

- Final validation and the review report stay `pending` until performed.
- A completed step records its outcome and evidence; it does not imply that delivery is complete.

## Split plans

- Only when the operator agrees to split. Each independent plan has its own approval note, Choices and Progress; approving one never approves another.
