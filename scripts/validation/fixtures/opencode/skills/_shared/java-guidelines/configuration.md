# Configuration (Spring Boot)

Externalized, typed, profile-aware configuration without secrets in source control.

---

## MUST

- Externalize environment-specific values via `application.yml` / `application.properties` and profile-specific files (`application-{profile}.yml`).
- Prefer **`@ConfigurationProperties`** (typed, validated groups) for new configuration clusters over scattered `@Value` fields.
- Enable configuration properties scanning or register with `@EnableConfigurationProperties` / `@ConfigurationPropertiesScan` as the project already does.
- Bind secrets and credentials from environment variables, secret stores, or CI-injected config — **never** commit real secrets.
- Keep default/`application.yml` safe for local or empty placeholders only; production values come from profiles/env.
- Use consistent profile names already present in the repo (`local`, `test`, `prod`, etc.).
- Document new property keys in README/AGENTS or existing config docs when adding user-facing settings.
- Fail fast on invalid config when using `@Validated` on `@ConfigurationProperties` where the project supports it.
- Prefix custom keys with the project’s existing root namespace (`app.`, service name, etc.) — do not dump flat top-level keys.

### Typed properties sketch

```java
@ConfigurationProperties(prefix = "app.orders")
@Validated
public record OrdersProperties(
    @NotNull Duration pollInterval,
    @NotBlank String defaultCurrency
) {}
```

Register and inject the type (or `*Properties` bean) per project pattern — constructor injection into services.

---

## MUST NOT

- Commit API keys, passwords, private URLs with embedded credentials, or cloud tokens.
- Hardcode production hostnames, account IDs, or feature-flag defaults that only belong in prod.
- Invent a parallel config format (custom JSON beside Boot config) when `application.yml` is the standard.
- Use `@Value` for large groups of related keys when a properties class is clearer and the repo already uses properties types.
- Activate `prod` profile locally with production secrets for routine development.
- Log the full contents of `Environment` or property sources that may contain secrets.
- Store secrets in test resources that ship in published artifacts unless they are clearly fake fixtures.

---

## Prefer when matching repo

- YAML vs properties: match existing files; do not convert the whole tree in a feature PR.
- `spring.config.import` / optional files: follow existing patterns for shared config.
- Kubernetes/Cloud: use the project’s existing Spring Cloud / K8s config approach; do not add Spring Cloud Config client casually.
- Test profile: `application-test.yml` + `@ActiveProfiles("test")` (or project equivalent) for integration tests.
- Feature toggles: use the library or property scheme already in the repo.
- Relaxed binding: rely on Boot’s relaxed binding (`APP_ORDERS_POLL_INTERVAL` ↔ `app.orders.poll-interval`) instead of duplicating keys.
- Immutable properties types (`record` / `final` fields) when the module already uses them.

### Secrets and profiles

| Concern | Practice |
|---------|----------|
| Secrets | Env vars / secret manager; placeholders in git |
| Profiles | Explicit `--spring.profiles.active` or env; document required profiles |
| Local overrides | `application-local.yml` gitignored **only if** the repo already gitignores it |
| Multi-tenant keys | Prefix with existing namespace (`app.`, `blip.`, etc.) |
| CI | Inject secrets via pipeline variables — never paste into committed YAML |

### `@Value` vs `@ConfigurationProperties`

| Situation | Prefer |
|-----------|--------|
| One-off simple key already used as `@Value` nearby | Match neighbor |
| New group of related settings | `@ConfigurationProperties` |
| Need validation on boot | `@ConfigurationProperties` + `@Validated` |
| Nested maps/lists | `@ConfigurationProperties` |

---

## References

- [Spring Boot — Externalized Configuration](https://docs.spring.io/spring-boot/reference/features/external-config.html)
- [Spring Boot — Type-safe Configuration Properties](https://docs.spring.io/spring-boot/reference/features/external-config.html#features.external-config.typesafe-configuration-properties)
- [Spring Boot — Profiles](https://docs.spring.io/spring-boot/reference/features/profiles.html)
- [Spring Boot — Validation of Properties](https://docs.spring.io/spring-boot/reference/features/external-config.html#features.external-config.typesafe-configuration-properties.validation)
