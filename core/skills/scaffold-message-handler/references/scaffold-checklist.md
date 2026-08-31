## Scaffold checklist (implementation)

Use after user confirms the plan. Check off in session notes; not all rows apply to every stack.

| Area | Verify |
|------|--------|
| **Contract** | Message DTO/event in correct layer (often Application contracts or shared messaging project) |
| **Consumer** | Handler class or `IConsumer<T>` with single responsibility |
| **Registration** | Bus/consumer registered in DI (`Program.cs`, `DependencyInjection`, `MassTransit` config) |
| **Configuration** | Queue/topic name from named constants - see `csharp-patterns.md` § **Named constants (no magic literals)** |
| **Errors** | Retry policy matches checklist; poison path documented |
| **Idempotency** | Dedup or idempotent handler per checklist |
| **Logging** | Structured log on start, success, failure (correlation id if repo uses it) |
| **Tests** | Meaningful behavior test per `csharp-patterns.md`; integration if repo already has harness |
| **Build** | `dotnet build` + filtered `dotnet test` pass |

---
