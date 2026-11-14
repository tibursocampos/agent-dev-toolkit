# ADT delivery - specialist triage

Applies to `adt-delivery-refine` and `adt-delivery-plan`, including when either runs directly.

## Procedure

1. Set the `needs_*` flags (`needs_api`, `needs_domain`, `needs_database`, `needs_frontend`, `needs_security`, `needs_devops`) and the nature (`greenfield` | `brownfield` | `operational`) using the canonical table in `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md`, section "Flags (`needs_*`)". Do not fork a second mapping.
2. TE01 applies unchanged (ROSTER, section "TE01 / security signals"). If authentication, secrets, PII, feed tokens or supply-chain signals appear in the demand, never default `needs_security` to `false`. Ask the operator explicitly or set it to `true`.
3. Ambiguous flag: ask the operator at most a few high-cost questions in the user's chat language. Otherwise prefer `false` until evidence or operator confirmation.
4. For each flag that is `true`, and for brownfield or greenfield nature, involve the specialists ROSTER names for it (`architect`, `security`, `database`, `repo-analyst`). Follow `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` for spawn, caps and the in-parent fallback. When spawn is unavailable, run the same analysis in-parent and say so.
5. In this flow specialists RETURN findings in their receipt. They do NOT write `ANALYSIS/`, `ARCH/` or `SEC/` folders or any new artifact. This overrides the folder-on-disk rule in ROSTER for this flow. The parent records a summary of the findings under Evidence in the plan. Specialist findings are suggestions, not authorized scope.
6. An `architect` design result is a suggestion until the operator approves the plan. Because no `ARCH/` artifact is written in this flow, the single plan approval replaces the ROSTER architecture confirm gate; present the design choice inside the plan so it is visible when approving.
7. `needs_frontend` and `needs_devops` have no specialist agent (ROSTER). Note them in the plan only.

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

## Direct invocation

- The same procedure and the same audit table apply when `adt-delivery-refine` or `adt-delivery-plan` runs alone.
- If the table already exists in the plan, reuse it and update only rows whose evidence changed.
