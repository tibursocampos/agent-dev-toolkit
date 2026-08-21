# STATE: {{NNN}}-{{slug}}

| Field | Value |
|-------|--------|
| **Feature** | `features/{{NNN}}-{{slug}}/` |
| **Evidence level** | cheap |
| **PLAN** | `./USnn/PLAN/PLAN_NNN_*.md` (portable path) |
| **Updated** | YYYY-MM-DD |

## Purpose

Post-implementation **evidence-or-zero** ledger (REQ-005 / CA4). Maps acceptance criteria to files under `EVD/`. Levels: `off` \| `cheap` \| `standard` \| `strict` — see `EVD-STATE-CONTRACT.md`.

## AC → evidence matrix

| AC | REQ | Evidence | Result | Notes |
|----|-----|----------|--------|-------|
| CA1 | REQ-001 | `EVD/ca1-smoke.md` | pending | Replace with real evidence path |

## Gate

- Level `off`: matrix optional
- Level ≥ `cheap`: at least one non-empty evidence file under `EVD/` cited above
- Level `standard`: every row has a non-empty `EVD/` file
- Level `strict`: every **Result** is `pass`

```text
.\scripts\validation\validate-evidence.ps1 -FeatureRoot features/{{NNN}}-{{slug}}
```

## Verifier note

Evidence verification runs **sequentially** in `sdd-develop` (script gate). Do **not** use O3 Task parallelism as the verifier.
