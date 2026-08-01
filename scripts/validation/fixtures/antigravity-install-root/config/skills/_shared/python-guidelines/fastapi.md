# FastAPI defaults (Python)

> Load when the open workspace uses **FastAPI** (or greenfield API work chooses FastAPI). Flask stays in scope via `flask.md` — this skill is **not** FastAPI-only.
>
> Architecture style (CA / VSA / DDD / EDA): load `architecture.md` + **one** principles B file named by ARCH. Do not paste architecture essays here.

---

## MUST

- Prefer **FastAPI** for greenfield HTTP APIs unless the repo already uses Flask or another framework.
- Keep path operations thin; put business rules in services / domain modules matching the repo layout.
- Treat `APIRouter` modules as **inbound adapters** — map HTTP ↔ application/use-case; do not own domain rules in routers.
- Validate request and response shapes with **Pydantic** models at the API boundary (`response_model`, body/query/path models).
- Inject shared concerns (auth, DB session, settings) via `Depends()` — do not open connections or read env ad hoc inside every handler.
- Use typed settings (`pydantic-settings` or the project equivalent); fail fast on missing required config at startup.
- Register exception handlers / raise `HTTPException` consistently with neighbor routes; return stable error shapes.
- Prefer **Pydantic v2** APIs when the project already uses v2; do not mix v1/v2 patterns in new code.
- Keep identifiers, comments, and log messages in **English**.
- Cover changed routes and error paths with FastAPI `TestClient` or `httpx.ASGITransport` + pytest (`pytest.md`).
- When ARCH declares a style, follow `architecture.md` (one-style load) before inventing package trees.

| Concern | Prefer |
|---------|--------|
| Routes | `APIRouter` as adapters mounted on `FastAPI()` |
| Schemas | Pydantic `BaseModel` at the edge |
| Dependencies | `Depends()` for auth, DB, settings (composition) |
| Architecture | `architecture.md` + one principles B overlay |
| ASGI runner | `uvicorn` / project entry already in use |

---

## MUST NOT

- Add Flask (or a second web framework) alongside FastAPI without an explicit migration ask.
- Return bare `dict` payloads for new public endpoints when neighbors use Pydantic models.
- Put ORM entities or internal models directly in OpenAPI responses when the project uses dedicated response schemas.
- Scatter `os.environ[...]` reads inside path operations.
- Commit secrets, tokens, or connection strings into source or default config.
- Mark every endpoint `async` when the call graph is sync-only and the project standardizes on sync handlers (see `async-pitfalls.md`).
- Disable validation (`response_model_exclude_unset` tricks, raw `Request.json()` bypass) to “save time.”
- Force concentric / VSA / event folders when ARCH omits a style — discover and mirror the repo (`architecture.md`).
- Duplicate principles B content into routers or this file.

---

## Prefer when matching repo

- Package layout: mirror existing `routers/`, `api/`, `services/`, `schemas/`, `features/` (or equivalent) — do not invent a parallel tree. See `architecture.md` for style → layout mapping.
- DI: prefer `Depends()` callables and yield dependencies that close resources in `finally` — treat them as adapter wiring, not domain.
- Routers as adapters: prefer path ops that call application services / use-cases; keep status mapping and DTO translation at the edge.
- OpenAPI: keep `tags`, `summary`, and `response_model` consistent with neighbor routes.
- Auth: reuse existing dependency (JWT, API key, OAuth2 password flow) rather than a new scheme.
- DB: use the project’s session/dependency pattern (SQLAlchemy async/sync, Tortoise, etc.) behind ports when concentric layout is present.
- Lifespan: prefer modern lifespan handlers over deprecated `@app.on_event` when the project already migrated.
- Background work: use the project’s task queue / `BackgroundTasks` pattern already present.
- Versioning: follow existing `/api/v1` (or header) conventions; do not introduce a second versioning style.

### Project signals

- Dependencies: `fastapi`, often `uvicorn` / `starlette`
- App entry: `FastAPI()` instance, routers via `APIRouter`
- Schemas: Pydantic `BaseModel`
- Architecture hub: `architecture.md`

---

## Implementation checklist (while coding)

- [ ] Path ops thin; services / domain hold rules
- [ ] Routers act as adapters; `Depends()` for shared wiring
- [ ] Pydantic in/out; typed settings; no secrets in repo
- [ ] ARCH style → `architecture.md` + one B file (if declared)
- [ ] Tests for happy path + key error statuses
- [ ] Async only when the call graph / project standard requires it

### Status and responses

- Use precise status codes (`201` create, `204` empty, `404` missing) matching neighbors.
- Prefer `status_code` on decorators / `Response` over ad-hoc `JSONResponse` when a model fits.
- Pagination / filtering: reuse existing query-param patterns; do not invent a second page scheme in one feature.

### Dependency and lifespan notes

- Yield dependencies must close resources in `finally` (DB sessions, clients).
- Prefer app `lifespan` for pool/client startup-shutdown over scattered globals.
- Do not share mutable request-scoped state via module globals.

---

## Related guidelines

- Architecture hub (HOW): `architecture.md`
- Principles B: `../code-guidelines/principles/architecture/` (one style only)
- Selection gate (A): `../code-guidelines/principles/architecture-selection.md`
- Async pitfalls: `async-pitfalls.md`
- Tests: `pytest.md`

---

## References

- [FastAPI — First Steps](https://fastapi.tiangolo.com/tutorial/first-steps/)
- [FastAPI — Bigger Applications (routers)](https://fastapi.tiangolo.com/tutorial/bigger-applications/)
- [FastAPI — Dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/)
- [FastAPI — Handling Errors](https://fastapi.tiangolo.com/tutorial/handling-errors/)
- [Pydantic — Usage](https://docs.pydantic.dev/latest/concepts/models/)
