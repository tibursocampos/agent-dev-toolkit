# Planning rules

## What the plan must contain (reviewable as a whole)
- Goal; scope and exclusions; acceptance criteria.
- Decisions and outstanding questions; affected files or bounded path patterns.
- Dependencies; ordered steps and any safe parallelism; intended validations; risks; progress and evidence.
- Shape: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-TEMPLATE.md`. Optional US groupings share the same plan, including when there are two US.
- Keep normative content (requirements, scope, decisions, paths, steps, intended validations) apart from operational status (approval record, choices, progress, evidence, actual results).
- Record unverified assumptions.

## Steps
- Ordered; each step references acceptance and decision ids; dependencies explicit.
- Parallelism only for independent steps with clear file ownership.
- Do not mandate a test after every step.

## Validation and closeout in the plan
- Specify a final validation appropriate to the change.
- Closeout order (same as other toolkit flows): `run-tests`, then `code-review`, then `run-tests` again if review changed files.
- The review report is written to `CODE-REVIEW.md` next to the actual plan.
- Mark final validation and review outcomes `pending` until performed; never claim delivery complete early.

## Inputs, storage and specialists
- Read repository instructions, `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` and the selected plan.
- Storage root, feature selection, plan path validation, missing plan and split rules: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md`. Do not restate them here.
- Retain refinement and decisions in the same plan; no separate story plans or US sections are required.
- Inspect the relevant source. Specialist triage and the audit table: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md`. Independent work may run in parallel when available; otherwise targeted local analysis, with limitations stated. Never load unrelated repository context or specialist guidance by default.
- After an agreed split, each independent plan names its own approval record, its own progress and its own `CODE-REVIEW.md` path (`plans/<unit-or-repo-slug>/CODE-REVIEW.md`), and references the shared decisions of the feature-root plan without copying them.

## Self-check and approval
- Before approval, check scope and acceptance coverage, evidence and assumptions, contradictions, and executable steps and validations (see `PLAN-TEMPLATE.md`).
- This is a targeted self-check, not a separate reviewer, cold review or review loop.
- Resolve every material open question with the operator before requesting approval; an exposed unresolved question is not approval-ready.
- Present the complete plan and request ONE explicit approval for its full scope.
- Record approval, date and scope sentence as defined in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md` (material changes, amendment and renewed approval live there).
- Approval is never inferred from silence or from a review.
- After approval, `adt-delivery-implement` asks for the branch at each start and for cadence and review mode once.
- Planning never implements, commits or publishes.
