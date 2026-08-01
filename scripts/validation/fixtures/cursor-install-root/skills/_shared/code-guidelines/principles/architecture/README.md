# Architecture Styles (Layer B — WHAT)

Stack-agnostic architecture **styles**. Selection happens in layer A (`../architecture-selection.md`). Stack HOW lives in layer C (`*-guidelines`).

**Stack:** Cross-stack  
**Purpose:** Define dependency and cohesion rules without framework lock-in

---

## Token discipline (mandatory)

| Rule | Detail |
|------|--------|
| **Load ONE style** | After A selects a style, read **exactly one** primary file from this folder |
| **Never glob** | Do **not** glob `architecture/**` or preload every style |
| **Optional companions** | Load `ddd-tactical.md` and/or `event-driven.md` **only** when A’s decision table selected them |
| **No stack libs** | These files must not prescribe MediatR, Spring, Nest, Axon, EF, etc. |

Paths after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/code-guidelines/principles/architecture/`

---

## Files in this folder

| File | Style | Load when |
|------|-------|-----------|
| [concentric-dependency.md](./concentric-dependency.md) | Clean / Onion / Hexagonal (aliases) | Rich domain, inward dependency rule |
| [vertical-slice.md](./vertical-slice.md) | Vertical Slice (VSA) | Feature / use-case cohesion, CRUD-heavy |
| [ddd-tactical.md](./ddd-tactical.md) | DDD tactical patterns | Aggregates, VOs, domain events (with concentric) |
| [event-driven.md](./event-driven.md) | Event-driven overlay | Async fan-out, outbox, eventual consistency |

This `README.md` is an index only — do not treat it as a substitute for the selected style file.

---

## MUST

- Resolve the style via `architecture-selection.md` (or existing ARCH) before opening a style file.
- Open **one** primary style file for the task.
- Keep B content stack-agnostic: ports, boundaries, and patterns — not package names.
- Prefer matching the repo’s existing folder shape when brownfield.

---

## MUST NOT

- Glob or recursively read `architecture/**`.
- Load all four style files “just in case.”
- Copy layer C library choices into these principles.
- Use VSA as an implicit default without A + confirm on greenfield.

---

## Prefer when matching repo

- ARCH names a style → open that file only.
- Unsure which companion applies → re-check A’s decision table; do not guess-load both DDD and EDA.
- Frontend-only → use `frontend-guidelines/frontend-architecture.md` (not this folder’s backend styles).

---

## How to load (agents)

```
1. architecture-selection.md          # WHEN (or skip if ARCH already set)
2. architecture/<one-primary>.md      # WHAT
3. optional: ddd-tactical.md          # only if selected
4. optional: event-driven.md          # only if selected
5. stack *-guidelines overlay         # HOW (layer C)
```

---

## References

- [Microsoft Learn — Common web application architectures](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [Alistair Cockburn — Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
- [Jimmy Bogard — Vertical Slice Architecture](https://jimmybogard.com/vertical-slice-architecture/)

**Version:** 1.0 (agent-dev-toolkit)
