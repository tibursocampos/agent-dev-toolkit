# Security basics (Spring Security / web apps)

Deny-by-default habits for Spring Boot APIs and MVC apps. Match the project’s existing SecurityFilterChain.

---

## MUST

- Keep **deny-by-default** authorization: permit only explicitly public routes; authenticate everything else unless the app is intentionally open and already documented as such.
- Configure security via the component-based model (`SecurityFilterChain` bean) consistent with Spring Security 6 / Boot 3+ when that is what the project uses.
- Enable and respect **CSRF** protection for browser session/cookie auth; disable CSRF only for stateless token APIs **when the project already does** and understands the trade-off.
- Configure **CORS** explicitly (allowed origins, methods, headers) — never `*` with credentials.
- Validate and authorize on the server; never rely on UI hiding alone.
- Store passwords with the project’s password encoder (e.g. DelegatingPasswordEncoder / BCrypt); never plain text.
- Keep secrets out of git and out of logs (see `configuration.md`).
- Use HTTPS expectations in non-local profiles when the deployment already terminates TLS (forward headers / secure cookies as configured in-repo).
- Apply the same security rules to new controllers that neighbors in the same area already use (roles, scopes, path matchers).

### CSRF / CORS / auth quick rules

| Topic | Rule |
|-------|------|
| CSRF | On for cookie/session browser apps; follow existing API exception list |
| CORS | Explicit origin allow-list; no credentialed wildcard |
| Authz | `requestMatchers` / `authorizeHttpRequests` deny-by-default |
| Tokens | Bearer/JWT handling only via existing filters/resource server config |

---

## MUST NOT

- Log access tokens, refresh tokens, passwords, `Authorization` headers, or raw session IDs.
- Disable CSRF globally “to make Postman easier” on a cookie-based app without replacing with another anti-CSRF strategy.
- Use `permitAll()` on broad Ant patterns (`/**`) for convenience.
- Open CORS to all origins in production profiles.
- Commit keystores, `.pem` private keys, or `.env` files with real credentials.
- Build SQL/JPQL with string concatenation from user input — use parameters / Criteria / Spring Data bindings.
- Expose Actuator sensitive endpoints without auth when Actuator is present.
- Return stack traces or internal exception messages to clients in production profiles.

---

## Prefer when matching repo

- OAuth2 Resource Server / Login / SAML: extend the existing Security config; do not add a second filter chain style casually.
- Method security (`@PreAuthorize`): use when the project already applies it on services.
- Public health/readiness paths: only the paths the ops setup already exposes.
- Error bodies: avoid leaking stack traces or internal IDs to clients in prod profiles.
- File uploads: size limits and content-type checks as already configured.
- SSRF: do not pass raw user URLs to server-side HTTP clients without allow-lists the project defines.
- Multi-tenant apps: enforce tenant checks where existing filters/aspects already do.

### Logging redaction

```text
// Wrong
log.info("auth={}", authorizationHeader);

// Right
log.info("authenticated userId={}", userId);
```

Never print JWT payloads or API keys at INFO/DEBUG in committed code paths.

### Touching SecurityFilterChain

1. Glob/Read the existing security configuration first.
2. Add the narrowest `requestMatchers` change needed.
3. Keep CSRF/CORS decisions aligned with sibling APIs.
4. Add or update a security-focused test if the project has `SecurityMockMvcRequestPostProcessors` / `@WithMockUser` patterns.

Cross-check logging rules in `java-style.md` and secret handling in `configuration.md` whenever auth code changes.

---

## References

- [Spring Security — CSRF](https://docs.spring.io/spring-security/reference/servlet/exploits/csrf.html)
- [Spring Security — CORS](https://docs.spring.io/spring-security/reference/servlet/integrations/cors.html)
- [Spring Security — Authorization](https://docs.spring.io/spring-security/reference/servlet/authorization/authorize-http-requests.html)
- [OWASP — Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
