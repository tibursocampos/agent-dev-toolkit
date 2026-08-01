# Event-driven architecture (Node / Nest) — HOW overlay

> **Layer C (HOW).** Stack mapping only. Load principles B first: `../../code-guidelines/principles/architecture/event-driven.md`. Do **not** copy or restate the B essay here.
>
> Load **only** when ARCH declares event-driven / EDA. One style per session.

---

## Role

Map domain/integration events onto Node’s `EventEmitter`, Nest events, or the repo’s broker adapters — without locking principles B to a broker library.

---

## MUST

- Treat events as **facts that already happened**; handlers must be idempotent when the project already requires it (retries, at-least-once delivery).
- Keep producers free of knowledge of concrete consumer implementations when ports/adapters already exist.
- Use the project’s existing event surface (`EventEmitter`, Nest `EventEmitter2` / `@OnEvent`, queue client, outbox table) — do not invent a parallel bus for one feature.
- Serialize payloads with stable contracts (versioned fields when neighbors version events).
- Log correlation / causation ids when the project already propagates them.
- Keep identifiers, comments, and logs in **English**.

| Concern | Nest (when matching) | Express / Fastify / plain Node (when matching) |
|---------|----------------------|------------------------------------------------|
| In-process | `@nestjs/event-emitter`, `@OnEvent` | `EventEmitter` / `eventemitter3` already in use |
| Integration | Existing queue/broker module | Existing producer/consumer adapters |
| Consistency | Outbox / inbox if present | Same — do not invent without approval |

---

## MUST NOT

- Force Nest event packages or a cloud broker into a codebase that only uses in-process emitters (or the reverse) without an explicit ask.
- Put long-running or fragile I/O inside synchronous in-process listeners when the project uses async queues for that work.
- Glob-load every `architecture/*.md` — load **this** overlay only when ARCH names event-driven.
- Duplicate event-driven principles from layer B inside this file.
- Use events as a hidden function call (request/response over the bus) when neighbors use direct calls for that path.
- Drop poison messages silently — follow the project’s dead-letter / error handler pattern.

---

## Prefer when matching repo

### event-emitter / Nest events

- Prefer Nest `@OnEvent` / `EventEmitter2` **when** `@nestjs/event-emitter` (or project equivalent) is already wired.
- Prefer Node `EventEmitter` only for **in-process** fan-out when that is the established pattern — not as a substitute for durable integration events.
- Prefer publishing after the successful unit of work commits when the repo uses transactional outbox; otherwise match neighbor publish timing.

### Brokers and workers

- Prefer the existing broker client (SQS, Rabbit, Kafka, Bull/BullMQ, etc.) already in the tree — do not add a second messaging stack for one feature.
- Prefer consumer concurrency and ack/nack behavior that sibling consumers already use.
- Prefer schema validation of inbound payloads at the consumer edge.

### Shared

- Prefer naming events in past tense (`OrderPlaced`) when neighbors do.
- Prefer keeping domain event types in domain/application; keep broker envelope mapping in adapters.
- Prefer integration tests that exercise publish → consume for the changed path when the harness exists.

---

## Thin HOW checklist

1. Confirm ARCH style = event-driven.
2. Read principles B: `event-driven.md` (WHAT).
3. Find existing producer/consumer or `@OnEvent` modules; copy their shape.
4. Add payload contract + handler; wire registration like neighbors.
5. Prove idempotency / retry behavior the way the project already tests messaging.

---

## Related guidelines

- Selection gate (A): `../../code-guidelines/principles/architecture-selection.md`
- Principles B: `../../code-guidelines/principles/architecture/event-driven.md`
- Backend defaults: `../node-backend.md`, `../node-structure-errors.md`, `../node-security.md`
- Sibling overlays (load **one**): `concentric.md`, `vertical-slice.md`

---

## References

- [NestJS — Events](https://docs.nestjs.com/techniques/events)
- [Node.js — EventEmitter](https://nodejs.org/api/events.html)
- [Microsoft — Event-driven architecture style](https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/event-driven)
- [microservices.io — Transactional outbox](https://microservices.io/patterns/data/transactional-outbox.html)
