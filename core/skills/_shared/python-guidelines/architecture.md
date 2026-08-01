# Python architecture hub — HOW overlay

> **Layer C (HOW).** Maps architecture styles onto FastAPI / Flask project layout. Load principles **B** (WHAT) from `../code-guidelines/principles/architecture/` — do **not** copy or restate those essays here.
>
> **One-style load:** when ARCH declares a style, load **only** that style’s B file (+ this hub for layout mapping). Never glob `principles/architecture/**` or invent a second style mid-feature.

---

## Role

Bridge stack-agnostic principles (CA / VSA / DDD / EDA) to Python package trees used with FastAPI or Flask. Framework-specific defaults stay in `fastapi.md` and `flask.md`.

---

## MUST

- Discover the repo’s existing layout first (brownfield) or follow ARCH after greenfield confirm (see architecture-selection).
- Keep HTTP adapters (routers / blueprints / views) thin; put rules in services / domain / use-cases matching the tree.
- Treat Pydantic / Marshmallow / WTForms models at the edge as transport contracts — not as the only domain model when the project separates them.
- Inject shared resources (DB session, settings, auth) via the project’s DI pattern (`Depends()`, Flask extensions, factories) — do not open connections ad hoc in every handler.
- Load **one** principles B style file named by ARCH; then apply the matching layout row below.
- Keep identifiers, comments, and logs in **English**.

| Style (ARCH) | Principles B | FastAPI / Flask layout habit |
|--------------|--------------|------------------------------|
| concentric / clean / onion / hexagonal | `../code-guidelines/principles/architecture/concentric-dependency.md` | `domain/` + `application/` inward; `api/` or `adapters/` (routers/blueprints, repositories) outward |
| vertical-slice / VSA | `../code-guidelines/principles/architecture/vertical-slice.md` | Feature packages (`features/<name>/`) with router + service + tests colocated |
| ddd-tactical | `../code-guidelines/principles/architecture/ddd-tactical.md` | Bounded-context packages; aggregates in domain; application services orchestrate |
| event-driven / EDA | `../code-guidelines/principles/architecture/event-driven.md` | Producers/consumers or outbox modules at the adapter edge; handlers idempotent |

---

## MUST NOT

- Force Clean Architecture folders onto a flat Flask blueprint app (or VSA onto a concentric tree) without explicit approval.
- Treat FastAPI or Flask as mandatory for a given style — frameworks are **Prefer when matching**, not principles.
- Glob-load every architecture principle or invent MediatR/Axon-style buses in Python without a repo pattern.
- Put ORM models or `Request` / Flask `g` types deep in domain when neighbors already isolate them.
- Duplicate layer-B essays into this hub or into `fastapi.md` / `flask.md`.
- Add a second web framework to satisfy an architecture diagram.

---

## Prefer when matching repo

### Concentric (CA / onion / hexagonal)

- Prefer packages `domain`, `application`, `infrastructure`, `api` (names may vary) when that tree exists.
- Prefer ports as Protocol / ABC in domain or application; implementations under infrastructure.
- Prefer FastAPI `APIRouter` or Flask blueprints as **inbound adapters** only.

### Vertical slice

- Prefer `features/<slice>/` (or equivalent) with router + use-case + schema together when VSA is already the layout.
- Prefer shared kernel only for auth, DB engines, and logging — not for feature business rules.

### DDD tactical

- Prefer ubiquitous-language module names matching the bounded context already in the repo.
- Prefer aggregate roots and domain events only when neighbors already model them that way.

### Event-driven

- Prefer the existing broker / worker / outbox modules; publish after successful commit when transactional outbox is present.
- Prefer idempotent consumers with the project’s ack/retry pattern.

### Framework adapters

- FastAPI: see `fastapi.md` — DI via `Depends()`, routers as adapters.
- Flask: see `flask.md` — blueprints as adapters, app factory as composition root.

---

## Thin HOW checklist

1. Read ARCH style (or discover from folder layout if ARCH omits it).
2. Load **one** matching file under `../code-guidelines/principles/architecture/`.
3. Map new code onto the existing package tree (table above).
4. Keep routers/blueprints thin; services/domain own rules.
5. Tests: domain/unit without ASGI/WSGI when possible; API tests via FastAPI/Flask clients (`pytest.md`).

---

## Related guidelines

- Selection gate (A): `../code-guidelines/principles/architecture-selection.md`
- Principles B index: `../code-guidelines/principles/architecture/README.md`
- FastAPI defaults: `fastapi.md`
- Flask defaults: `flask.md`
- Typing / async: `typing.md`, `async-pitfalls.md`

---

## References

- [FastAPI — Bigger Applications](https://fastapi.tiangolo.com/tutorial/bigger-applications/)
- [Flask — Application Factories](https://flask.palletsprojects.com/en/stable/patterns/appfactories/)
- [Flask — Blueprints](https://flask.palletsprojects.com/en/stable/blueprints/)
- [Microsoft — Clean Architecture](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
