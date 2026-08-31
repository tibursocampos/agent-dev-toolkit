## Structural validate (`validate-plan`)

Before `/sdd-develop` handoff, run:

```
.\scripts\validation\validate-prd.ps1 -Path <prd-path>
.\scripts\validation\validate-plan.ps1 -Path <plan-path> -PrdPath <prd-path>
```

Exit 0 required: PLAN has Execution policy, REQ→step map, PASSO/STEP headings, and covers every PRD `REQ-NNN`. Exit ≠ 0 → fix and re-run. Fixtures/smoke: `scripts/validation/Assert-ValidatePrdPlan.ps1`, `Assert-PlanStructure.ps1`. Deterministic scripts only (RNF-001) — never use an LLM as the structural validator.
