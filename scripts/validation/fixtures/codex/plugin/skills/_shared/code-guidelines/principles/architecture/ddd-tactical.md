# DDD Tactical Patterns

Tactical Domain-Driven Design building blocks for modeling **rich domains**. Use **inside** a concentric (or existing domain-centric) style — not as a standalone folder replacement.

**Stack:** Cross-stack (layer B)  
**Load after:** `concentric-dependency.md` (typical) when A selected aggregates / rich domain  
**Companions:** optional `event-driven.md` for integration vs domain events

---

## Building blocks

| Pattern | Role |
|---------|------|
| **Bounded context** | Explicit model boundary and ubiquitous language |
| **Aggregate** | Consistency boundary; root enforces invariants |
| **Entity** | Identity + lifecycle inside or as aggregate root |
| **Value object** | Immutable measure/descriptor; equality by value |
| **Domain event** | Something that happened in the domain (past tense) |
| **Repository** | Persistence abstraction for aggregate roots (port) |
| **Domain service** | Domain logic that does not naturally sit on one entity |

---

## MUST

- Protect invariants **inside** the aggregate root; do not allow external code to bypass the root.
- Model value objects for concepts without identity (money, date ranges, identifiers-as-values when appropriate).
- Keep the **ubiquitous language** consistent in type and method names within a bounded context.
- Define repositories as ports over **aggregates**, not over arbitrary tables or DTOs.
- Publish domain events for meaningful state changes other contexts/processes must react to — names in past tense.
- Prefer small aggregates; redesign boundaries when transactional scope grows too wide.

---

## MUST NOT

- Treat every database table as an aggregate or entity by default.
- Anemic domain: public setters everywhere with all rules in application “managers.”
- Reference stack libraries (no mediator packages, Spring Data specifics, ORM attributes-as-architecture).
- Share one giant model across unrelated bounded contexts without translation.
- Use domain events as a substitute for in-process method calls inside the same aggregate without reason.
- Load this file alone as the primary folder style — pair with concentric (or repo equivalent).

---

## Prefer when matching repo

- Aggregates and VOs already present → extend those patterns; do not invent a parallel model.
- Concentric rings exist → place tactical types in Domain / core; application orchestrates.
- VSA brownfield with a thin shared domain → keep slices; apply tactical patterns only where aggregates already live.
- Integration across contexts → clarify domain events vs integration events; see `event-driven.md`.
- CRUD-only modules → do not force aggregates; YAGNI — re-check A’s decision table.

---

## Aggregate rules (practical)

1. Modify state through the **root** only.
2. One transaction **per** aggregate when possible.
3. Reference other aggregates by **id**, not by holding full graphs.
4. Invariants that span aggregates → eventual consistency or a redesign of boundaries — not a silent distributed lock.

---

## Domain vs integration events

| Kind | Use |
|------|-----|
| Domain event | Inside the model / same process boundary; expresses domain fact |
| Integration event | Across processes/contexts; stable contract — see `event-driven.md` |

Do not conflate the two without an explicit mapping at the boundary.

---

## Review checklist

- [ ] Invariants enforced on the aggregate root
- [ ] No ORM/UI types leaking into domain tactical types
- [ ] Repository ports scoped to aggregates
- [ ] Language matches the bounded context glossary

---

## References

- [Martin Fowler — Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [Microsoft Learn — Domain-driven design](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/ddd-oriented-microservice)
- [Vaughn Vernon — Effective Aggregate Design (info summary)](https://www.dddcommunity.org/library/vernon_2011/)

**Version:** 1.0 (agent-dev-toolkit)
