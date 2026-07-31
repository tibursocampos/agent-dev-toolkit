# Template: high-level task list

Use at the start of a dev session (step 0). Keep ≤ 10 items; one `in_progress` at a time.

---

## Default list (Git-only)

| # | Task | Initial status |
|---|------|----------------|
| 1 | Read `AGENTS.md` / `README.md` | `in_progress` |
| 2 | Review guidelines (step 0.5) | `pending` |
| 3 | Create/checkout `feature/<slug>` or `feat/<id>` | `pending` |
| 4 | Implement change + tests | `pending` |
| 5 | Pre-commit validation (step 3.5) | `pending` |
| 6 | Commit (+ push if requested) | `pending` |
| 7 | Pre-PR checklist (step 7) | `pending` |

For SDD, the PLAN file is the detailed control artifact - this list tracks Git workflow only.

---

## By stack (suffix step 4-6)

| Stack | Verify commands |
|-------|-----------------|
| .NET | `dotnet build`, `dotnet test` |
| Node | `npm run build`, `npm test`, lint if configured |
| Python | `pytest`, type/lint tools if configured |

---

## Status values

| Status | Meaning |
|--------|---------|
| `pending` | Not started |
| `in_progress` | Active |
| `completed` | Done |

Update when starting and finishing each step.

---

## Practices

**Do:** create list at session start; update in real time; descriptive item titles.

**Don't:** duplicate every PLAN baby step here; exceed 10 items; leave multiple items in progress.
