# Closeout: final validation and review

## When
- Run after all approved steps are COMPLETED.
- Final validation and review stay `pending` in the plan until performed. Completed steps alone do not mean delivery is complete.

## Order
1. Run the final validations listed in the plan's Validation section. For the workspace test command, follow `{{TOOLKIT_ROOT}}/skills/run-tests/SKILL.md`. Delegate bounded commands to `shell-runner` when subagents are available (`{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`); otherwise run them in-parent.
2. Invoke `{{TOOLKIT_ROOT}}/skills/code-review/SKILL.md` explicitly, as the closeout. Pass:
   - mode: `single` or `multi-angle`, as recorded in the plan's Choices;
   - the full resolved `PLAN.md` path, global storage included;
   - the focus, as recorded or asked once;
   - the base branch;
   - scope `working_tree` (all uncommitted delivery changes, staged and unstaged).
   - Do not pass a report path. `code-review` returns its report in chat.
   - `code-review` runs `/run-tests` itself as part of its verification; that is expected, as in the other flows.
3. After review-driven changes, run the affected validation again with `run-tests`. Or record in the plan that no change required a rerun.
4. Only if the plan's audit table has `needs_security` = `true`: have the `security` specialist review the final working-tree diff, after the review and the rerun (same order as `orchestrate-develop`). Use `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/security.md` and the spawn rules of `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md`. Findings come back in chat; no artifact is written. Treat them like review findings.

## Review report
- `code-review` does not write a file. This skill saves the consolidated report (findings, decision, evidence, limitations) as `CODE-REVIEW.md`.
- Place `CODE-REVIEW.md` next to the actual resolved plan: the feature root, or the folder of an independent plan (`plans/<unit-or-repo-slug>/`). Global storage included. Layout rules: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md`.
- Update the file after fixes, then recheck.
- Preexisting changes recorded in the start baseline are mentioned in the report as context.
- If preexisting changes cannot be told apart from delivery changes, say so. Ask the operator for a path list to pass to `code-review`. Do not guess the scope.

## Findings
- Fix actionable findings that fall inside the approved plan scope.
- Before touching any unplanned file or step, consult the operator. Amendment rule: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`. Review suggestions are not authorized scope.
- After fixes, do a focused recheck of those fixes and rerun only the affected validations. Do not repeat the whole suite or a full new review unless the operator asks.
- An open `critical` finding stays blocking until the recheck verifies the correction.
- The security pass (Order, step 4) is conditional on `needs_security`. It is not the O3 mandatory closeout security pass.

## Recording and reporting
- Record in the plan's Closeout: what ran, results per stack or check (`PASS`, `FAIL` or `SKIPPED`), unavailable validations, partial reviews, and remaining limitations.
- `SKIPPED` is never `PASS`.
- If validation fails and the review is partial in the same run, report both: the failed validation first, then the partial review with the angles that did not run. Neither is success and the delivery is not complete.
- For review angles that did not run, state the cause and offer to rerun only those angles; rerun them only if the operator asks.
- Report the same to the operator in the final message. Never present failed, unavailable or partial validation or review as success.
- Terminal outcome rules: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`.
- Do not commit, push, merge or open a pull request unless the operator asks for it specifically. Handoff rules: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`.
- Do not use cold reviewers (`cold-critic`, `cold-reader`). Do not import the O3 mandatory closeout security pass.
