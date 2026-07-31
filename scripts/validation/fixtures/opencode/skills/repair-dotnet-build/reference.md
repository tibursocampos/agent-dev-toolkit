# repair-dotnet-build - reference

Heuristics and optional CI helpers for `skills/repair-dotnet-build/SKILL.md`. Keep `SKILL.md` under 500 lines; use this file for extended detail.

---

## Common causes (tests and build)

### Culture and parsing

| Symptom | Likely cause | Fix direction |
|---------|--------------|---------------|
| `decimal.Parse` mismatch across OS | Implicit culture (en-US vs pt-BR) | `CultureInfo.InvariantCulture` or explicit culture matching data source |
| FluentValidation message mismatch | `CurrentUICulture` vs agent locale | Set `CultureInfo.DefaultThreadCurrentUICulture` in test fixture |
| xUnit collection fixture order | Culture set too late | Set default thread cultures in fixture constructor before tests run |

### Dates and time zones

| Symptom | Likely cause | Fix direction |
|---------|--------------|---------------|
| Off-by-hours in assertions | `DateTime.Now` vs UTC | Prefer `DateTime.UtcNow` or explicit `TimeZoneInfo.ConvertTime` |
| Flaky “today” tests | Hardcoded date relative to run day | Inject `TimeProvider` / clock abstraction or freeze test time |

### Random / generated data

| Symptom | Likely cause | Fix direction |
|---------|--------------|---------------|
| Intermittent assertion values | Bogus or random without fixed seed | Fix seed in test infrastructure or use deterministic builders |
| Mapper vs fake culture drift | Both parse decimals without culture | Align fake and mapper to same explicit `CultureInfo` |

### Restore and compile

| Symptom | Likely cause | Fix direction |
|---------|--------------|---------------|
| Package not found | Missing feed in `NuGet.Config` | Document feed in repo README; do not invent corporate URLs |
| Linux CI glob not expanding | `**/*.Test*.csproj` without globstar | Use solution file path in pipeline (when user shares YAML) |

---

## Local commands

```bash
# Full solution (default)
dotnet build
dotnet test --no-build

# Large repo - scoped
dotnet test path/to/TestProject.csproj --filter "FullyQualifiedName~MyFeatureTests"
dotnet test --no-build --filter "FullyQualifiedName~MyFeatureTests"
```

Capture tail of output for diagnosis; read full lines for file paths and test names.

---

## Pasted CI log - what to extract

| Signal | Pattern |
|--------|---------|
| Compile error | `error CS`, file path, line number |
| Restore | `restore failed`, `NU1101`, unauthorized feed |
| Test failure | `[FAIL]`, `Failed!`, `Error Message:`, `Expected`, `Actual`, `.cs:line` |
| Docker/other | `exit code`, `exception`, step name from log header |

Ignore stack frames from test frameworks unless they point to product code.

---

## CI logs (paste only)

When the user references a CI failure, ask them to **paste** the failed job/step log. Parse failed steps similarly to local pasted logs.

Do not call remote CI APIs or CLIs. Stay on local `dotnet build` / `dotnet test` when no paste is available.

Do not use this section for non-GitHub hosts unless the user pastes logs.

---

## Diagnosis template (extended)

```markdown
## Build diagnosis

**Source:** local | pasted log | GitHub Actions (run <id>)
**Branch:** feature/...
**Failures:** 2

### 1. [Test] Should_ReturnTotal_When_ItemsAdded
- **File:** tests/.../OrderTests.cs:42
- **Expected:** 10.5
- **Actual:** 10,5
- **Hypothesis:** culture - see § Culture and parsing

### 2. [Compile] CS0246 in Handler.cs:12
- **Hypothesis:** missing using or renamed type
```

---

## Fix proposal template

```markdown
## Proposed fixes

1. **src/.../Mapper.cs:28** - implicit `decimal.Parse`
   - **Cause:** culture-dependent parsing on Linux CI
   - **Fix:** `decimal.Parse(value, CultureInfo.InvariantCulture)`

Apply these fixes? (wait for user yes/no)
```

---

## Commit handoff

After local validation:

```
/commit
```

The commit skill enforces `feature/<slug>` / `feat/<id>` and Conventional Commits. repair-dotnet-build does not call tracker APIs or link work items.

---

## Relationship to other skills

| Need | Skill |
|------|-------|
| EF migration after model fix | `/ef-add-migration` |
| Small feature without PLAN | `/dotnet-developer` |
| PLAN-sized work | `/sdd-develop - <full-plan-path> - Step N` (resolve SDD PLAN per `STORAGE.md` - repo or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/sdd/<repo-id>/PLAN/`) |
| New feature / no PLAN | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` (`STORAGE.md` for PRD/PLAN location) |
