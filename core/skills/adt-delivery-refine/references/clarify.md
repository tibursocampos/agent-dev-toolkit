# Refinement rules

## What to clarify

- Observable outcome.
- Context and current behavior.
- Scope and exclusions.
- Acceptance criteria.
- Dependencies.
- Risks.
- Material questions.
- Evidence.
- Where applicable, consider impacts on contracts, data migration, integrations and error handling.

## Evidence discipline

- Keep these apart: the user request, verified facts with their sources, inferences, and suggestions.
- Inspect the relevant source instead of treating assumptions as facts.
- Do not invent requirements and do not expand scope.

## Acceptance criteria

- Make each criterion observable and measurable.
- Cover happy paths, failures and edge cases when relevant.
- Give each criterion an id: A1, A2, ...

## Questions

- Ask only material unresolved questions; group them where useful.
- Reuse information the user already gave.
- Ask for missing material decisions.
- Refine proportionally to the demand.

## Specialists

- Triage and the audit table follow `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md`.
- Use proportional analysis.
- Delegate independent analysis in parallel when available.
- Otherwise do targeted local analysis and state the limitation.
- No cold reviewers and no fixed token budget.

## Recording

- Update the same `PLAN.md` at feature root, shaped by `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-TEMPLATE.md`.
- Preserve prior decisions and progress.
- Record decisions and their sources; mark unresolved items explicitly.
- Use US sections only if they improve clarity; create no extra story artifacts by default.
- Exceptional split, only if the operator agreed: select the exact independent `plans/<unit-or-repo-slug>/PLAN.md` inside the resolved feature directory, and reference shared decisions instead of duplicating them.
- Validate confinement, including global storage; reject traversal and escapes.
- Refinement is not implementation approval.
- Direct invocation: stop after refinement and provide the `adt-delivery-plan` handoff.
- Invoked by `adt-delivery-flow`: return control to the coordinator (see `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`).
