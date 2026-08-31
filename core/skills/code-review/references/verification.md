## Code analysis focus

| Area | Focus |
|------|--------|
| Correctness | Logic, edge cases, error handling |
| Architecture | Layer boundaries, DI, no domain -> infrastructure leaks |
| Tests | Behavior covered; meaningful assertions; no trivial tests |
| Security | Secrets, injection, authz, sensitive logs |
| Performance | N+1, unbounded work, missing async where I/O |
| Maintainability | Naming, method size, duplication; magic values - see `csharp-patterns.md` |

## Verification commands

| Stack | Commands |
|-------|----------|
| .NET | `dotnet build`, `dotnet test` (scoped if large) |
| .NET coverage | `/test-coverage` when PRD, PLAN, or user sets a target (default **80%** on changed production files) |
| Node | `npm run build`, `npm test` per project scripts |

When a coverage target applies: run `test-coverage` before final decision; paste summary into report section Testes. **Fail** below threshold -> **Changes required** unless user documents an accepted exception.

---

## Approval criteria

**Approved:** PRD/PLAN satisfied; no critical issues; build/tests pass or user accepts documented gaps; when a coverage target applies (PRD, PLAN, user, or `test-coverage` run), **new code** line coverage on changed production files is **≥ threshold** (default **80%**).

**Approved with reservations:** Minor issues or PLAN cosmetic drift; no security or correctness blockers; coverage at or above threshold with some changed files below **100%** target (document gaps).

**Changes required:** Security vulnerability; broken behavior; missing PRD scope; build/test failure; critical architecture violation; **coverage below threshold** on changed production files when a target applies.

---

## Coverage gate (.NET)

Run when PRD, PLAN, or user requires coverage evidence:

```text
/test-coverage - <base-branch> - threshold 80
```

| Result from test-coverage | code-review decision |
|---------------------------|---------------------|
| Pass (≥ threshold) | May approve if all other criteria met |
| Fail (&lt; threshold) | **Alterações necessárias** |
| Not run, target required | Note limitation; ask user to run or waive explicitly |
| Not applicable (no .NET / no target) | Omit coverage rows in § Testes |

---

---
