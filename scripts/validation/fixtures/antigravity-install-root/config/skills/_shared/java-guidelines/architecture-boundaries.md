# Architecture boundaries (Java / Spring Boot)

Rules for what may cross layer and module boundaries. Complements `layered-structure.md`.

> **Principles (WHAT):** load the ARCH style from `../code-guidelines/principles/architecture/` — typically `concentric-dependency.md`, `vertical-slice.md`, `ddd-tactical.md`, or `event-driven.md`. Do not copy those essays here.  
> **Selection (WHEN):** `../code-guidelines/principles/architecture-selection.md`  
> **Stack HOW by style:** `architecture/clean-hexagonal.md`, `architecture/modulith-vertical.md`, `architecture/ddd-tactical.md`, `architecture/event-driven.md`

---

## MUST

- Treat the HTTP/API surface as a **boundary**: request/response DTOs in, domain or persistence models inside.
- Validate inbound payloads at the boundary (`@Valid` / `@Validated`) before service logic runs.
- Keep transaction ownership in the application/service layer (or the layer the project already designates).
- Depend on abstractions at boundaries when the project already uses interfaces for repositories/clients; do not invent interfaces for every class in a simple layered app.
- Isolate outbound I/O (HTTP clients, messaging, mail) behind the project’s existing client/adapter types.
- Fail closed on security boundaries: authenticate/authorize before sensitive service work (see `security-basics.md`).
- Keep Flyway/Liquibase (or equivalent) migrations as the only schema change path when the project uses them.
- Preserve existing module APIs in multi-module builds: public types in `api` modules stay stable; implementation details stay internal.
- Map API status codes and error bodies in the web layer; services throw or return domain results, not raw `ResponseEntity` (unless the project already returns it from services).
- Lazy-load **only** the architecture overlay named in ARCH — never glob `architecture/**`.

### Boundary checklist (per change)

| Boundary | In | Out |
|----------|----|-----|
| Web | DTOs, status mapping, validation | Entities as API body (unless repo standard) |
| Service | Commands/queries, domain rules | Servlet API, JSON annotations as core model |
| Persistence | Entities, repositories | Controllers, web DTOs |
| Messaging / jobs | Payload contracts, idempotency keys | Direct UI/controller calls |

---

## MUST NOT

- Call repositories or `EntityManager` from controllers when services already own that path in the module.
- Pass web-layer types (`MultipartFile`, `Principal` implementation details) deep into persistence.
- Share mutable entity instances across threads or cache entities as API responses without a deliberate project pattern.
- Open a second persistence technology (e.g. add JDBC templates beside JPA) for one feature without user approval.
- Bypass authorization filters by exposing “internal” controllers without the same security config.
- Cross microservice or module boundaries via reach-through to another service’s database.
- Introduce hexagonal ports/adapters folders into a classic layered module without explicit approval / ARCH = concentric.
- Leak lazy-loaded associations through JSON serialization (N+1 / `LazyInitializationException` risk).
- Duplicate principles B content in this file — pointer only.

---

## Prefer when matching repo

- **Classic layered**: DTO ↔ entity mapping in service or dedicated mapper; no ports folder required — see `layered-structure.md`.
- **Hexagonal / Clean already in repo or ARCH=concentric**: `architecture/clean-hexagonal.md` (ports/adapters, ArchUnit, jMolecules Prefer when matching).
- **Modulith / VSA Java**: `architecture/modulith-vertical.md` — respect `@ApplicationModule` / allowed dependencies; module events as the cross-module boundary.
- **DDD tactical**: `architecture/ddd-tactical.md`.
- **Event-driven**: `architecture/event-driven.md`.
- MapStruct vs manual mappers: match the neighbor feature.
- Exception → HTTP: use existing `@ControllerAdvice` / problem-details types; do not invent a parallel error envelope.
- Async boundaries: use the project’s `@Async`, messaging, or virtual-thread patterns as already configured — do not add a new async stack casually.
- API versioning (`/api/v1`): follow existing URL and DTO versioning; do not invent `v2` mid-feature.

---

## Anti-patterns (block)

1. Controller → repository with business `if` chains in the controller.
2. Entity returned from REST with lazy associations triggering N+1 in serialization.
3. Circular dependency between `service` and `web` via shared static helpers.
4. “Util” module that both web and persistence depend on for business rules (hidden domain).
5. Shared mutable static caches of security principals or tenant context without project support.

---

## Related guidelines

- Packages and default layers: `layered-structure.md`
- Boot DI / DTO / validation defaults: `spring-boot-defaults.md`
- CSRF / CORS / deny-by-default: `security-basics.md`
- Config secrets / profiles: `configuration.md`

When in doubt, copy the boundary shape of the nearest similar feature in the same module before inventing a new crossing pattern.

---

## References

- [Spring Boot — Structuring Your Code](https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html)
- [Spring Framework — Validation](https://docs.spring.io/spring-framework/reference/core/validation/beanvalidation.html)
- [Baeldung — DTO Pattern](https://www.baeldung.com/entity-to-and-from-dto-for-a-java-spring-application)
- [Spring Modulith (optional)](https://docs.spring.io/spring-modulith/reference/)
