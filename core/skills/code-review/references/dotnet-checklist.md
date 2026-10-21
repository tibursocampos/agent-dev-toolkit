## .NET review checklist (condensed)

**Structure**

- [ ] Clean Architecture layers respected
- [ ] Namespaces and folder layout consistent
- [ ] Single responsibility; focused methods
- [ ] Cross-stack bar: `structure-and-quality.md` (architecture vs style; identifiers **English**; comments/XML docs **mirror** touched area or **ask** on greenfield)
- [ ] **C# structure/formatting** per `csharp-patterns.md`: one type per file; signatures/invocations (6 params / 160 chars); follow the established project pattern; do not treat pre-existing project literals as a blocking restyle unless the operator approved it; named constants for new code only after that choice (PascalCase; shared files only when reusable); public methods before private, alphabetical within blocks

**C#**

- [ ] Explicit types; nullable reference types where enabled
- [ ] Async/await for I/O; `CancellationToken` propagated
- [ ] No unjustified `dynamic` or blocking `.Result` / `.Wait()`
- [ ] Resources disposed (`using`, `IAsyncDisposable`)

**Tests**

- [ ] Existing project test framework, libraries, naming, and structure followed; toolkit defaults apply only when no baseline is verifiable
- [ ] When toolkit defaults apply: xUnit + Moq + Shouldly as relevant; names `Should_<Result>_When_<Condition>`
- [ ] Arrange / Act / Assert structure with `// Arrange`, `// Act`, `// Assert` comments when consistent with the project baseline
- [ ] Edge cases and failure paths where behavior changed

**EF / data**

- [ ] No obvious N+1; `AsNoTracking` for read-only queries when appropriate — detail: `references/n-plus-one.md`
- [ ] Migrations safe (up/down, indexes, no unintended data loss)

---
