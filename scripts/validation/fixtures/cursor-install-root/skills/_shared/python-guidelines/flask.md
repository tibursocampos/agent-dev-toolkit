# Flask defaults (Python)

> Load when the open workspace uses **Flask**. FastAPI remains in scope via `fastapi.md`. Do **not** treat Python work as FastAPI-only — Flask apps stay first-class.
>
> Architecture style (CA / VSA / DDD / EDA): load `architecture.md` + **one** principles B file named by ARCH. Do not paste architecture essays here.

---

## MUST

- Prefer the **application factory** (`create_app()`) and Blueprint layout when the project already uses them.
- Keep view functions / Blueprint handlers thin; put business rules in services or domain modules.
- Treat Blueprints (and modular views) as **inbound adapters** — map HTTP ↔ application/use-case; do not own domain rules in views.
- Validate input with the schema/validation stack already in the repo (Marshmallow, WTForms, pydantic, flask-smorest, etc.).
- Centralize config via Flask config object / env loaders; fail clearly when required keys are missing.
- Register error handlers consistent with neighbors; return stable JSON (or HTML) shapes and correct status codes.
- Keep side effects (DB commits, external HTTP) out of pure helpers; keep them in services or explicit use-case functions.
- Keep identifiers, comments, and log messages in **English**.
- Cover changed routes and error paths with the Flask test client + pytest (`pytest.md`).
- When ARCH declares a style, follow `architecture.md` (one-style load) before inventing package trees.

| Concern | Prefer |
|---------|--------|
| Routes | Blueprints as adapters (or modular views matching the repo) |
| Input | Project schema / request parsing at the edge |
| Config | App config + env — no hardcoded secrets |
| Composition | App factory wires extensions / blueprints |
| Architecture | `architecture.md` + one principles B overlay |
| Errors | Registered `@app.errorhandler` / Blueprint handlers |

---

## MUST NOT

- Introduce FastAPI (or a second web framework) into a Flask codebase without an explicit migration ask.
- Put business rules and persistence commits directly in view functions when services already exist.
- Hardcode secrets, API keys, or connection strings in config modules checked into git.
- Swallow exceptions in views without logging or re-raising to the central handler.
- Force a full rewrite to async ASGI / Quart without an explicit ask.
- Add Flask extensions “just in case” that the project does not already use.
- Force concentric / VSA / event folders when ARCH omits a style — discover and mirror the repo (`architecture.md`).
- Duplicate principles B content into blueprints or this file.

---

## Prefer when matching repo

- App factory + Blueprints when present; stay with a monolith module only if that is the established style. See `architecture.md` for style → layout mapping.
- Blueprints as adapters: prefer views that call application services / use-cases; keep status mapping and DTO translation at the edge.
- Extensions (SQLAlchemy, Migrate, Marshmallow, flask-restx / flask-smorest): follow existing `init_app` wiring — treat extension bootstrap as composition root, not domain.
- URL prefixes and blueprint names: match neighbor blueprints.
- Auth: reuse existing login / token / session patterns.
- CLI (`flask` commands / Click): extend existing command groups rather than ad-hoc scripts when the repo uses them.
- Static/templates: only when the app is not API-only; match template folder conventions.
- Persistence: keep repositories / data access behind the service boundary when concentric or layered layout is present.

### Project signals

- Dependencies: `flask` (often `flask-restx`, `flask-smorest`, Blueprints, or plain views)
- App factory: `create_app()` when already used
- Extensions: SQLAlchemy, Marshmallow, etc. — follow existing wiring
- Architecture hub: `architecture.md`

---

## Implementation checklist (while coding)

- [ ] Thin handlers; services / domain own rules
- [ ] Blueprints act as adapters; factory wires composition
- [ ] Validation matches project stack
- [ ] Config from env / config object; no secrets in source
- [ ] ARCH style → `architecture.md` + one B file (if declared)
- [ ] Error handlers aligned with neighbors
- [ ] Flask test client coverage for changed routes

### Request / response habits

- Prefer `request.get_json(silent=False)` (or project helper) with explicit 400 on bad JSON when building JSON APIs.
- Use `url_for` for links when templates/redirects exist; avoid hard-coded path strings scattered across modules.
- Blueprints: set `url_prefix` once at registration; keep endpoint names stable for clients and tests.

### App context and extensions

- Access extensions via the pattern already used (`db.session`, `current_app.config`) — do not create a second global proxy.
- Push app/request context only in tests/CLI the way neighbors do (`app.test_request_context`, fixtures).
- Migrations: follow the existing Alembic/Flask-Migrate workflow; do not hand-edit production DBs in feature work.

---

## Related guidelines

- Architecture hub (HOW): `architecture.md`
- Principles B: `../code-guidelines/principles/architecture/` (one style only)
- Selection gate (A): `../code-guidelines/principles/architecture-selection.md`
- Tests: `pytest.md`

---

## References

- [Flask — Application Factories](https://flask.palletsprojects.com/en/stable/patterns/appfactories/)
- [Flask — Modular Applications with Blueprints](https://flask.palletsprojects.com/en/stable/blueprints/)
- [Flask — Handling Application Errors](https://flask.palletsprojects.com/en/stable/errorhandling/)
- [Flask — Testing](https://flask.palletsprojects.com/en/stable/testing/)
