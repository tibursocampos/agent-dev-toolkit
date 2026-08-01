# Node structure and error handling

> Load when adding routes, layers, or error middleware to a Node HTTP API. Complements `node-backend.md`. Match the open repo’s layout — do not invent a parallel tree.

---

## MUST

- Mirror the **existing** folder layout (feature folders, layered `routes` / `controllers` / `services` / `repositories`, or Fastify plugins).
- Keep HTTP transport (req/res mapping) out of domain/services when the project already separates them.
- Register a **central error handler** (Express four-arg middleware or Fastify `setErrorHandler`) after routes.
- Map known domain errors to stable HTTP status codes and response bodies; log unexpected errors with correlation ids when the project uses them.
- Fail **fast** on configuration: validate required env/config at startup and exit non-zero if invalid — do not serve traffic half-configured.
- Propagate errors from `async` handlers (`next(err)`, Fastify throw, or wrappers the project already uses).
- Keep error messages for clients safe (no stacks in production); keep identifiers and logs in **English**.

---

## MUST NOT

- Create a new top-level architecture (hexagonal, CQRS folders, microservices split) without an explicit ask.
- Duplicate error-handling logic in every route when a central handler exists.
- Return inconsistent error JSON shapes across neighboring endpoints.
- Catch-and-ignore (`catch (_) {}`) in handlers.
- Read `process.env.X` ad hoc deep in business logic when a config module exists.
- Throw raw strings; throw `Error` subclasses or project domain error types.

---

## Prefer when matching repo

### Layout examples (illustrative — follow the real tree)

```
# Layered
src/
  routes/          # or controllers/
  services/
  repositories/    # or data/
  middleware/
  config/
  app.js           # factory
  server.js        # listen

# Feature-based
src/
  users/
    users.routes.js
    users.service.js
    users.repository.js
  shared/
    errors.js
    config.js
```

| Style | When |
|-------|------|
| Layered by technical role | Repo already has `routes/` + `services/` |
| Feature / vertical slice | Repo groups by domain folder |
| Fastify plugins | One plugin per feature with encapsulated routes |
| Nest modules | Nest present — follow existing modules/DI only (recognition; no Nest pack) |

### Central error handler habits

| Kind | HTTP | Client body |
|------|------|-------------|
| Validation | 400 | Field errors matching project schema |
| Unauthorized / forbidden | 401 / 403 | Stable code/message keys |
| Not found | 404 | Stable not-found shape |
| Conflict / domain rule | 409 / 422 | Project domain error codes |
| Unexpected | 500 | Generic message; details only in logs |

### Fail-fast config

```javascript
// Prefer — validate once at boot
const config = loadConfig(process.env); // throws or returns Result
if (!config.ok) {
  console.error(config.error);
  process.exit(1);
}
```

- Use `zod` / `envalid` / `convict` / project helper when already present.
- Export a frozen config object; inject into services rather than re-parsing env.

### Async error propagation (Express)

```javascript
// Prefer project wrapper or Express 5 async behavior
router.get('/orders/:id', async (req, res, next) => {
  try {
    const order = await orderService.getById(req.params.id);
    res.json(order);
  } catch (err) {
    next(err);
  }
});
```

---

## References

- [Express — Error handling](https://expressjs.com/en/guide/error-handling.html)
- [Fastify — Errors](https://fastify.dev/docs/latest/Reference/Errors/)
- [Node.js Best Practices — Error handling](https://github.com/goldbergyoni/nodebestpractices#2-error-handling-practices)
- [Node.js Best Practices — Project structure](https://github.com/goldbergyoni/nodebestpractices#1-project-structure-practices)
