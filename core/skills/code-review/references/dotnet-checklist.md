## .NET review checklist (condensed)

**Structure**

- [ ] Clean Architecture layers respected
- [ ] Namespaces and folder layout consistent
- [ ] Single responsibility; focused methods
- [ ] **C# structure/formatting** per `csharp-patterns.md` (blocking when violated): one type per file; signatures/invocations (5 params / 150 chars); follow existing patterns; named constants (no magic literals, PascalCase; shared files only when reusable); public methods before private, alphabetical within blocks

**C#**

- [ ] Explicit types; nullable reference types where enabled
- [ ] Async/await for I/O; `CancellationToken` propagated
- [ ] No unjustified `dynamic` or blocking `.Result` / `.Wait()`
- [ ] Resources disposed (`using`, `IAsyncDisposable`)

**Tests**

- [ ] xUnit + Moq + Shouldly
- [ ] Names: `Should_<Result>_When_<Condition>`
- [ ] Arrange / Act / Assert structure with `// Arrange`, `// Act`, `// Assert` comments
- [ ] Edge cases and failure paths where behavior changed

**EF / data**

- [ ] No obvious N+1; `AsNoTracking` for read-only queries when appropriate
- [ ] Migrations safe (up/down, indexes, no unintended data loss)

---
