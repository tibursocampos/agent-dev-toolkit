# Executing the approved steps

## Cadence
- `step_by_step`: stop after each completed NON-final step and wait for the next instruction. Completing the last step proceeds directly to criterion tests and closeout without another permission.
- `continuous`: run all approved steps until complete or blocked.
- The progress table follows `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` in both cadences.
- `orchestrator_mode` (preferences): `always` delegates every step to a child; `adaptive` keeps in the parent only the trivial work defined in `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` ("Delegation checklist"). Applies when subagents are `native`.

## Doing the work
- Implement each step within its planned paths and outcomes, following the guideline files in the plan's `Guidelines:` line: structure and naming from `structure-and-quality.md`, layering from the architecture file, the stack file for the language, and its test shape.
- A step that names a domain skill (`adt-ef-add-migration`, `adt-i18n-manager`, `adt-containerize`, `adt-test-coverage`, `adt-repair-dotnet-build`) invokes that skill for that step, inside the step's paths. No other domain skill runs.
- Check dependencies and current state before every step and on resume.
- When subagents are available, delegate proportionally to scope and risk, with scoped file ownership and a receipt. Follow `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`. Without subagents, implement in the current context.
- Run steps in parallel only when they are independent and file ownership is clear.
- Before a parallel wave, record for each step of the wave that it has no dependency on another step of the same wave and which paths it owns; path overlap alone is not enough to prove independence. If independence is not shown, run the steps in sequence.
- The coordinator is the SOLE writer of `PLAN.md`. Children return reports and never edit it.
- Tests are chosen by risk and by the plan. They are not required after every step; the criterion tests come at the end.

## Child prompts
Every child prompt states, in English:
- the step id, its planned paths and its expected outcome;
- the criteria ids it covers (`A1, ...`);
- the guideline paths for its area, copied from the `Guidelines:` line (only those);
- the rule `{{TOOLKIT_ROOT}}/rules/ai-stealth.mdc`: no AI references in code, comments, identifiers, log messages or returned text;
- the receipt requirement (`{{TOOLKIT_ROOT}}/skills/_shared/agents/RECEIPT.md`) and that it must not edit `PLAN.md`.

## Criterion tests (after the last approved step, before closeout)
1. For each criterion `A1..An`, find or write the test that asserts its Then clause. Name it with the test pattern of the plan's Validation (for .NET `Should_<Result>_When_<Condition>`), and follow the test shape of the stack test file in the `Guidelines:` line.
2. Cover every criterion, including its failure and edge cases. Adjust an existing test only when it asserts the criterion's behavior differently; never weaken an assertion to make a test pass.
3. Write the tests in the files the plan lists under Impact. A new test file outside the planned paths needs the operator's approval first (scope control below).
4. Record in Progress one line per criterion: `A1 -> <test name> (<file>)`. A criterion without a test is open: record it as `BLOCKED` with the next action.
5. Run the closeout (`references/closeout.md`).

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
