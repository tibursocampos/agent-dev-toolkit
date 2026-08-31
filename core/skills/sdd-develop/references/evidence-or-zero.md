## Evidence-or-zero (REQ-005 / CA4)

Canonical paths: `features/NNN-slug/EVD/`, `features/NNN-slug/STATE.md`.

| Level | Gate |
|-------|------|
| `off` | No evidence required |
| `cheap` | STATE + EVD + ≥1 non-empty cited evidence file |
| `standard` | Every matrix row has non-empty EVD file |
| `strict` | `standard` + every Result = `pass` |

```powershell
.\scripts\validation\validate-evidence.ps1 -FeatureRoot features/NNN-slug [-Level cheap]
```

Templates: `skills/_shared/templates/features/STATE.md`, `…/EVD/README.md`. Contract: `EVD-STATE-CONTRACT.md`. Smoke: `Assert-EvidenceContract.ps1`.

**Verifier ≠ O3:** never use orchestrate-develop Task parallelism as the mechanism that “proves” ACs — evidence is script + matrix only.

---
