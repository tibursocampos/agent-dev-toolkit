# Executing the approved steps

## Cadence
- `step_by_step`: stop after each completed NON-final step and wait for the next instruction. Completing the last step proceeds directly to closeout without another permission.
- `continuous`: run all approved steps until complete or blocked.
- The progress table follows `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` in both cadences.

## Doing the work
- Implement each step within its planned paths and outcomes.
- Check dependencies and current state before every step and on resume.
- When subagents are available, delegate proportionally to scope and risk, with scoped file ownership and a receipt. Follow `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`. Without subagents, implement in the current context.
- Run steps in parallel only when they are independent and file ownership is clear.
- Before a parallel wave, record for each step of the wave that it has no dependency on another step of the same wave and which paths it owns; path overlap alone is not enough to prove independence. If independence is not shown, run the steps in sequence.
- The coordinator is the SOLE writer of `PLAN.md`. Children return reports and never edit it.
- Collect all reports. Inspect and reconcile their actual diffs against planned ownership and outcomes. Resolve conflicts without clobbering changes, then update the plan.
- Tests are chosen by risk and by the plan. They are not required after every step.

## Scope control
- Before any unplanned file or step, consult the operator.
- Record the approved amendment and obtain renewed approval for material changes, per `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`.
- Do not silently expand scope. Suggestions from agents or reviewers are not authorized scope.

## Progress and interruption
- Update the plan's Progress ledger in the same edit that changes a step status: status, evidence, validation results, blockers and next action.
- On interruption, record partial work, evidence, blockers and the next action.
- On resume, reconcile the record with the real working tree before continuing.
- Stop and report exact blockers or failed checks. Never claim completion without evidence.
- Do not commit, push, merge or publish automatically.

## After a child returns
- Re-read the persisted `PLAN.md` and reconcile the child's receipt with it and with the actual diff before marking a step COMPLETED.
- Check that the files in the receipt are inside the step's planned paths and that the reported checks match what the step declares.
- Out-of-plan file, failed check or missing evidence: record the step as BLOCKED (or leave it IN_PROGRESS) with the blocker and the next action; do not advance and do not retry automatically. If an unplanned file needs approval, ask the operator once.
- With `step_by_step` and a parallel wave: stop once after the whole wave is reconciled, unless the wave includes the final step.
