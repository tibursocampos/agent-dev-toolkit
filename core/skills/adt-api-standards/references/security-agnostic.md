# Security hygiene (agnostic)

Load when reviewing auth, transport, or secret handling for HTTP APIs.

## Transport and auth

- Prefer TLS for all non-local environments.
- Prefer short-lived tokens (OAuth2 / OIDC patterns) over long-lived static keys when the stack allows.
- Put secrets in configuration / secret stores — never in source, OpenAPI examples, or skill references.
- Scope tokens to least privilege; document required scopes per operation.

## Input and output

- Validate and reject unexpected fields when feasible.
- Sanitize logs: no Authorization headers, cookies, or PII dumps.
- Rate-limit public endpoints; return `429` with a clear retry hint when applicable.

## Forbidden examples

- No live API keys, JWTs, connection strings, or customer payloads in playbooks.
- No company-specific threat models copied from private runbooks — keep guidance generic.
