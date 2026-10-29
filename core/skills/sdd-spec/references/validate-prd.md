## Structural validate (`validate-prd`)

Before `/sdd-plan` handoff, run:

```
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-prd.ps1" -Path <prd-path>
```

Exit 0 required (REQ-NNN + CA headings + required sections). For a PRD that describes an API route, include the observable API contract subsection with the accepted heading `### 7.3 Contrato observável de API` (or `### 7.3 Observable API contract` for English content). If validation fails, inspect the validator's actionable failure message and the matching condition in `scripts/validation/validate-prd.ps1`, then correct the PRD and re-run; do not repeat speculative edits or ask the operator to locate evidence before checking cited local sources. Fixtures/smoke: `scripts/validation/Assert-ValidatePrdPlan.ps1`. Deterministic scripts only (RNF-001) — never use an LLM as the structural validator.
