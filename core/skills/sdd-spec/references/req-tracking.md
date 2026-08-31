## REQ-NNN tracking (required / strongly recommended)

| Rule | Detail |
|------|--------|
| Format | Stable `REQ-NNN` (three digits, e.g. `REQ-001`) in §4 table and inline where cited |
| Coverage | Every functional behavior → ≥1 REQ → ≥1 verifiable CA |
| External IDs | Issue/US/TS ids may appear in header **Rastreamento**; still assign REQ-NNN in §4 for PLAN handoff |
| PLAN/develop | REQ-NNN is the cross-artifact tracking key — do not rename after `/sdd-plan` |

`validate-prd` exit 0 requires at least one REQ-NNN plus required structural sections (Execution policy, acceptance, requirements, OOS).
