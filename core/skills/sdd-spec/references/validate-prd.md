## Structural validate (`validate-prd`)

Before `/sdd-plan` handoff, run:

```
.\scripts\validation\validate-prd.ps1 -Path <prd-path>
```

Exit 0 required (REQ-NNN + CA headings + required sections). Exit ≠ 0 → fix and re-run. Fixtures/smoke: `scripts/validation/Assert-ValidatePrdPlan.ps1`, `Assert-PrdStructure.ps1`. Deterministic scripts only (RNF-001) — never use an LLM as the structural validator.
