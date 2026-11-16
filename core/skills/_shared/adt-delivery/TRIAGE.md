# ADT delivery - specialist triage

Applies to `adt-delivery-refine` and `adt-delivery-plan`, including when either runs directly.

## Procedure

1. Set the `needs_*` flags (`needs_api`, `needs_domain`, `needs_database`, `needs_frontend`, `needs_security`, `needs_devops`) and the nature (`greenfield` | `brownfield` | `operational`) using the canonical table in `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md`, section "Flags (`needs_*`)". Do not fork a second mapping.
2. TE01 applies unchanged (ROSTER, section "TE01 / security signals"). If authentication, secrets, PII, feed tokens or supply-chain signals appear in the demand, never default `needs_security` to `false`. Ask the operator or set it to `true`. Demand text about logging of authorization data, tokens, request or response bodies, or PII counts as one of these signals.
3. Ambiguous flag: ask the operator a few high-cost questions at most, in the user's chat language. Otherwise prefer `false` until evidence or operator confirmation.
4. For each `true` flag and for brownfield or greenfield nature, use the specialists ROSTER names. Spawn them in parallel in the same turn, following `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`. Use in-parent analysis only when subagents are unavailable or the host refused the spawn, and say so. Skip a specialist only when the operator declines it in chat.
5. Specialists RETURN findings in their receipt. They do NOT write `ANALYSIS/`, `ARCH/` or `SEC/` folders or any new artifact. The parent records a summary of the findings under Evidence in the plan. Specialist findings are suggestions, not authorized scope.
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
