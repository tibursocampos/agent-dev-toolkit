# REST / HTTP shape (agnostic)

Load only when reviewing or designing resource HTTP surfaces.

## Methods

| Method | Typical use |
|--------|-------------|
| `GET` | Read; safe; idempotent |
| `POST` | Create or non-idempotent action |
| `PUT` | Replace resource (idempotent) |
| `PATCH` | Partial update |
| `DELETE` | Remove (idempotent at rest) |

Prefer nouns for resources (`/orders/{id}`), not verbs (`/getOrder`). Actions that are not CRUD may use a subordinate resource or a clearly named action path — keep one convention per API.

## Status codes (common)

| Code | When |
|------|------|
| `200` | Success with body |
| `201` | Created; include `Location` when applicable |
| `204` | Success with no body |
| `400` | Malformed request / validation |
| `401` | Unauthenticated |
| `403` | Authenticated but not allowed |
| `404` | Resource missing |
| `409` | Conflict (state / uniqueness) |
| `422` | Semantically invalid (when distinct from `400`) |
| `429` | Rate limited |
| `5xx` | Server failure — no stack traces to clients |

## Content

- Prefer `application/json` unless the product already standardized otherwise.
- Use consistent pluralization and case in paths (pick kebab or lowercase plural; document once).
- Do not invent company-specific media types unless the consumer repo already defines them.
