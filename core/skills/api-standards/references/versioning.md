# API versioning (agnostic)

Load when introducing or reviewing version strategy.

## Prefer one primary strategy

| Strategy | Notes |
|----------|-------|
| URI prefix (`/v1/...`) | Explicit; easy to route; common default |
| Header (`Accept-Version` / custom) | Cleaner URLs; harder to discover |
| Content negotiation | Powerful; easy to misuse |

Do **not** mix URI + header versioning for the same surface without a documented migration plan.

## Compatibility

- Additive, non-breaking changes stay in the current major version when possible.
- Breaking changes → new major (`v2`) with a deprecation window for `v1`.
- Document sunset dates in consumer-facing docs — not as hardcoded vendor portals.

## What not to version casually

- Purely cosmetic field renames without aliases break clients — treat as breaking.
- Enum extensions are usually additive; removals are breaking.
