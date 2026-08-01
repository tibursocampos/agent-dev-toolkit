# Architecture Selection (Layer A — WHEN)

Decide **which** architecture style to apply before loading style details or stack overlays.

**Stack:** Cross-stack  
**Layer:** A (selection gate) → hand off to B (`architecture/`) then C (`*-guidelines`)  
**Used by:** architect agent, orchestrate-analyze, greenfield ARCH write

---

## Decision table

| Signal in problem / repo | Prefer style (B file) | Notes |
|--------------------------|----------------------|--------|
| CRUD / CRUD-heavy APIs, thin domain, feature velocity | Vertical Slice → `architecture/vertical-slice.md` | Default **proposal** for greenfield CRUD — never silent default without confirm |
| Rich domain rules, clear inward dependency needs | Concentric → `architecture/concentric-dependency.md` | CA / Onion / Hexagonal aliases (same rule) |
| Explicit aggregates, invariants, ubiquitous language | DDD tactical **inside** concentric → `architecture/ddd-tactical.md` + concentric | Load concentric first; DDD is tactical overlay on B |
| Async fan-out, integration events, eventual consistency | EDA overlay → `architecture/event-driven.md` | **Overlay**, not a folder-tree replacement |
| UI-only / SPA shell / presentation boundaries | Frontend hub → `frontend-guidelines/frontend-architecture.md` (P3) | Do not force backend CA onto UI packs |

Combine only when signals require it (e.g. concentric + DDD tactical; concentric/VSA + EDA overlay). Prefer the **smallest** set that fits YAGNI.

---

## MUST

- **Brownfield-first:** discover existing layout, ARCH, and conventions; **mirror** the established style. Do not re-select or propose a swap unless the operator asks.
- **Greenfield:** propose from the decision table, then set `needs-confirm` until the operator answers **sim**. Write final ARCH **only after** confirm.
- Apply **YAGNI:** do not add DDD tactical, EDA, or multi-style stacks “for later.”
- After selection is confirmed (or brownfield mirrored), hand off:
  1. **One** B style file under `principles/architecture/` (see `architecture/README.md`)
  2. Matching thin **C** overlay under the active stack `*-guidelines` when present
- Architect output **must** include, in order:
  1. **Boundaries** (what is in/out of the system and layers/slices)
  2. **Recommendation** (primary style + why)
  3. **≤ 2 alternatives** (or explicit “none”)
  4. **≤ 5 open questions**
  5. **`needs-confirm`** status until operator **sim** (greenfield) or N/A (brownfield mirror)

---

## MUST NOT

- Treat Vertical Slice as a silent default without greenfield confirm.
- Glob or preload `architecture/**` — load **one** style file only.
- Name stack libraries in this file or in B principles (no MediatR, Spring, Nest modules, Axon, MassTransit, etc.).
- Rewrite brownfield architecture to match a preferred template without explicit operator request.
- Emit more than 2 alternatives or more than 5 open questions in the architect deliverable.
- Skip the confirm gate on greenfield and write ARCH as final.

---

## Prefer when matching repo

- If ARCH already records a style → load that B file (+ C overlay); skip re-selection.
- If the repo is layer-based (Domain/Application/Infrastructure) → concentric; do not invent slices.
- If the repo is feature/use-case folders with minimal shared domain → vertical slice.
- If aggregates and domain events already exist → add DDD tactical on top of the mirrored base style.
- If messaging/outbox already exists → add EDA overlay; keep the primary folder style.
- UI-heavy work with thin or no backend domain → frontend-architecture hub, not full backend CA.

---

## Handoff (A → B → C)

```
A  architecture-selection.md     → WHEN / which style
B  architecture/<one-style>.md   → WHAT (stack-agnostic rules)
C  *-guidelines/...              → HOW (thin stack overlay; PASSO 4+)
```

Token rule: after A resolves a style, read **exactly one** B file (plus optional EDA or DDD tactical only when the decision table selected them). Never glob `principles/architecture/**`.

---

## References

- [Microsoft Learn — Clean Architecture](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [Alistair Cockburn — Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
- [Jimmy Bogard — Vertical Slice Architecture](https://jimmybogard.com/vertical-slice-architecture/)
- [Martin Fowler — Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)

**Version:** 1.0 (agent-dev-toolkit)
