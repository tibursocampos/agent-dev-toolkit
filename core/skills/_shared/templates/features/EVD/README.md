# EVD: evidence folder

Canonical path: `features/NNN-slug/EVD/`

Store **short** evidence notes for AC rows in sibling `STATE.md` (REQ-005 / CA4).

## Naming

Prefer `caN-<short-slug>.md` (e.g. `ca4-validate-evidence.md`).

## Content (minimal)

```markdown
# Evidence: CA4

| Field | Value |
|-------|--------|
| **AC** | CA4 |
| **Command / check** | `.\scripts\validation\Assert-EvidenceContract.ps1` |
| **Result** | pass |
| **When** | YYYY-MM-DD |

## Notes

- Exit 0; summary line …
```

## Rules

- Cite portable paths only
- No full PRD or full `memory-bank/` dump (`SR-NO-FULL-DUMP`)
- Level ≥ `cheap` requires at least one non-empty file here
- Contract: `EVD-STATE-CONTRACT.md`
