# Node security basics

> Load for Express/Fastify (and Nest-when-present) HTTP APIs. Themes align with [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices) security sections. Pair with `node-backend.md` and `node-structure-errors.md`.

---

## MUST

- Enable **Helmet** (or equivalent secure headers middleware) on public HTTP apps unless the project documents a deliberate alternative.
- Configure **CORS** explicitly (allowed origins/methods/headers); do not leave `origin: true` / `*` on credentialed production APIs without review.
- Apply **rate limiting** on auth and public write endpoints (express-rate-limit, @fastify/rate-limit, API gateway — match the repo).
- Keep secrets in environment / secret managers; load via the project config module — never hardcode tokens, private keys, or connection strings.
- Validate and sanitize untrusted input at the edge (schema validation); treat query/body/headers as hostile.
- Hash passwords with a modern KDF already used by the project (argon2/bcrypt/scrypt); never store plaintext credentials.
- Run `npm audit` / `pnpm audit` / `yarn npm audit` (as used by the repo) and address high/critical findings on touched dependency trees before release.
- Log security-relevant failures without writing secrets, session tokens, or raw card/PII payloads to logs.

---

## MUST NOT

- Disable TLS verification (`rejectUnauthorized: false`) in production code paths.
- Expose stack traces or internal error details to clients in production (see central error handler).
- Commit `.env` files with real secrets; commit only `.env.example` with placeholders when that is the project pattern.
- Use `eval`, `Function()`, or unsanitized dynamic `require`/`import` on user input.
- Trust client-supplied roles/user ids without server-side authorization checks.
- Leave default framework secrets (`express-session` secret, JWT secret) as well-known placeholders in deployed envs.
- Ignore transitive CVEs on dependencies you add without documenting an accepted risk.

---

## Prefer when matching repo

| Topic | Prefer |
|-------|--------|
| Headers | `helmet()` / `@fastify/helmet` early in the middleware chain |
| Body size | Limit JSON/urlencoded body size to what neighbors use |
| Cookies | `httpOnly`, `secure`, `sameSite` appropriate to the deployment |
| JWT | Short TTL + refresh pattern the project already uses; validate `aud`/`iss` when present |
| File uploads | Allow-list MIME/extensions; store outside web root; scan size limits |
| SSRF | Allow-list outbound URLs when the app fetches user-provided URLs |
| Dependencies | Lockfile committed; prefer maintenance-active packages |

### Express sketch

```javascript
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

app.use(helmet());
app.use('/auth', rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
```

### Fastify sketch

```javascript
await app.register(import('@fastify/helmet'));
await app.register(import('@fastify/rate-limit'), { max: 100, timeWindow: '15 minutes' });
```

Match options to existing config — do not paste limits blindly.

### Secrets checklist

- [ ] No secrets in source or client bundles
- [ ] Required env vars fail fast at boot
- [ ] CI uses secret store / masked variables
- [ ] Rotate compromised credentials via project runbook

### HTTP hardening checklist

- [ ] Helmet (or equivalent) enabled on public apps
- [ ] CORS allow-list reviewed for credentialed clients
- [ ] Rate limits on auth and expensive writes
- [ ] Body size limits set
- [ ] Production responses omit stacks
- [ ] `npm audit` / equivalent reviewed for new deps

### AuthZ reminder

- Authenticate identity and **authorize** action separately.
- Enforce ownership checks in services (not only “JWT present”).
- Deny by default for new admin/debug routes.

---

## References

- [Node.js Best Practices — Security](https://github.com/goldbergyoni/nodebestpractices#6-security-best-practices)
- [Helmet](https://helmetjs.github.io/)
- [OWASP — Node.js Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Nodejs_Security_Cheat_Sheet.html)
- [npm Audit](https://docs.npmjs.com/cli/v10/commands/npm-audit)
