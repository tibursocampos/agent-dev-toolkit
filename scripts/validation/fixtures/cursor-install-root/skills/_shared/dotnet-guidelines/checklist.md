# .NET delivery checklist

Use before opening a pull request.

---

## Preparation

- [ ] `AGENTS.md` and relevant skills reviewed
- [ ] PLAN step (if applicable) marked complete
- [ ] Acceptance criteria understood

---

## Branching

- [ ] Working branch created: `feature/<slug>` or `feat/<id>-<slug>`
- [ ] Branch based on the correct default branch (e.g. `main` / `develop`)

---

## Implementation

- [ ] Command exists (if using CQRS-style flow)
- [ ] Command handler exists
- [ ] FluentValidation validator exists for the command
- [ ] Response/DTO defined
- [ ] Controller has no business logic
- [ ] No validation outside FluentValidation
- [ ] Guard clauses used (no deep nested `if`)
- [ ] Single responsibility respected
- [ ] Identifiers and comments in **English**
- [ ] Changes follow `dotnet-guidelines` (clean architecture + C# patterns)
- [ ] New types prefer modern C# (primary constructors, collection expressions, `required`) when no conflicting repo style; otherwise match the project

---

## Code structure and formatting (`csharp-patterns.md`)

- [ ] **One top-level type per file** (no second `class` / `record` in the same file)
- [ ] **Signatures and invocations:** inline only when ≤ 5 parameters and full line ≤ 150 characters; otherwise one parameter per line
- [ ] **Follow existing project patterns** (Glob/Read similar types; no parallel validation/flow)
- [ ] **Named constants** in production code - no magic strings/numbers; `const` names in **PascalCase**; shared Constants files only for reusable values; prefer `partial` / regions when shared files grow
- [ ] **Method ordering:** all public methods (alphabetical), then all private methods (alphabetical)

---

## .NET patterns

- [ ] Async methods use `Async` suffix
- [ ] `await` used (no `.Result` / `.Wait()` / `ConfigureAwait` in app code)
- [ ] `CancellationToken` propagated on async APIs
- [ ] `IDisposable` / `IAsyncDisposable` handled with `using` / `await using`
- [ ] `IOptions<T>` for configuration
- [ ] `IHttpClientFactory` for `HttpClient` (resilience via `Microsoft.Extensions.Http.Resilience` when adding HTTP clients)

---

## Clean architecture

- [ ] Domain has no external dependencies
- [ ] Application depends only on Domain
- [ ] Infrastructure implements Domain interfaces
- [ ] API references only Application
- [ ] Folder layout matches the repo (classic layers or feature folders) - do not invent a parallel structure

---

## Tests (new code)

- [ ] xUnit (`[Fact]` / `[Theory]`)
- [ ] Shouldly (`ShouldBe`, `ShouldNotBeNull`, …)
- [ ] Moq for mocks
- [ ] Names follow `Should_<Result>_When_<Condition>`
- [ ] English identifiers in tests
- [ ] Mock variables suffixed with `Mock`
- [ ] Arrange data built via `*Fake` classes (not inline domain objects)
- [ ] One behavior per test
- [ ] Arrange / Act / Assert structure with `// Arrange`, `// Act`, `// Assert` comments

---

## Build and quality

- [ ] `dotnet build` succeeds
- [ ] `dotnet test` passes
- [ ] No new nullable reference type warnings (or documented)
- [ ] Coverage ≥ 80% on changed files (`/test-coverage`; goal 100% when feasible)
- [ ] SOLID and clean-code basics respected
- [ ] No obvious security issues (secrets, injection, unsafe defaults)
- [ ] No obvious N+1 or hot-path inefficiencies
- [ ] Prefer: Central Package Management when the solution uses or starts CPM
- [ ] Prefer: `dotnet list package --vulnerable` reviewed for changed dependency graphs

| Stack | Blocking | Optional |
|-------|----------|----------|
| .NET | `dotnet build`, `dotnet test` | `csharpier check .` |

---

## Pull request

- [ ] PR targets the correct base branch
- [ ] Title follows conventional format (see `rules/conventional-commits.md` when synced)
- [ ] Description lists what changed and how to test
- [ ] Linked issue/ticket referenced (if your workflow uses one)

---

## Blockers vs warnings

| Type | Examples | Action |
|------|----------|--------|
| **Blocker** | Build failed, tests failing, wrong base branch, coverage below 80% on changed files (when `test-coverage` reports fail) | Fix before PR |
| **Warning** | Coverage below 100% but ≥ 80%, style nits, vulnerable package advisories pending triage | Document or fix in follow-up |

| Problem | Action |
|---------|--------|
| Build failed | Fix usings, types, package references |
| Tests failing | Fix implementation or test; avoid disabling without reason |
| Low coverage (&lt; 80% on changed files) | Run `/test-coverage`; add tests for uncovered behavior |

---

## Final summary

- [ ] All blockers resolved
- [ ] Warnings reviewed
- [ ] Build and tests green
- [ ] PLAN/checklist notes updated if using SDD
