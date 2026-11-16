# Closeout: final validation, review and quality checks

## When
- Run after all approved steps are COMPLETED and the criterion tests are recorded (`references/execution.md`, "Criterion tests").
- Final validation and review stay `pending` in the plan until performed. Completed steps alone do not mean delivery is complete.

## Order
0. **Criterion map.** Progress holds one `criterion -> test` line for every criterion `A1..An`. A missing line means the criterion is open: stop, record `BLOCKED` with the next action.
1. **Final validation.** Run the final validations listed in the plan's Validation. For the workspace test command, follow `{{TOOLKIT_ROOT}}/skills/run-tests/SKILL.md`. Delegate bounded commands to `shell-runner` when subagents are available (`{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`); otherwise run them in-parent.
2. **Code review.** Invoke `{{TOOLKIT_ROOT}}/skills/code-review/SKILL.md` explicitly, as the closeout. Pass:
   - mode: `single` or `multi-angle`, as recorded in the plan's Choices;
   - the full resolved `PLAN.md` path, global storage included;
   - the focus, as recorded or asked once;
   - the base branch;
   - scope `working_tree` (all uncommitted delivery changes, staged and unstaged).
   - Do not pass a report path. `code-review` returns its report in chat.
   - `code-review` runs `/run-tests` itself as part of its verification; that is expected, as in the other flows.
   - Fix the actionable findings (see "Findings") before step 3.
3. **Rerun.** After review-driven changes, run the affected validation again with `run-tests`. Or record in the plan that no change required a rerun. Any later code change returns to this step, and steps 4 and 5 run again on the changed tree.
4. **Security pass (conditional).** Only if the plan's triage marks security as needed (`needs_security`): have the `security` specialist review the final working-tree diff, after the review and the rerun. Use `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/security.md` and the spawn rules of `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md`. Findings come back in chat; no artifact is written. Treat them like review findings.
5. **Quality checks (once, on the final tree).** Observation only: no fixes, no formatter, package update or cleanup commands, no commit. Apply each item below and record one line per item.
   - **Secrets** (`{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md`, 3.5.1): blocking. A secret found is a blocker: stop and report the file and line.
   - **Lint and format** (3.5.2): blocking when configured. Configured diagnostics run only under the trust rule of 3.5.2.
   - **Build** (3.5.3): blocking. Covers the build item of `step-7-checklist.md` 7.3.
   - **Dependency audit** (3.5.5): warning only, and only when packages changed.
   - **Branch** (`step-7-checklist.md` 7.2): on a `feature/` or `feat/` branch, not on an integration branch; changes belong to the feature scope.
   - **Plan traceability** (7.4): every step deliverable and acceptance criterion is addressed; Progress and Closeout are updated.
   - **Quality** (7.3 and 7.5): behavior changes have tests; naming, method size and types follow the stack guidelines; no security issue (secrets, injection, sensitive logs) and no egregious performance issue (N+1, unbounded loops) in touched code.
   - **Tests** (7.3): cite the latest `run-tests` result (step 1, or step 3 after a rerun). Do not run the suite again only to record this item. Section 3.5.4 is covered by step 1.
   - Each item is `PASS`, `FOUND`, `SKIPPED` or `open`. `FOUND` names the rule, severity, `file:line` and whether it is `new` or `pre-existing` against the start baseline. `SKIPPED` names the reason and the availability evidence; it is never `PASS`. `open` names the next action.
6. **AI-trace scan (last).** After any fix and after `CODE-REVIEW.md` is saved, scan the working-tree changes (`git diff` plus the untracked files from `git status`), `PLAN.md` and `CODE-REVIEW.md` for AI references in comments, identifiers, log messages and text, per `{{TOOLKIT_ROOT}}/rules/ai-stealth.mdc`. Rewrite each hit. A hit outside the plan's paths is an operator question. A comment or text-only fix stays at this step. A fix that changes code returns to step 3, and steps 4 to 6 run again on the changed tree. Record `AI traces: none` or `AI traces: fixed` in Closeout.

## Review report
- `code-review` does not write a file. This skill saves the consolidated report (findings, decision, evidence, limitations) as `CODE-REVIEW.md`.
- Place `CODE-REVIEW.md` next to the actual resolved plan: the feature root, or the folder of an independent plan (`plans/<unit-or-repo-slug>/`). Global storage included. Layout rules: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md`.
- Update the file after fixes, then recheck.
- Preexisting changes recorded in the start baseline are mentioned in the report as context.
- If preexisting changes cannot be told apart from delivery changes, say so. Ask the operator for a path list to pass to `code-review`. Do not guess the scope.

## Findings
- Fix actionable findings (from the review, the security pass or a `FOUND` quality item) that fall inside the approved plan scope. The fix then returns to step 3.
- Before touching any unplanned file or step, consult the operator. Amendment rule: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`. Review suggestions are not authorized scope.
- After fixes, do a focused recheck of those fixes and rerun only the affected validations (step 3). Do not repeat the whole suite or a full new review unless the operator asks.
- An open `critical` finding stays blocking until the recheck verifies the correction.

## Recording and reporting
- Record in the plan's Closeout: what ran, results per check of steps 1 to 5 (`PASS`, `FAIL`, `FOUND`, `SKIPPED` or `open`), the criterion map status, `AI traces: none | fixed`, unavailable validations, partial reviews, and remaining limitations.
- `SKIPPED` is never `PASS`.
- If validation fails and the review is partial in the same run, report both: the failed validation first, then the partial review with the angles that did not run. Neither is success and the delivery is not complete.
- For review angles that did not run, state the cause and offer to rerun only those angles; rerun them only if the operator asks.
- Report the same to the operator in the final message. Never present failed, unavailable or partial validation or review as success.
- Terminal outcome rules: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`.
- Do not commit, push, merge or open a pull request unless the operator asks for it specifically. Handoff rules: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`.
- Do not use cold reviewers (`cold-critic`, `cold-reader`). Do not import the O3 mandatory closeout security pass.
