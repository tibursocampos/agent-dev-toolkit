# Layered structure (Spring Boot / Java)

Prefer the **existing package layout** in the open module. When greenfield or the repo has no clear convention, use a simple layered package model.

> **Principles (WHAT):** default classic layers align with pragmatic concentric flow — see `../code-guidelines/principles/architecture/concentric-dependency.md` when ARCH = concentric. For VSA/Modulith, DDD, or EDA load the matching file under `../code-guidelines/principles/architecture/` instead. Do not copy those essays.  
> **Selection (WHEN):** `../code-guidelines/principles/architecture-selection.md`  
> **Boundaries:** `architecture-boundaries.md`  
> **Style overlays:** `architecture/clean-hexagonal.md`, `architecture/modulith-vertical.md`, `architecture/ddd-tactical.md`, `architecture/event-driven.md`

---

## MUST

- Default to classic layers: **web → service → persistence** (and optional `domain` / `client`) unless ARCH names another style.
- Keep dependency direction one-way: upper layers may call lower layers; persistence and domain must not call web.
- Mirror neighbor package names (`web` vs `controller`, `persistence` vs `repository`) — do not invent a parallel tree beside an existing one.
- Colocate new feature types with similar existing features in the same module.
- Keep controllers free of business rules and free of direct `EntityManager` / repository access unless the project already does that consistently.
- Keep services free of servlet/HTTP types (`HttpServletRequest`, raw status-code branching as core logic).
- Place shared `@Configuration` / security / OpenAPI wiring under `config` (or the repo’s equivalent).
- One public top-level type per file when practical; file name matches the type.
- Lazy-load only the overlay required by ARCH (no `architecture/**` glob).

### Default package layers (greenfield classic)

```
com.example.app/
├── config/          # @Configuration, security, OpenAPI wiring
├── web/             # Controllers, filters, advice, API DTOs
├── service/         # Application services / use-case orchestration
├── domain/          # Domain types (optional if project uses anemic services only)
├── persistence/     # Repositories, entities, Spring Data
└── client/          # Outbound HTTP / messaging adapters (optional)
```

### Dependency direction

```
web -> service -> persistence / domain
```

| Layer | May depend on | Must not |
|-------|---------------|----------|
| `web` | `service`, DTOs, validation | Repositories / EntityManager directly (unless project already does) |
| `service` | `domain`, `persistence` ports, clients | HTTP concerns in core logic |
| `persistence` | entities, Spring Data | Controllers or web DTOs |
| `config` | framework wiring | Business rules |

---

## MUST NOT

- Force hexagonal / Clean Architecture / ports-and-adapters folders onto a classic Spring layered app without an explicit user request or ARCH = concentric.
- Create a new Maven/Gradle module for a small feature unless the user asks.
- Put business rules in controllers or `@ControllerAdvice` beyond mapping exceptions to HTTP.
- Let persistence types (entities) leak into the public API contract when the project uses DTOs elsewhere.
- Introduce Spring Modulith modules as a redesign of an existing flat layered app without approval — see `architecture/modulith-vertical.md` when ARCH = VSA/modulith.
- Duplicate the same feature under both package-by-layer and package-by-feature layouts in one change set.
- Paste principles B rules into this file — pointer only.

---

## Prefer when matching repo

- **Package-by-feature** is fine when the repo already uses it — stay consistent inside the touched area.
- **Hexagonal / Clean Architecture**: follow existing ports, adapters, and module boundaries only when already present or ARCH = concentric → `architecture/clean-hexagonal.md`.
- **Spring Modulith** (VSA on Java): use only if the project already adopts Modulith or ARCH says so → `architecture/modulith-vertical.md`.
- Multi-module: put code in the module that already owns the concern; shared contracts in existing `*-api` / `*-domain` modules.
- Typical feature shape: API DTO + validation → controller → service (`@Transactional` if repo uses it) → repository → entity (only if persistence changes).
- Outbound integrations: keep HTTP/messaging clients in `client` / `infrastructure` as the project already names them.

---

## Typical types per feature

1. API DTO + validation annotations (or project mapper pattern)
2. Controller endpoint(s)
3. Service method(s) with clear transaction boundary
4. Repository / Spring Data interface
5. Entity or persistence model (only if persistence changes)

Check for an existing similar feature first; copy its shape.

---

## References

- [Spring Boot — Structuring Your Code](https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html)
- [Spring Framework — Web MVC](https://docs.spring.io/spring-framework/reference/web/webmvc.html)
- [Spring Data JPA — Repositories](https://docs.spring.io/spring-data/jpa/reference/jpa/repositories.html)
- [Spring Modulith (optional)](https://docs.spring.io/spring-modulith/reference/)
