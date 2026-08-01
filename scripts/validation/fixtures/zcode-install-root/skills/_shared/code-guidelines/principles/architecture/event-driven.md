# Event-Driven Architecture (EDA) Overlay

Use events for **async fan-out**, integration between bounded contexts, and eventual consistency. EDA is an **overlay** on the primary style (concentric or vertical slice) — not a replacement folder tree.

**Stack:** Cross-stack (layer B)  
**Load when:** A’s decision table selected async integration / fan-out  
**Does not replace:** `concentric-dependency.md` or `vertical-slice.md` as the primary structure

---

## Core ideas

- Producers publish facts; consumers react independently.
- Prefer **at-least-once** delivery assumptions → consumers **must** be idempotent.
- Stabilize **contracts** (payload shape, versioning) at context boundaries.
- Use an **outbox** (or equivalent transactional publication) so state change and event publication do not diverge.

```
Primary style folders (unchanged)
        │
        ├── Domain / Slice writes state
        ├── Outbox (same transaction as state) ──► dispatcher ──► bus/broker
        └── Consumers / handlers (idempotent)
```

---

## MUST

- Treat EDA as an overlay: keep the primary architecture folders; add messaging ports/adapters at the edges.
- Ensure publication is **reliably tied** to the business transaction (outbox or documented equivalent).
- Design consumers for **idempotency** (dedupe keys, natural idempotent upserts, or stored processed-message ids).
- Version and document integration contracts; avoid silent breaking field renames.
- Separate **domain events** (model facts) from **integration events** (cross-process contracts) with an explicit mapping when both exist.
- Bound consistency expectations: document eventual consistency where immediate consistency is not provided.

---

## MUST NOT

- Replace the whole codebase layout with “events everywhere” folders when a request/response style suffices (YAGNI).
- Lock guidelines to one broker or cloud bus product.
- Assume exactly-once delivery without an idempotent consumer story.
- Publish events from UI adapters without going through the application/domain boundary used by the primary style.
- Prescribe specific messaging libraries or frameworks in this B file.
- Drop transactional integrity (state committed, event lost — or the reverse) without an outbox-style remedy.

---

## Prefer when matching repo

- Outbox/inbox tables or dispatcher already exist → extend that pattern.
- Concentric repo → ports in application/domain; adapters in infrastructure.
- VSA repo → keep feature slices; messaging adapters stay thin and shared only when proven.
- Dual write without outbox observed → flag as blocking risk; introduce outbox or equivalent.
- Chatty sync HTTP between services where async fan-out fits → propose EDA overlay via A + confirm if greenfield/new.

---

## Contract checklist

| Concern | Guidance |
|---------|----------|
| Naming | Past-tense business facts (`OrderPlaced`) |
| Payload | Minimal stable fields; ids over deep graphs |
| Versioning | Additive changes preferred; explicit version when breaking |
| Ordering | Do not assume global order unless the platform guarantees it |
| Failure | Retry + dead-letter / poison strategy matching the repo |

---

## Review checklist

- [ ] Overlay did not erase primary style boundaries
- [ ] Outbox (or equivalent) covers state + publish
- [ ] Consumers idempotent under retry
- [ ] No broker product mandated by principles
- [ ] Contracts versioned or additive

---

## References

- [Microservices.io — Transactional outbox](https://microservices.io/patterns/data/transactional-outbox.html)
- [Martin Fowler — Event-Driven Architecture](https://martinfowler.com/articles/201701-event-driven.html)
- [Microsoft Learn — Event-driven architecture style](https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/event-driven)

**Version:** 1.0 (agent-dev-toolkit)
