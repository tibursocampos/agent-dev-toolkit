# Errors and pagination (agnostic)

Load when shaping error envelopes or list endpoints.

## Error envelope (generic)

Prefer a stable JSON shape, for example:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Human-readable summary",
    "details": []
  }
}
```

Rules:

- `code` is a stable, lowercase, snake_or_kebab machine id — **not** a company product name.
- `message` is safe for clients (no secrets, no internal hostnames).
- `details` optional field-level issues (`field`, `reason`).
- Do not return stack traces, SQL, or file paths to clients.

## Pagination

Pick one style per API and stick to it:

| Style | Typical fields |
|-------|----------------|
| Offset | `limit`, `offset` (or `page`/`pageSize`) |
| Cursor | `cursor`, `limit`, `nextCursor` |

Include totals only when cheap; otherwise omit or provide an estimate flag. Keep sort stable when paging.

## Idempotency

For create-like `POST`s that may retry, support an idempotency key header when the domain needs it. Document retention window; do not hardcode vendor header names unless the repo already standardized them.
