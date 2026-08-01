# Vertical Slice Architecture (VSA)

Organize by **feature / use case**, not by technical layer as the primary axis. Each slice owns the code needed to deliver one request or use case end-to-end.

**Stack:** Cross-stack (layer B)  
**Also known as:** Feature folders, use-case cohesion  
**Companions:** optional `event-driven.md`; do not force full concentric rings unless the repo already has them

---

## Core idea

```
Features/
  CreateOrder/     # command, validation, handler, persistence touch, tests for this use case
  GetOrderById/    # query path co-located
  CancelOrder/
Shared/            # truly cross-cutting only (auth primitives, clock, errors) — keep thin
```

- High cohesion **inside** a slice; low coupling **between** slices.
- Duplication across slices is acceptable when coupling would be worse (balance with DRY at 3+ copies — see `../DRY.md`).
- Shared kernel stays small; extract shared code when a second or third slice proves the need (YAGNI).

---

## MUST

- Place request handling, validation, and use-case logic for a feature in the **same** slice boundary.
- Name slices after business capabilities / use cases, not after technical roles alone (`Controllers`, `Repositories` as top-level homes).
- Keep cross-slice dependencies explicit and rare; prefer local types inside the slice when private.
- Mirror the repository’s existing feature-folder convention when brownfield.
- Isolate side effects (persistence, messaging) behind clear boundaries **within** or at the edge of the slice — without mandating a global layer project.

---

## MUST NOT

- Force a full Clean Architecture project graph solely because VSA was selected.
- Scatter one use case across distant technical folders when the repo already uses feature folders.
- Prescribe mediators, CQRS libraries, or framework modules.
- Grow a large “Shared” / “Common” dumping ground for feature-specific code.
- Silently adopt VSA on a concentric brownfield without operator request.

---

## Prefer when matching repo

- Existing `Features/{Name}/` or `UseCases/{Name}/` → continue that shape.
- Minimal domain model and CRUD endpoints → VSA as primary style.
- Some shared entities already in a Domain project → keep them; slices may reference shared domain without inventing new rings.
- Heavy domain invariants appearing → consider concentric + DDD tactical via A’s decision table (may need confirm to change style).
- Async integration between slices/services → add `event-driven.md` overlay.

---

## Slice contents (typical)

| Element | Guidance |
|---------|----------|
| Input model | Request/command/query types local to the slice |
| Validation | Co-located with the slice input |
| Handler / interactor | Orchestrates the use case |
| Data access | Slice-local or thin port — match repo |
| Tests | Prefer tests beside or under the same feature |

Exact type names follow the stack overlay (layer C) and the repo — not this file.

---

## Review checklist

- [ ] New behavior landed in an existing or new **feature** slice, not only a technical layer
- [ ] Shared folder did not absorb feature-specific logic
- [ ] No unjustified cross-slice reach-through
- [ ] Style matches ARCH / brownfield

---

## References

- [Jimmy Bogard — Vertical Slice Architecture](https://jimmybogard.com/vertical-slice-architecture/)
- [Microsoft Learn — Common web application architectures](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [Martin Fowler — Presentation Domain Data Layering](https://martinfowler.com/bliki/PresentationDomainDataLayering.html)

**Version:** 1.0 (agent-dev-toolkit)
