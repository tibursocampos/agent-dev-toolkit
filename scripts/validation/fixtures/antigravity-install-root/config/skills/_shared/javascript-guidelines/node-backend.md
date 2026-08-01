# Node backend (Express / Fastify)

> Load when the open workspace is a **Node.js HTTP API** (Express, Fastify, Nest, or similar). DOM / `html-css` guidance stays in sibling docs — this file extends `javascript-developer` for **backend**; it does not replace frontend routes.
>
> Route Node backend work through **`/javascript-developer`**. There is **no** `node-developer` skill.

---

## MUST

- Prefer the HTTP framework **already chosen** by the project (Express, Fastify, **or** Nest) — do not add a second framework without an explicit ask.
- Keep handlers / route modules thin; put business rules in services matching the repo layout (see `node-structure-errors.md`).
- Validate input at the edge (Zod, Joi, celebrate, Fastify JSON Schema / TypeBox, Nest pipes — match the repo).
- Load config from env / a typed config module; fail fast on missing required keys at startup.
- Propagate async errors to central error middleware / Fastify `setErrorHandler` / Nest filters — no unhandled promise rejections.
- Use named constants for status codes, route prefixes, and message keys when the project already does.
- Keep identifiers, comments, and logs in **English**.
- Cover changed routes and error paths with the project’s test stack (supertest / Fastify `inject`, Nest testing, Jest/Vitest/Mocha/`node:test`).
- When ARCH declares an architecture style, load **exactly one** overlay under `architecture/<style>.md` (see Architecture overlays below) — never glob `architecture/**`.

| Concern | Prefer |
|---------|--------|
| Routes | Thin handlers; services own rules |
| Input | Schema validation at the edge |
| Config | Env / typed config — no secrets in source |
| Errors | Central middleware / hooks (`node-structure-errors.md`) |
| Security | `node-security.md` (helmet, rate limit, secrets, audit) |
| Architecture | One ARCH style → one `architecture/*` overlay |

---

## MUST NOT

- Create a **`node-developer`** or **`nest-developer`** skill, folder, or guidelines pack.
- Add NestJS to a non-Nest codebase, or treat Nest as the default for greenfield Node work in this toolkit.
- Commit secrets, tokens, or private keys into source.
- Swallow errors in empty `catch` blocks.
- Use `http`/`https` ad-hoc servers when Express/Fastify/Nest app factories already exist.
- Block the event loop with sync CPU/fs work on hot request paths without offloading (worker threads / queues as the project does).
- Load every architecture overlay “just in case,” or invent concentric / VSA / EDA folders when ARCH omits a style (discover-first: mirror the repo).

---

## Nest modules vs Express / Fastify slices

| Shape | Typical markers | HOW habit |
|-------|-----------------|-----------|
| Nest modules | `@nestjs/core`, `nest-cli.json`, `@Module` | Controllers + providers per module; DI via Nest; follow existing module graph |
| Express slices | `express`, `Router`, `app.use` | Thin routers → services; mount from app factory |
| Fastify slices | `fastify`, `fastify.register` | Plugins encapsulate routes; schema at plugin edge |

When Nest deps are present: **recognize** the stack and follow the **existing Nest layout**, modules, DI, and test harness. Do **not** invent a Nest skill or Nest guidelines pack. Prefer matching Nest module patterns over Express/Fastify habits from this file when they conflict.

When Express/Fastify: prefer feature or layered folders already in the tree — do not force Nest module semantics onto plain Node apps.

---

## Architecture overlays (lazy-load)

Load principles **B** (WHAT) from `../code-guidelines/principles/architecture/` for the declared style, then the matching **C** overlay below. Pointers only — do not paste B essays into handlers.

| ARCH style (examples) | Overlay (HOW) | Principles B |
|-----------------------|---------------|--------------|
| concentric / clean / onion / hexagonal | `architecture/concentric.md` | `../code-guidelines/principles/architecture/concentric-dependency.md` |
| vertical-slice / VSA | `architecture/vertical-slice.md` | `../code-guidelines/principles/architecture/vertical-slice.md` |
| event-driven / EDA | `architecture/event-driven.md` | `../code-guidelines/principles/architecture/event-driven.md` |

Selection gate (A): `../code-guidelines/principles/architecture-selection.md`.

---

## Prefer when matching repo

### Express

- `Router` modules mounted from an app factory; `express.json()` / `urlencoded` as neighbors do.
- Error middleware with four args `(err, req, res, next)` registered after routes.
- `helmet`, CORS, and rate limit as in `node-security.md` when already used or when adding public HTTP surface.

### Fastify

- Plugins via `fastify.register`; encapsulate routes per plugin.
- Prefer Fastify schema / TypeBox validation over ad-hoc checks.
- Use `setErrorHandler` / `setNotFoundHandler` consistently.

### Nest (when matching)

- Prefer existing `@Module` boundaries, providers, and pipes — do not restructure the module graph for one feature.
- Prefer Nest CQRS, events, or ports **only when** those packages/patterns already appear in the repo (see overlays).
- Prefer Nest testing module patterns neighbors already use.

### Shared

- Colocate route registration with existing patterns (`routes/`, `plugins/`, `controllers/`, `modules/`, `features/`).
- Logging: pino / winston / project logger — structured fields, no secret values.
- Shutdown: listen for `SIGTERM` and close server/DB pools when the project already does.

### Project signals

| Signal | Typical markers |
|--------|-----------------|
| Express | deps `express`; `app.use` / `Router` |
| Fastify | deps `fastify`; `fastify.register` / plugins |
| Nest | deps `@nestjs/core`; `nest-cli.json` — recognition + match layout |

---

## Tests and npm validation

```bash
npm test
npm run build
```

Add lint/typecheck scripts only when configured (`eslint`, `tsc`, etc.).

---

## References

- [Express — Guide](https://expressjs.com/en/guide/routing.html)
- [Express — Error handling](https://expressjs.com/en/guide/error-handling.html)
- [Fastify — Getting Started](https://fastify.dev/docs/latest/Guides/Getting-Started/)
- [NestJS — Modules](https://docs.nestjs.com/modules)
- [Node.js — Best Practices (overview)](https://github.com/goldbergyoni/nodebestpractices)
