# DDD tactical patterns — .NET (overlay C)

Thin stack HOW for tactical DDD on .NET. Load when ARCH declares DDD tactical (usually **inside** concentric or hybrid — not a silent default).

> **Principles (WHAT):** `../code-guidelines/principles/architecture/ddd-tactical.md` — aggregates, bounded contexts, ubiquitous language live there. Do not copy that essay.  
> **Selection (WHEN):** `../code-guidelines/principles/architecture-selection.md`  
> **Concentric host (typical):** `clean-architecture.md` + `../code-guidelines/principles/architecture/concentric-dependency.md`

---

## MUST

- Mirror the repo’s Domain model shape (aggregates, entities, value objects, domain events) before inventing new abstractions.
- Keep the Domain project free of EF Core, ASP.NET, and messaging package references.
- Express invariants on the aggregate root (or the type the repo already treats as consistency boundary).
- Map persistence in Infrastructure: DbContext, configurations, repositories — not in Domain entities as EF-coupled models unless the brownfield already does so consistently.
- Use ubiquitous language from the bounded context in type and method names (English identifiers; domain terms match the context glossary when one exists).
- Prefer explicit constructors / factories for aggregates; reject invalid states at the boundary.

---

## MUST NOT

- Introduce a full SharedKernel “god” project for one feature; extend an existing SharedKernel only when the solution already has one and the type is truly cross-context.
- Leak EF `DbContext`, `EntityEntry`, or change-tracking APIs into Domain or Application use-case surfaces.
- Treat every entity as an aggregate root; match neighbor aggregate boundaries.
- Force Vogen / strongly-typed IDs onto a codebase that uses primitive IDs everywhere without approval.
- Duplicate principles B content (aggregate rules, context maps) in this overlay — link instead.
- Start tactical DDD redesign on a CRUD anemic model without ARCH + operator confirm.

---

## Prefer when matching repo

| Concern | Prefer when matching |
|---------|----------------------|
| Strongly-typed IDs / VOs | **Vogen** (or existing VO library) when already in-repo; otherwise hand-rolled VOs matching neighbors |
| Cross-cutting primitives | Existing **SharedKernel** / `BuildingBlocks` only — do not create a new one casually |
| Persistence | EF Core configurations + repositories as the solution already structures them |
| Domain events | Raise in Domain; publish from Application/Infrastructure using the repo’s dispatcher/outbox |
| Validation of commands | FluentValidation at Application edge; domain invariants stay in the model |
| Layout | Concentric Domain project **or** feature-local domain types if hybrid VSA already colocates them |

### Thin SharedKernel policy

SharedKernel holds only stable, context-agnostic primitives the whole solution already shares (e.g. base entity, result type, strongly-typed ID base). Feature-specific domain types stay in their bounded context / feature folder.

### EF mapping sketch (illustrative)

```
Domain/Orders/Order.cs              # aggregate — no EF attributes required if configs used
Infrastructure/Persistence/
  Configurations/OrderConfiguration.cs
  Repositories/OrderRepository.cs
```

Match attribute-vs-fluent config to the neighbor aggregate.

### Load / save checklist (per aggregate change)

1. Identify the consistency boundary already used by neighbors (same root? same DbSet?).
2. Load through the repository / specification the feature already uses — do not query child collections via ad-hoc DbContext in Application.
3. Mutate via domain methods on the root; do not set navigation properties from handlers unless brownfield already does.
4. Persist once per use-case transaction; publish integration events only after successful commit / via outbox.

### Anti-patterns (block)

1. Anemic `OrderService` with public setters on every property and no invariants.
2. New `IOrderManager` facade that bypasses the aggregate API.
3. Cross-aggregate updates in one handler without an existing saga/process manager pattern.
4. Copying tactical vocabulary into Infrastructure type names that are really DTOs.

---

## Related guidelines

- Clean Architecture host: `clean-architecture.md`
- Vertical slices hosting domain types: `vertical-slice.md`
- Integration events / outbox: `event-driven.md`
- C# type/file rules: `csharp-patterns.md`

---

## References

- [Microsoft — Domain-Driven Design patterns](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/)
- [EF Core — Entity types](https://learn.microsoft.com/en-us/ef/core/modeling/)
- [Vogen](https://github.com/SteveDunn/Vogen)
