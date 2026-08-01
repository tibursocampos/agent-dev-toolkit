# Concentric Dependency (Clean / Onion / Hexagonal)

One **dependency rule**: source code dependencies point **inward** toward domain policy. Clean Architecture, Onion Architecture, and Hexagonal Architecture are **aliases** of this concentric model — not competing trees.

**Stack:** Cross-stack (layer B)  
**Aliases:** Clean Architecture · Onion · Ports & Adapters (Hexagonal)  
**Companions:** optional `ddd-tactical.md`; optional `event-driven.md` overlay

---

## Core idea

```
    ┌─────────────────────────────────────┐
    │  Adapters / UI / Infrastructure     │  outer — details
    │  ┌───────────────────────────────┐  │
    │  │  Application / Use cases      │  │
    │  │  ┌─────────────────────────┐  │  │
    │  │  │  Domain / Entities      │  │  │  inner — policy
    │  │  └─────────────────────────┘  │  │
    │  └───────────────────────────────┘  │
    └─────────────────────────────────────┘
```

- **Inner** circles know nothing about outer circles.
- **Outer** circles depend on inner abstractions (ports), never the reverse.
- Hexagonal “ports” = boundaries; “adapters” = outer implementations.

---

## MUST

- Keep domain (entities, value objects, domain services) free of framework and I/O imports.
- Define **ports** (interfaces / abstract contracts) in inner or application rings; implement adapters outside.
- Route use-case orchestration through application/use-case code — not through UI or persistence types.
- Preserve the inward dependency rule when adding folders or projects.
- Prefer stable domain language over technology names in inner types.

---

## MUST NOT

- Let Domain / core reference UI, HTTP, ORM, message brokers, or cloud SDKs.
- Put business rules in controllers, handlers’ transport DTOs, or persistence entities alone.
- Prescribe stack libraries (no specific DI container, ORM, mediator, or web framework).
- Flatten all code into one “shared” bag that breaks the concentric rule.
- Treat Onion vs Clean vs Hex as three different mandatory folder layouts — map names to the repo’s existing rings.

---

## Prefer when matching repo

- Classic `Domain` / `Application` / `Infrastructure` / `API` (or Host) → keep that naming; enforce inward deps.
- `Core` + `Adapters` / `Inbound` / `Outbound` → Hexagonal naming; same rule.
- Feature folders **inside** Application while Domain stays shared → allowed if dependencies still point inward.
- Rich invariants and aggregates → load `ddd-tactical.md` after this file.
- Existing messaging → add `event-driven.md` as overlay; do not replace concentric folders.

---

## Rings (conceptual — map to repo names)

| Ring | Responsibility |
|------|----------------|
| Domain / Entities | Business rules, invariants, domain events (definitions) |
| Application / Use cases | Orchestration, ports consumed by adapters |
| Interface adapters | API, UI, presenters, gateway shapes |
| Infrastructure / Frameworks | DB, brokers, files, third-party SDKs |

Exact folder names **must** follow the repository — do not rename brownfield rings without approval.

---

## Review checklist

- [ ] No inward import from outer → inner violated
- [ ] Domain compiles without framework packages
- [ ] New use case adds port + adapter, not domain→DB coupling
- [ ] Style matches ARCH / brownfield layout

---

## References

- [Microsoft Learn — Clean Architecture](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [Alistair Cockburn — Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
- [Jeffrey Palermo — Onion Architecture](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/)

**Version:** 1.0 (agent-dev-toolkit)
