# ADT delivery - specialist triage

Applies to `adt-delivery-refine` and `adt-delivery-plan`, including when either runs directly.

## Procedure

1. Set the `needs_*` flags (`needs_api`, `needs_domain`, `needs_database`, `needs_frontend`, `needs_security`, `needs_devops`) and the nature (`greenfield` | `brownfield` | `operational`) using the canonical table in `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md`, section "Flags (`needs_*`)". Do not fork a second mapping.
2. Apply the security triage in ROSTER. For authentication, secrets, sensitive data or supply-chain signals, identify the affected trust boundary and the material question. Existing safeguards can be evidence; new controls remain proposals until decided.
3. Scope each investigation using the applicable surface in `../sdd-artifacts/AUTHORING-CONTENT.md`. Use the repository first and ask the operator only for a material choice or missing confirmation.
4. Choose the specialist named in ROSTER when expertise can answer a concrete question. A flag or project classification alone does not require delegation. Independent investigations can run in parallel under `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`. Use focused parent analysis for the documented fallback and record any evidence limit.
5. Specialists RETURN source, observation or inference, evidence limits and effect on the affected work. They do not write artifacts in this flow. The parent reconciles their findings and recommendations into Evidence and Decisions before handoff. Recommendations do not authorize scope.
6. An `architect` design result is a suggestion until the operator approves the plan. Present the design choice inside the plan so it is visible at approval.
7. `needs_frontend` and `needs_devops` have no specialist agent (ROSTER). Note them in the plan only.

## Evidence rules

- Every specialist finding carries `file:line` for the code or document it rests on. A finding without a location is not recorded as evidence.
- Label each finding as `fact` (read in a source), `inference` (derived from facts, with the reasoning shown) or `suggestion` (a proposed change or design choice).
- A suggestion that implies a defect or a behavior change stays a suggestion until the operator explicitly decides on it. Until then it is not written into the plan as a defect, scope item or acceptance criterion.
- Sources not read (libraries, production configuration, other files) are listed as evidence gaps in the plan, not presented as checked.

## Decisions record

Put a short bullet list in the plan's Normative content, under Decisions:

- `Nature: <greenfield | brownfield | operational>`
- `Flags: api=<true|false> domain=<...> database=<...> frontend=<...> security=<...> devops=<...>`
- `Specialists used: <role>, <role>` and `Specialists declined: <role> (operator)` when they apply. Write this only after the receipts return or the operator answers.

Specialist receipt summaries go under Evidence, not in this list.

## Direct invocation

- The same procedure applies when `adt-delivery-refine` or `adt-delivery-plan` runs alone.
- If the Decisions list already exists in the plan, reuse it and update only the entries whose evidence changed.
