# ADT delivery - specialist triage

Applies to `adt-delivery-refine` and `adt-delivery-plan`, including when either runs directly.

## Procedure

1. Set the `needs_*` flags (`needs_api`, `needs_domain`, `needs_database`, `needs_frontend`, `needs_security`, `needs_devops`) and the nature (`greenfield` | `brownfield` | `operational`) using the canonical table in `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md`, section "Flags (`needs_*`)". Do not fork a second mapping.
2. TE01 applies unchanged (ROSTER, section "TE01 / security signals"). If authentication, secrets, PII, feed tokens or supply-chain signals appear in the demand, never default `needs_security` to `false`. Ask the operator explicitly or set it to `true`. Demand text about logging of authorization data, tokens, request or response bodies, or PII counts is one of these signals as well.
3. Ambiguous flag: ask the operator at most a few high-cost questions in the user's chat language. Otherwise prefer `false` until evidence or operator confirmation.
4. For each flag that is `true`, and for brownfield or greenfield nature, take the specialists ROSTER names for it (section "Flags (`needs_*`)"). Do not keep a second mapping here. Then apply these Result rules:
   - When the effective `subagents` capability is `native`, every row that ROSTER maps to a specialist must end as `specialist spawned: <role>` or `declined by operator`.
   - Spawn the specialists of the plan in parallel, in the same turn, following `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` for spawn, caps and handoff.
   - `in-parent fallback: <role>` is allowed only when the capability is `none` or unavailable, or when the host refused the spawn. Basis then records that reason, and the analysis is run in-parent and said so.
   - `declined by operator` is allowed only when the operator refused that specialist in chat.
   - Write a Result only after the spawn has returned its receipt, or after the operator answered. Never pre-fill a Result before that.
   - Rows whose flag is `false`, and rows whose flag is `true` but ROSTER names no specialist (`needs_frontend`, `needs_devops`), are `not applicable`.
5. In this flow specialists RETURN findings in their receipt. They do NOT write `ANALYSIS/`, `ARCH/` or `SEC/` folders or any new artifact. This overrides the folder-on-disk rule in ROSTER for this flow. The parent records a summary of the findings under Evidence in the plan. Specialist findings are suggestions, not authorized scope.
6. An `architect` design result is a suggestion until the operator approves the plan. Because no `ARCH/` artifact is written in this flow, the single plan approval replaces the ROSTER architecture confirm gate; present the design choice inside the plan so it is visible when approving.
7. `needs_frontend` and `needs_devops` have no specialist agent (ROSTER). Note them in the plan only.

## Evidence rules

- Every specialist finding carries `file:line` for the code or document it rests on. A finding without a location is not recorded as evidence.
- Label each finding as `fact` (read in a source), `inference` (derived from facts, with the reasoning shown) or `suggestion` (a proposed change or design choice).
- A suggestion that implies a defect or a behavior change stays a suggestion until the operator explicitly decides on it. Until then it is never written into the plan as a defect, scope item or acceptance criterion.
- Sources not read (libraries, production configuration, other files) are listed as evidence gaps in the plan. They are not presented as checked.

## Audit record (mandatory)

Put this table in the plan's Normative content (Decisions section). Record the nature on the line above the table.

Nature: `<greenfield | brownfield | operational>`

| Flag | Value | Basis | Result |
|------|-------|-------|--------|
| `needs_api` | `true` or `false` | one short phrase of evidence | one result from the list below |
| `needs_domain` | `true` or `false` | one short phrase of evidence | one result from the list below |
| `needs_database` | `true` or `false` | one short phrase of evidence | one result from the list below |
| `needs_frontend` | `true` or `false` | one short phrase of evidence | one result from the list below |
| `needs_security` | `true` or `false` | one short phrase of evidence | one result from the list below |
| `needs_devops` | `true` or `false` | one short phrase of evidence | one result from the list below |

- Result is exactly one of: `specialist spawned: <role>`, `in-parent fallback: <role>`, `not applicable`, `declined by operator`.
- Six flag rows are always present, even when all flags are `false`.
- A nature-driven role (brownfield or greenfield) gets its own row, with Flag set to `nature: <value>`.
- Basis is one short phrase of evidence (for example "touches login flow").
- A row cannot be omitted. Skipping a specialist silently is not allowed.
- For a row with `specialist spawned: <role>`, Basis also names where the receipt summary is recorded in the plan, for example `see Evidence, repo-analyst receipt`. The Evidence section must hold that summary.

## Direct invocation

- The same procedure and the same audit table apply when `adt-delivery-refine` or `adt-delivery-plan` runs alone.
- If the table already exists in the plan, reuse it and update only rows whose evidence changed.
