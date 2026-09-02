# Naming and resource contracts (agnostic)

Load when naming resources, fields, or documenting public contracts.

## Resources and fields

- Resource paths: plural nouns, consistent case (`/users/{userId}/orders`).
- JSON fields: one casing convention project-wide (`camelCase` or `snake_case`).
- Identifiers: opaque strings or UUIDs preferred over sequential ints when exposure matters.
- Booleans: affirmative names (`isActive`, not `isNotDisabled`).
- Timestamps: ISO-8601 UTC (`YYYY-MM-DDTHH:mm:ssZ`) unless the repo already chose otherwise.

## Contracts vs branding

- Public schemas describe **resources and fields**, not company marketing names.
- Do not paste proprietary partner WSDLs, internal ticket ids, or branded error catalogs into toolkit Core.
- When the consumer repo has local standards under `docs/` or `AGENTS.md`, prefer those over inventing new ones.

## OpenAPI hygiene (pointer only)

- Keep operationIds unique and stable.
- Document auth schemes without embedding real credentials.
- For generating typed clients from a finished schema, hand off to `api-integrate` — this skill does not generate clients.
