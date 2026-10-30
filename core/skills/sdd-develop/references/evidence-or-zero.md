## Evidence-or-zero

Canonical paths: `features/NNN-slug/{USnn|TSnn}/EVD/`, `features/NNN-slug/{USnn|TSnn}/STATE.md`.

| Level | Gate |
|-------|------|
| `off` | No evidence required |
| `cheap` | STATE + EVD + ≥1 non-empty cited evidence file |
| `standard` | Every matrix row has non-empty EVD file |
| `strict` | `standard` + every Result = `pass` |

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-evidence.ps1" -StoryRoot features/NNN-slug/USnn [-Level cheap]
# Or derive the story root only from an explicit plan/story path:
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-evidence.ps1" -PlanPath features/NNN-slug/TSnn/PLAN/PLAN_*.md [-Level cheap]
```

Templates: `skills/_shared/templates/features/STATE.md`, `…/EVD/README.md`. Contract: `EVD-STATE-CONTRACT.md`. Run `validate-evidence.ps1` when the step declares evidence validation.

For final US test consolidation, reconcile the STATE matrix against every
applicable acceptance criterion and its tests/results. Append new evidence or
update the relevant matrix row; do not remove a valid prior EVD artifact merely
because a newer run exists. Supersession is valid only when a newer equivalent
or stronger result covers the same criterion against the current implementation.
Record the old and replacement evidence paths and the reason in the evidence
record, retain the old file, and point the current matrix row to the replacement.
Run `validate-evidence.ps1` without overriding the level so the STATE setting or
repository default governs; use an explicit level only when the PLAN/operator
configures one.

**Verifier ≠ O3:** never use orchestrate-develop Task parallelism as the mechanism that “proves” ACs — evidence is script + matrix only.

---
