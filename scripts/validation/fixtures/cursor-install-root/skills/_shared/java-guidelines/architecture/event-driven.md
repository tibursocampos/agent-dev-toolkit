# Event-driven architecture — Java (overlay C)

Stack HOW for messaging and async collaboration on Java/Spring. Load when ARCH declares event-driven / EDA (often as an **overlay** on layered, hexagonal, or Modulith — not a silent default).

> **Principles (WHAT):** `../../code-guidelines/principles/architecture/event-driven.md` — outbox, eventual consistency, idempotent consumers. Do not copy that essay.  
> **Selection (WHEN):** `../../code-guidelines/principles/architecture-selection.md`  
> **Hosts:** `modulith-vertical.md`, `clean-hexagonal.md`, `../layered-structure.md`, `../architecture-boundaries.md`

---

## MUST

- Discover the existing event stack first (Spring Modulith events, Spring Cloud Stream, Axon, Kafka listeners, JMS, transactional outbox library) before adding a new broker framework.
- Keep payload contracts stable and versioned as the repo already versions them.
- Implement listeners/handlers beside existing ones: same package layout, error handler, retry, and DLQ topology.
- Map inbound messages to application use cases; do not bury rich domain rules only in the transport listener.
- Ensure idempotency matches neighbor consumers (dedup store, natural key, framework interceptor).
- Keep broker credentials in Spring config / secrets providers — never hard-code.

---

## MUST NOT

- Force **Axon**, **SCS**, or a new broker onto a codebase that already standardized on another approach.
- Bypass Modulith application events with illegal cross-module persistence when Modulith is the collaboration model.
- Skip transactional outbox / inbox when the project already requires it for the touched aggregate or integration.
- Invent a second retry/error stack beside the one Spring Cloud Stream / Kafka / Axon already configures.
- Default to full event-sourcing for a simple async notification without ARCH + confirm.
- Duplicate principles B (choreography vs orchestration theory) here — link instead.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Spring Modulith + `@ApplicationModuleListener` / module events | **Modulith events** for in-process modular collaboration |
| Spring Cloud Stream binders already present | **SCS** suppliers/consumers matching binder and content-type |
| Axon Framework packages / aggregates | **Axon** command/event/query model as neighbors do |
| Kafka / Rabbit listeners without SCS | Stay on Spring Kafka / AMQP templates already wired |
| Transactional outbox library (e.g. Debezium, custom outbox table) | Keep publishing through that path |
| No bus yet + greenfield EDA confirmed | Ask before pinning; prefer the org’s standard (often Modulith events in-process, SCS/Kafka cross-process) |

### Alignment with other overlays

| Host style | Where handlers live |
|------------|---------------------|
| Modulith / VSA | Inside the owning module; cross-module via module events — `modulith-vertical.md` |
| Hexagonal | Inbound messaging adapters → application ports — `clean-hexagonal.md` |
| Classic layered | `messaging` / `listener` packages calling services — `../layered-structure.md` |
| DDD tactical | Domain events → application publish — `ddd-tactical.md` |

### Listener checklist (per new handler)

1. Detect binder/framework (Modulith, SCS, Axon, Kafka/JMS) from packages and existing listeners.
2. Confirm topic/queue, content type, concurrency, DLQ, and idempotency with the operator when greenfield.
3. Implement listener + registration + payload type matching neighbors.
4. Cover publication and consumption with the suite style already used in that module.

### Anti-patterns (block)

1. Publishing from a JPA `@Entity` lifecycle callback when the project uses application/outbox publish.
2. Reach-through to another Modulith module’s repository instead of a module event.
3. Adding Axon or a second binder “just for this feature” beside an established stack.
4. Listener that opens another service’s datasource for writes.

### Tests

- Prefer tests that assert event publication and consumer side effects using the repo’s harness (`@ApplicationModuleTest`, Testcontainers, EmbeddedKafka, Axon test fixtures).
- Unit-test pure mapping/idempotency logic without a broker when cheaper.
- Shared fixtures under test-support — do not duplicate arrange blocks.

---

## Related guidelines

- Modulith testing: `modulith-vertical.md`
- Security of internal endpoints / jobs: `../security-basics.md`
- Config profiles / secrets: `../configuration.md`
- General testing defaults: `../testing.md`

---

## References

- [Spring Modulith — Events](https://docs.spring.io/spring-modulith/reference/events.html)
- [Spring Cloud Stream reference](https://docs.spring.io/spring-cloud-stream/docs/current/reference/html/)
- [Axon Framework reference](https://docs.axoniq.io/reference-guide/)
- [Spring for Apache Kafka](https://docs.spring.io/spring-kafka/reference/index.html)
