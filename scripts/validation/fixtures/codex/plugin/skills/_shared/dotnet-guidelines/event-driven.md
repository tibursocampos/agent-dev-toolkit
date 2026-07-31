# Event-driven architecture — .NET (overlay C)

Stack HOW for messaging and async workflows on .NET. Load when ARCH declares event-driven / EDA (often as an **overlay** on concentric or VSA — not a silent default).

> **Principles (WHAT):** `../code-guidelines/principles/architecture/event-driven.md` — outbox, eventual consistency, consumer idempotency live there. Do not copy that essay.  
> **Selection (WHEN):** `../code-guidelines/principles/architecture-selection.md`  
> **Scaffold skill:** `../../scaffold-message-handler/SKILL.md` + `reference.md` (detect bus, collect requirements, mirror consumers)

---

## MUST

- Discover the existing messaging stack first (packages, `AddMassTransit` / Wolverine / ASB / raw clients) before adding a new broker library.
- Keep message contracts stable and versioned as the repo already versions them (shared contracts assembly or feature-local messages).
- Implement consumers beside existing ones: same namespace layout, registration, retry/error topology, and test base.
- Treat handlers as application boundaries: map message → command/use case; do not put rich domain rules only in the transport adapter.
- Ensure idempotency and duplicate delivery handling match neighbor consumers (inbox key, natural business key, or framework middleware already configured).
- Keep secrets and connection strings in configuration providers — never hard-code broker URLs or credentials.

---

## MUST NOT

- Force MassTransit, Wolverine, NServiceBus, or Axon-style tooling onto a repo that already standardized on another bus.
- Publish domain events directly to the broker from Domain entities without the Application/Infrastructure path the solution uses (outbox/dispatcher).
- Bypass outbox/inbox when the project already requires them for the touched aggregate or integration.
- Invent a second error/retry stack beside MassTransit `_error` / Wolverine policies / ASB dead-letter already in use.
- Scaffold consumers without reading `scaffold-message-handler` detection rules when the user asks for a new handler.
- Duplicate principles B (consistency models, choreography vs orchestration theory) here — link instead.

---

## Prefer when matching repo

| Stack signal | Prefer |
|--------------|--------|
| MassTransit packages / `IConsumer<T>` | **MassTransit** — keep transport (RabbitMQ, ASB, SQS, in-memory) as configured |
| Wolverine / JasperFx | **Wolverine** handlers and transactional outbox as neighbors do |
| Azure.Messaging.ServiceBus only | ASB processors / hosted services already in-repo |
| Cap / Rebus / NServiceBus / internal bus | Stay on that stack |
| No bus yet + greenfield EDA confirmed | Ask before pinning; toolkit scaffold default is MassTransit + RabbitMQ when none detected — still confirm with the operator |

### Outbox / integration events

- Prefer the project’s transactional outbox (MassTransit EF outbox, Wolverine outbox, or custom) when cross-process publish must commit with the business transaction.
- Distinguish **domain events** (in-process) from **integration events** (cross-service) the way the codebase already names them.

### Alignment with other overlays

| Host style | Where consumers live |
|------------|----------------------|
| Concentric | Infrastructure messaging + Application handlers — see `clean-architecture.md` |
| VSA | Feature folder next to the producing use case — see `vertical-slice.md` |
| DDD tactical | Raise in Domain; publish after persistence — see `ddd-tactical.md` |

### Consumer checklist (per new handler)

1. Run `scaffold-message-handler` detection (or Glob existing consumers) — record bus, contract location, registration file.
2. Collect queue/topic, concurrency, poison handling, and idempotency key with the operator when greenfield.
3. Implement consumer + registration + contract (if new) matching neighbors.
4. Add/adjust integration test using the repo’s harness before claiming done.

### Anti-patterns (block)

1. `IBus.Publish` from a Domain entity method.
2. Fire-and-forget publish with no failure path when the project uses outbox/retry.
3. New broker library beside an existing MassTransit/Wolverine registration “just for this feature”.
4. Consumer that writes to another service’s database instead of emitting an integration event.

### Tests

- Prefer integration tests that exercise serialize → consume → assert side effects using the repo’s test harness (Testcontainers / in-memory bus / MassTransit test harness).
- Unit-test pure mapping and policy logic without standing up a broker when cheaper.

---

## Related guidelines

- Consumer scaffold: `../../scaffold-message-handler/SKILL.md`
- CA / VSA / DDD hosts: `clean-architecture.md`, `vertical-slice.md`, `ddd-tactical.md`
- Magic values / queue name constants: `csharp-patterns.md`

---

## References

- [MassTransit documentation](https://masstransit.io/documentation)
- [Wolverine documentation](https://wolverinefx.net/)
- [Microsoft — Asynchronous messaging](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/architect-microservice-container-applications/asynchronous-message-based-communication)
