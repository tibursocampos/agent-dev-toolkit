# Concentric architecture (Node / Nest) — HOW overlay

> **Layer C (HOW).** Stack mapping only. Load principles B first: `../../code-guidelines/principles/architecture/concentric-dependency.md`. Do **not** copy or restate the B essay here.
>
> Load **only** when ARCH declares concentric / clean / onion / hexagonal (aliases of the same rule). One style per session.

---

## Role

Map concentric dependency (domain inward; adapters outward) onto Nest modules/ports **or** Express/Fastify layered folders — whichever the repo already uses.

---

## MUST

- Keep domain / application free of HTTP, ORM, and message-broker types when the tree already separates them.
- Put Nest controllers, Express/Fastify route handlers, and persistence adapters at the **edge**; call inward through existing ports or service interfaces.
- Mirror the repo’s module or folder boundaries — do not invent a second ports tree beside an established layered layout.
- Inject dependencies the way neighbors do (Nest DI, factory wiring, or explicit constructors) — no ad-hoc `new` of adapters inside domain.
- Validate and map DTOs at the HTTP adapter; do not leak transport shapes into domain entities.
- Fail closed at security boundaries before domain work runs (`node-security.md`).
- Keep identifiers, comments, and logs in **English**.

| Ring | Nest (when matching) | Express / Fastify (when matching) |
|------|----------------------|-----------------------------------|
| Domain / application | Services, domain modules, port interfaces | `services/` / `domain/` free of `req`/`res` |
| Adapters in | Controllers, pipes, guards | Route handlers, schema validation |
| Adapters out | TypeORM/Prisma/repositories, HTTP clients | `repositories/`, clients, queues |

---

## MUST NOT

- Force Nest modules/ports onto an Express/Fastify codebase (or the reverse) without an explicit migration ask.
- Import `@nestjs/*`, Express, Fastify, or ORM types into pure domain modules when the project already forbids it.
- Glob-load every `architecture/*.md` — load **this** overlay only when ARCH names concentric (or alias).
- Duplicate concentric rules from principles B inside this file.
- Add hexagonal `ports/` / `adapters/` folders into a classic layered tree without approval.
- Put business rules in controllers or route handlers when services/domain already own them.

---

## Prefer when matching repo

### Nest modules / ports

- Prefer Nest **modules** with clear `imports` / `exports` when `@nestjs/core` is present.
- Prefer **ports** (interfaces) in application/domain and adapter implementations in infrastructure modules when the repo already uses that shape.
- Prefer Nest providers / custom providers for adapter wiring — match neighbor modules.
- Prefer keeping controllers thin: map DTO → use-case → response; no persistence in controllers.

### Express / Fastify concentric slices

- Prefer layered `routes|controllers` → `services|domain` → `repositories|data` when that tree exists.
- Prefer Fastify plugins / Express routers as **inbound adapters** only; keep schemas at the edge.
- Prefer a single composition root (app factory / bootstrap) that wires adapters — do not scatter connection setup in domain.

### Shared

- Prefer matching the nearest similar feature’s ring placement before inventing a new boundary.
- Prefer one persistence technology already in the repo; do not add a second for one feature.
- Prefer central error mapping at the adapter edge (`node-structure-errors.md`).

---

## Thin HOW checklist

1. Confirm ARCH style = concentric (or CA / onion / hexagonal alias).
2. Read principles B: `concentric-dependency.md` (WHAT).
3. Locate existing domain vs adapter folders/modules; copy that shape.
4. Add use-case inward; add HTTP/persistence only at the edge.
5. Tests: domain without HTTP; adapter tests with project harness (supertest / Fastify `inject` / Nest testing module).

---

## Related guidelines

- Selection gate (A): `../../code-guidelines/principles/architecture-selection.md`
- Principles B: `../../code-guidelines/principles/architecture/concentric-dependency.md`
- Backend defaults: `../node-backend.md`, `../node-structure-errors.md`, `../node-security.md`
- Sibling overlays (load **one**): `vertical-slice.md`, `event-driven.md`

---

## References

- [NestJS — Modules](https://docs.nestjs.com/modules)
- [NestJS — Custom providers](https://docs.nestjs.com/fundamentals/custom-providers)
- [Microsoft — Clean Architecture](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [Alistair Cockburn — Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
