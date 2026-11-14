# ADT delivery - plan lifecycle

Applies to the single feature `PLAN.md` used by `adt-delivery-flow`, `adt-delivery-plan` and `adt-delivery-implement`.

## Two parts of PLAN.md

- `## Normative content` = what was approved: goal and scope, exclusions, evidence, decisions, acceptance criteria, affected paths, steps, intended validation.
- `## Operational record` = status only: approval record, execution choices (branch, cadence, review mode), progress, evidence of results, closeout.
- Only changes to Normative content can invalidate approval. Operational updates never do.

## Approval record

Write this exact format inside the Operational record, as one line:

`Approval: pending | approved <YYYY-MM-DD> - scope: <one sentence of what was approved> | invalidated <YYYY-MM-DD> - reason: <why>`

| State | Meaning | Next action |
|-------|---------|-------------|
| pending | Plan presented, no explicit approval yet | Present the full plan and ask for one approval |
| approved | Explicit approval covers the current Normative content | Implementation may start, per the recorded choices |
| invalidated | A material change was made after approval | Present the amendment and obtain renewed approval before affected work |

- One explicit approval covers the full plan. Silence, a review, or approval of refinement alone is NOT approval.
- The planner or coordinator records the approval and its date concisely. Approval is tracked by that date and the scope sentence only; no checksums or text-identity comparisons.

## Run mode, subagents and stage ledger

- `Mode: full | analysis` in the Operational record. `analysis` stops after refine; plan and implement never start.
- `Subagents: native | none` and `Model choice: inherit | reuse_saved | choose_model | n/a` record the run's specialist choice. `native` requires a model choice other than `n/a`.
- `Stage ledger` tracks the stages: `refine=pending | done`, `plan=pending | approved`, `implement=pending | in_progress | done`.
- Refine sets `refine=done` at its exit. Plan sets `plan=approved` only after the single explicit approval is recorded in the Approval line.
- Implement moves `implement` to `in_progress` while work runs and to `done` after it finishes.
- The preflight `{{TOOLKIT_ROOT}}/scripts/runtime/Test-AdtDeliveryPreflight.ps1` reads these lines before each stage starts.
- A stage never starts unless the previous ledger value is satisfied: plan needs `refine=done`; implement needs `plan=approved` and an Approval line that reads approved.

## What is a material change

- Material: changes the goal, scope or exclusions, acceptance criteria, a decision, affected paths, the steps or their order, or the intended validation.
- Not material: wording, formatting, typos, reordering without meaning change, operational updates.
- The agent decides by comparing current Normative content with the approval scope sentence and with what the operator was shown.
- When unsure, show the operator a short summary of the difference and ask.
- Formatting alone never blocks work and never starts a re-approval loop.

## Amendment

- A material change marks the approval `invalidated` with the reason.
- That applies once the change is written into the plan. A change that is only needed, but not yet written, follows the blocking rule below.
- Present the amendment to the operator and obtain a new explicit approval.
- Record the new date and scope sentence BEFORE affected work continues.
- Unaffected steps continue only if the operator says so.
- Unplanned file or step found during implementation: consult the operator first, record the approved amendment, and obtain renewed approval if it is material.
- When implementation reveals that a material change is needed, block the affected step in the same edit that records the blocker and ask the operator; do not change Normative content yet. The approval is marked `invalidated <date> - reason: <why>` in the edit that writes the amendment, and approval returns only through a renewed explicit approval.
- If the operator keeps the approved scope instead, the plan stays `approved` unchanged; record the dropped change as a limitation or out-of-scope note in the Progress ledger and continue.

## Resume

- On every resume: read the selected plan and check that the approval record is `approved`.
- Compare Normative content with the approval scope, using the material-change rule.
- Inspect branch, working tree, progress and evidence; reconcile recorded progress with the actual repository before continuing.
- Missing or unclear approval record: present the current Normative content, obtain explicit approval and record it.
- Interrupted work: keep partial work, evidence, blockers and the next action in the Operational record.

## Closeout states

- Final validation and the review report stay `pending` until performed.
- A completed step records its outcome and evidence; it never implies that delivery is complete.
- Record limitations and remaining blockers next to each result.

## Split plans
- The feature-root plan holds the shared decisions; its approval covers those shared sections.
- Each independent plan carries its own Approval line, Choices and Progress. Approving one never approves another.
