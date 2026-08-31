## .NET implementation pointers

Load on demand - do not paste into PLAN:

| Topic | File |
|-------|------|
| Layers, handlers, repositories | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/clean-architecture.md` |
| Tests, fakes, anti-patterns | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| Pre-PR checklist | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/checklist.md` |

**Test stack (toolkit default):** xUnit, Moq, Shouldly; method names `Should_<Result>_When_<Condition>`.

**Commands (examples):**

```bash
dotnet build
dotnet test --filter "FullyQualifiedName~MyFeatureTests"
dotnet test path/to/TestProject.csproj
```

**Migrations:** when a PLAN step requires a new EF Core migration, hand off to `/ef-add-migration` (optional migration name in PascalCase). Resume the same PLAN step after migration files exist. Details: `{{TOOLKIT_ROOT}}/skills/ef-add-migration/reference.md` or `skills/ef-add-migration/reference.md` in this toolkit repo.

---

## Non-.NET stacks

Follow the step and project docs. Typical checks:

| Stack | Verify |
|-------|--------|
| Angular | `ng build` or `npm run build`; unit tests per `package.json` scripts |
| Node | `npm test` / `pnpm test` scoped to changed package |
| Other | Commands documented in repo `README` or PLAN step |

Keep PLAN updates identical regardless of stack.

---
