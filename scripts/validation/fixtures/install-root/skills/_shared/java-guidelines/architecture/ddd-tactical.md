# DDD tactical patterns — Java (overlay C)

Thin stack HOW for tactical DDD on Java/Spring. Load when ARCH declares DDD tactical (usually **inside** concentric or Modulith — not a silent default).

> **Principles (WHAT):** `../../code-guidelines/principles/architecture/ddd-tactical.md` — aggregates, bounded contexts, ubiquitous language. Do not copy that essay.  
> **Selection (WHEN):** `../../code-guidelines/principles/architecture-selection.md`  
> **Typical hosts:** `clean-hexagonal.md`, `modulith-vertical.md`, `../layered-structure.md`

---

## MUST

- Mirror the repo’s domain model (aggregates, entities, value objects, domain events) before inventing new stereotypes.
- Keep the domain model free of Spring Web and persistence-vendor APIs unless brownfield already mixes them consistently (prefer separation).
- Enforce invariants on the aggregate root (or the type the codebase treats as the consistency boundary).
- Map persistence in adapters / persistence packages — repositories implement outbound ports when hexagonal; classic layered apps keep repositories under `persistence` as neighbors do.
- Name types with the ubiquitous language of the owning bounded context / module.
- Prefer constructors/factories that reject invalid aggregate state at creation time.

---

## MUST NOT

- Introduce jMolecules, ArchUnit, or a SharedKernel module casually when the build does not already use them.
- Leak `EntityManager`, Spring Data types, or JSON annotations into the domain core when neighbors keep them out.
- Treat every JPA `@Entity` as an aggregate root — match neighbor aggregate boundaries.
- Start a tactical DDD redesign on a CRUD anemic model without ARCH + operator confirm.
- Duplicate principles B (context mapping theory, aggregate design essays) here — link instead.
- Put cross-context domain types into a dumping-ground `common` package without an existing SharedKernel pattern.

---

## Prefer when matching repo

| Concern | Prefer when matching |
|---------|----------------------|
| Stereotypes / modeling | **jMolecules** (`@AggregateRoot`, `@Entity`, …) when already on the classpath |
| Structural enforcement | **ArchUnit** rules already protecting domain packages |
| Persistence | Spring Data JPA + explicit aggregate loading as neighbors do |
| Value objects | Immutable types / records matching project style |
| Domain events | Raise in domain; publish via application service / outbox / Modulith events as configured |
| Modulith | One bounded context ≈ one application module — see `modulith-vertical.md` |
| Hexagonal | Domain in core; JPA entities may be adapters if the repo already separates them — see `clean-hexagonal.md` |

### Thin shared kernel

Only stable, context-agnostic primitives belong in an existing shared module. Feature-specific domain stays in its bounded context / Modulith module.

### Illustrative placement

```
domain/order/Order.java                 # aggregate
domain/order/OrderId.java               # value object
application/order/PlaceOrderService.java
adapter/out/persistence/OrderJpaRepository.java
```

Rename to match brownfield (`model`, `core`, multi-module `order-domain`).

### Load / save checklist (per aggregate change)

1. Identify the consistency boundary neighbors already use (same root entity? same module?).
2. Load via the repository/port the feature already uses — avoid ad-hoc `EntityManager` queries from web.
3. Mutate through domain methods on the root; keep setters package-private or absent when neighbors do.
4. Flush/commit once per use-case transaction; publish integration / module events after success or via outbox.

### Anti-patterns (block)

1. Anemic JPA entity with all-public setters and business `if` chains only in the controller.
2. New `*Manager` that bypasses aggregate methods and writes children directly.
3. Cross-aggregate updates in one service without an existing process/saga pattern.
4. Dumping every VO into a global `common.model` package.

---

## Related guidelines

- Boundaries: `../architecture-boundaries.md`
- Event publish paths: `event-driven.md`
- Style / Optional / logging: `../java-style.md`
- Testing: `../testing.md`

---

## References

- [jMolecules](https://github.com/xmolecules/jmolecules)
- [Spring Data JPA — Repositories](https://docs.spring.io/spring-data/jpa/reference/jpa/repositories.html)
- [ArchUnit user guide](https://www.archunit.org/userguide/html/000_Index.html)
- [Domain-Driven Design reference (overview)](https://www.domainlanguage.com/ddd/)
