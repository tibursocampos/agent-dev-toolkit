# 05 — Review and quality

These skills run **after** code exists, or on a branch the operator names. When a story or feature is done, `orchestrate-develop` runs `/run-tests`, then `/code-review`, then `/run-tests` again after review changes (or records that no rerun is required), then the `security` agent, then asks `/commit` and `/push`. The review skill must not turn multi-angle into a mandatory gate.

## `code-review`

Trigger: `/code-review`, “review this PR”.

### Mode is a required choice

If the invoke does not say single or multi-angle, the skill stops and asks:

1. **single** — one reviewer (also `single-angle`, `simples`)
2. **multi-angle** — quality, acceptance, and security (also `multi-ângulo`). A subset is allowed: `ângulos: qualidade, segurança`

There is no default.

### What it reads

| Input | Rule |
|-------|------|
| Base branch | `main` or `develop`; ask once if missing |
| Head | Current branch, or a named branch |
| PRD / PLAN | Optional on the invoke. Step 0.5 searches before the diff |

Search is **only** under `features/**/PRD/` and `features/**/PLAN/PLAN_*.md` (workspace and global SDD root). Root `PRD/` folders do not count. Pair by the three-digit `NNN`. One pair is read before traceability. None: the report says **SDD limitation** (technical review only) and does not claim the files “do not exist”. Several pairs: ask once.

### Diff and checks

`git diff <base>...<head>`, stat, and log. Large sets are confirmed before a deep pass.

When artifacts exist: PLAN progress matches the code; completed steps have deliverables checked; pending steps are not already merged; PRD acceptance maps to code and tests. Drift is **important**, not automatically blocking.

Standards order: project `docs/standards/` or `AGENTS.md`, then the matching guideline pack (for .NET: layers and tests with xUnit, Moq, Shouldly). When the diff matches, load one of: policy regressions, N+1 / hot paths, or SDD/CHANGE/API contracts. Do not paste those files into the report.

### Multi-angle

After the operator chooses multi-angle: one child per requested angle when `subagents=native` (at most three, in parallel). Otherwise the same angles run in the parent, in order. The parent still owns build, test, and coverage. Overlapping findings keep the stronger severity and the clearest `path:line`.

| Angle | Looks for |
|-------|-----------|
| Quality | Correctness, boundaries, tests, N+1, policy regressions, maintainability |
| Acceptance | PRD criteria, PLAN drift, CHANGE and portable paths, in-scope business rules |
| Security | Auth assumptions, injection, secrets and PII in logs, dangerous defaults |

### Decision

| Decision | When |
|----------|------|
| **Approved** | Scope met, no critical issues, build and tests pass or gaps are accepted, and coverage is at or above threshold when a target applies |
| **Approved with reservations** | Minor or cosmetic drift, no security or correctness blocker, coverage at or above threshold with some files under the 100% note |
| **Changes required** | Security issue, broken behavior, missing PRD scope, build or test failure, critical architecture break, or coverage **below** threshold when a target applies |

Default coverage target is **80%** line coverage on changed production files, via `/test-coverage`. No target means coverage is not a blocker. Fail without a documented exception is **Changes required**.

The report is for the operator, with `path:line`, why, and how to fix. Spoken report prose follows `core/skills/_shared/agents/LANGUAGE.md`. Keep the positives section. Each positive names one observed good point, uses a title in that language, and cites `path:line` evidence in the diff. When no such evidence exists, the section states that no positive was observed. This skill does not edit code and does not write PRD or PLAN.

The security checklist runs only when the mode is multi-angle and the security angle was requested. A single review does not run it. That checklist does not replace the closeout pass in `core/skills/_shared/agents/prompts/security.md`, which still runs after the post-review `/run-tests`, including when the review was single. One pass does not waive the other.

### After the report

Ask, and wait for **sim** or **pular**, whether to fix with `/developer`, `/sdd-develop`, or a stack `*-developer`, and whether to re-run `/code-review`. Do not ask, suggest, or hand off memory bank, `/memory-bank-init`, `/document-implement`, or `/document-plan`. There is no memory-bank gate and no documentation gate in this skill.

A pull-request URL is used only when the operator passed it. Do not tell the operator to open a pull request, call `/open-github-pr`, or open the GitHub UI.

Then `/commit` when the operator asks. New scope found in the review goes to `/sdd-spec`, not into this skill’s editor.

## `test-coverage`

.NET Coverlet plus ReportGenerator. Default threshold **80** on changed production `.cs` files. **100** is an aspirational note, not the pass line.

Needs Agent mode for `dotnet test`. A toolkit-only workspace with no test project stops and asks which repo to open. Missing `coverlet.collector` stops with install instructions. The run is not finished until `TestResults/CoverageReport/Summary.txt` and `index.html` exist.

This skill does not block merge by itself. `code-review` applies the threshold. Pass hands back to `/code-review` with the summary. Fail hands to `/dotnet-developer` or `/sdd-develop`. Broken build or tests hand to `/repair-dotnet-build`.

Excluded from the new-code denominator: migrations, `*.g.cs`, `*.Designer.cs`, test projects.

## `run-tests`

Trigger: `/run-tests`, or the close of a story in `orchestrate-develop`, once before `code-review` and once after review changes (or record no rerun required), both before the security pass.

It detects the stack in the same order as `developer` and runs that stack’s existing test command. Several stacks mean one run each. The report is one row per stack: command, exit code, `PASS` or `FAIL`. A check the repo does not have is `SKIPPED`. Overall `PASS` only when every stack passed.

It does not edit code and does not mark a PLAN step `COMPLETED`. .NET coverage is `test-coverage`, and only when the PLAN asks for it. No detected stack stops and asks. Plan or Ask mode does not run the shell.

## `repair-dotnet-build`

Trigger: `/repair-dotnet-build`, local `dotnet build` / `dotnet test`, or a **pasted** CI log. It does not fetch a remote build by API.

Diagnosis groups compile, restore, test assertion, configuration, and pipeline YAML when the log was pasted. One error at a time, the smallest change, and only .NET. Each proposed edit waits for confirmation. After the fix, build and targeted tests run again until the status is explicit. Offer `/commit`. New EF migration goes to `/ef-add-migration`. Large scope goes to `/sdd-spec`.

## `refactor`

Trigger: `/refactor`, or a review that shows high complexity. Optional file and method.

It reduces complexity and keeps existing tests green. It does not add features or bugfixes in the same session. One step, then stop. No auto-commit. Stack guidance loads for the detected language only (C#, Python, JS/TS, React, Angular).

## `performance-profile`

Trigger: `/performance-profile`. Optional method, function, or LINQ/SQL block.

Audit first, then **wait for a workflow choice** before changing code. Improvements are micro-benchmarked (time and allocations before versus after). Do not drop a domain rule for speed. One step, then stop.
