## REQ-NNN tracking (required / strongly recommended)

| Rule | Detail |
|------|--------|
| Format | Stable `REQ-NNN` (three digits, e.g. `REQ-001`) in §4 table and inline where cited |
| Coverage | Every functional behavior → ≥1 REQ → ≥1 verifiable CA |
| Decision projection | When a material decision feeds a REQ/CA, compare the actual normative wording with the current decision; an ID, link, or envelope alone does not prove semantic agreement. Apply `skills/_shared/sdd-artifacts/SEMANTIC-SUFFICIENCY.md` and retain the existing decision owner. |
| Supersession | Keep superseded decisions as history; do not carry their old behavior as an active REQ or CA. |
| Applicable gaps | Include material rules, failures, compatibility/preservation, OOS, and evidence limits only when relevant. A generic CA or missing material behavior/failure remains a question, not inferred `agreed` text. |
| External IDs | Issue/US/TS ids may appear in header **Rastreamento**; still assign REQ-NNN in §4 for PLAN handoff |
| PLAN/develop | REQ-NNN is the cross-artifact tracking key — do not rename after `/sdd-plan` |

`validate-prd` exit 0 requires at least one REQ-NNN plus required structural sections (Execution policy, acceptance, requirements, OOS).

- **SDDW-10 (criterion text change):** Changing the text of a CA, REQ, or CT requires one dated row in the PRD `## Histórico de alterações` (or `Change history`) that names the changed id and records the operator approval (`operador` or `operator`). Without that row the approved text stays as it is. Reconciliation: list each changed id against the history rows before reporting the PRD changed.
