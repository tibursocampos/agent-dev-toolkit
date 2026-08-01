# Clean Architecture — .NET (overlay C)

Stack HOW for concentric dependency on .NET. Load **only** when ARCH declares concentric / Clean Architecture / Onion / Hexagonal (or brownfield already mirrors this layout).

> **Principles (WHAT):** `../code-guidelines/principles/architecture/concentric-dependency.md` — do not duplicate that essay here.  
> **Selection (WHEN):** `../code-guidelines/principles/architecture-selection.md`

---

## MUST

- Default to classic concentric projects when ARCH = **concentric** (or aliases CA / Onion / Hexagonal): `Domain` → `Application` → `Infrastructure` → `API` (or the repo’s exact names).
- Keep dependency direction inward: Domain has no external deps; Application depends on Domain; Infrastructure implements Domain/Application ports; API references Application (not Infrastructure directly unless the repo already does).
- Controllers stay thin: no business rules, no direct database access.
- Business rules live in Domain; persistence adapters live in Infrastructure; Application orchestrates use cases.
- For each use case ship **Command / Handler / Validator / Response** (names may match repo: `*CommandHandler`, `IRequestHandler`, etc.).
- All inbound validation uses **FluentValidation** (or the repo’s established validator stack) — one validator per command.
- Before inventing layout, Glob/Read a similar feature in the same solution and mirror it (`csharp-patterns.md` — follow existing project patterns).
- Guard clauses at method start; English identifiers.

### Default layer tree (greenfield concentric)

```
src/
├── Domain/           # Entities, value objects, domain interfaces
├── Application/      # Commands, handlers, validators, DTOs, mappings
├── Infrastructure/   # Repositories, persistence, external clients
└── API/              # Controllers, middleware, composition root
tests/
├── Unit/             # Domain, Application, fixtures
└── Integration/      # API, Infrastructure, fixtures
```

---

## MUST NOT

- Invert dependencies (Domain → Infrastructure, Application → EF types as core model).
- Put validation in controllers, handlers, or entities when FluentValidation (or repo equivalent) owns the edge.
- Use DataAnnotations / inline ad-hoc validation as the primary command validation path.
- Force feature-folder redesign onto a classic layer-only tree without ARCH = VSA/hybrid or explicit approval.
- Require MediatR — see `recommended-libraries.md` for commercial-license notes.
- Change the solution’s architectural structure without explicit approval.
- Copy principles essays into this file; link to concentric-dependency instead.

---

## Prefer when matching repo

| ARCH / repo signal | Layout |
|--------------------|--------|
| **concentric** (default for this overlay) | Project-per-layer as above |
| **VSA / hybrid** | Feature folders under Application/API while **keeping** concentric dependency rules — see `vertical-slice.md` |
| Existing `src/<BoundedContext>/...` | Mirror bounded-context folders; do not flatten |
| Existing dispatcher (MediatR / Mediator / Wolverine / internal) | Keep it; do not swap for a paid package without approval |

- Map API status/errors in the host layer; return domain/application results from handlers.
- Implementation order: Domain → Application → Infrastructure → API → Tests.

### Layer flow

```
Controller → Application → Domain ← Infrastructure
```

---

## Naming (stack)

- Prefer specific types: `RegisterOrderCommand`, `RegisterOrderCommandValidator`, `RegisterOrderResponse`.
- Avoid `Helper`, `Utils`, `Manager`, `GenericService` without a clear single responsibility.

---

## Related guidelines

- Vertical slice HOW: `vertical-slice.md`
- DDD tactical HOW: `ddd-tactical.md`
- Messaging HOW: `event-driven.md`
- Patterns / one-type-per-file: `csharp-patterns.md`
- Dispatcher license notes: `recommended-libraries.md`

---

## References

- [Microsoft — Clean Architecture](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [Architecture Styles — Clean Architecture](https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/web-queue-worker)
- [FluentValidation](https://docs.fluentvalidation.net/)
