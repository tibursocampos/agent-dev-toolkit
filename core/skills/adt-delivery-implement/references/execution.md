# Executing the approved steps

## Cadence
- `step_by_step`: stop after each completed NON-final step and wait for the next instruction. Completing the last step proceeds directly to criterion tests and closeout without another permission.
- `continuous`: run all approved steps until complete or blocked.
- The progress table follows `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` in both cadences.
- `orchestrator_mode` (preferences): `always` delegates every step to a child; `adaptive` keeps in the parent only the trivial work defined in `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` ("Delegation checklist"). Applies when subagents are `native`.

## Doing the work
- Implement each step within its planned paths and outcomes. Read the applicable structure, architecture, stack and testing references from the plan's `Guidelines:` index. Reuse the target repository's observed conventions where they settle implementation or test style.
- A step that names a domain skill (`adt-ef-add-migration`, `adt-i18n-manager`, `adt-containerize`, `adt-test-coverage`, `adt-repair-dotnet-build`) invokes that skill for that step, inside the step's paths. No other domain skill runs.
- Check dependencies and current state before every step and on resume.
- When subagents are available, delegate proportionally to scope and risk, with scoped file ownership and a receipt. Follow `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`. Without subagents, implement in the current context.
- Only `continuous` permits parallel steps. Each step must be independent with clear file ownership. `step_by_step` dispatches one step at a time.
- Before a parallel wave, record for each step of the wave that it has no dependency on another step of the same wave and which paths it owns; path overlap alone is not enough to prove independence. If independence is not shown, run the steps in sequence.
- The coordinator is the SOLE writer of `PLAN.md`. Children return reports and never edit it.
- Before completing a step, run the checks the plan requires for that step and record actual evidence. Defer only checks reserved for final criterion testing or closeout.

## Child prompts
Every child prompt states, in English:
- the step id, its planned paths and its expected outcome;
- the criteria it covers, by existing identifier or an unambiguous reference;
- the guideline paths for its area, copied from the `Guidelines:` line (only those), and the instruction to read them and relevant target repository instructions;
- the rule `{{TOOLKIT_ROOT}}/rules/ai-stealth.mdc`: no AI references in code, comments, identifiers, log messages or returned text;
- the receipt requirement (`{{TOOLKIT_ROOT}}/skills/_shared/agents/RECEIPT.md`) and that it must not edit `PLAN.md`.

## Criterion tests (after the last approved step, before closeout)
1. For each criterion, find or write a test that asserts its expected outcome. Use the test convention evidenced in the target repository and recorded in the plan. Use the toolkit stack guideline as fallback when the repository provides no convention (for example, .NET `Should_<Result>_When_<Condition>`).
2. Cover every criterion, including its failure and edge cases. Adjust an existing test only when it asserts the criterion's behavior differently; never weaken an assertion to make a test pass.
3. Write the tests in the files the plan lists under Impact. A new test file outside the planned paths needs the operator's approval first (scope control below).
4. Record in Progress the criterion and the test name and file that prove it. Equivalent references are acceptable. A criterion without the required evidence is open: record the concrete gap and next action.
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
- With `step_by_step`, stop after reconciling the single completed step, unless it is the final step.
