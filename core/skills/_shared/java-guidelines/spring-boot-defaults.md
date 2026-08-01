# Spring Boot defaults (Java)

> **Default stack for `/java-developer`.** Prefer Spring Boot unless the open workspace already uses another JVM framework.

---

## MUST

- Treat **Spring Boot** as the default for greenfield and ambiguous JVM repos.
- Detect the build already in the module (Maven `pom.xml` **or** Gradle `build.gradle*` / `settings.gradle*`) and keep it — never add a second build system.
- Prefer official `spring-boot-starter-*` over hand-picked transitive libraries.
- Align dependency versions with the Spring Boot **parent** / **BOM**; do not fight the BOM with ad-hoc pins unless the repo already does.
- Use **constructor injection** for Spring beans; a single constructor needs no `@Autowired` (Spring 4.3+ / Boot default).
- Keep controllers thin; put orchestration and business rules in services (or domain types the project already uses).
- Expose **DTOs** at the HTTP/API boundary; map to/from entities inside the service or mapper layer.
- Validate at the edge with Bean Validation (`@Valid` / `@Validated` + constraints) on request bodies and params.
- Place the `@SpringBootApplication` main class in the **root package** of the app so component scanning covers subpackages.
- Externalize config via `application.yml` / `application.properties` (+ profile files); prefer `@ConfigurationProperties` for new typed config groups.
- Keep identifiers, comments, and log messages in **English**.
- Prefer synchronous MVC (`spring-boot-starter-web`) unless the module is already reactive.

| Choice | Rule |
|--------|------|
| **Spring Boot** | Default for greenfield and ambiguous JVM repos |
| Quarkus / Micronaut | **Not** defaults — only when the project already depends on them |
| Plain Jakarta EE / other | Follow the existing project; do not migrate without explicit ask |

---

## MUST NOT

- Introduce Quarkus or Micronaut starters, BOM, or config as the starting point of a new feature.
- Use field `@Autowired` in new code.
- Expose JPA/Hibernate entities as the public REST/API contract unless the project already does so consistently.
- Scatter magic config keys with raw `@Value` when a typed `@ConfigurationProperties` group fits.
- Commit secrets, tokens, or environment-specific credentials into source or default config files.
- Add Actuator, OpenAPI, or messaging starters “just in case” without project need or user ask.
- Pin library versions that conflict with the Boot BOM without a documented repo reason.
- Switch a Servlet MVC module to WebFlux (or the reverse) inside a small feature PR.

---

## Prefer when matching repo

- Web: `spring-boot-starter-web` (or `webflux` only if the module is already reactive).
- Persistence: `spring-boot-starter-data-jpa` (or the data starter already in use: JDBC, Mongo, etc.).
- Validation: `spring-boot-starter-validation`.
- Tests: `spring-boot-starter-test` (JUnit 5, Mockito, AssertJ, Spring Test).
- Packaging: Boot executable jar (`spring-boot-maven-plugin` / Gradle `bootJar`).
- Local run: `./mvnw spring-boot:run` or `./gradlew bootRun` (or the repo’s documented command).
- Profiles: reuse existing names (`local`, `test`, `prod`, etc.); do not invent a parallel profile scheme.
- MapStruct / manual mappers: follow the neighbor feature’s mapping style.
- Transaction boundaries: use `@Transactional` where the project already applies it on services.
- Exception handling: extend existing `@ControllerAdvice` / problem-details types.
- OpenAPI: only when `springdoc` (or equivalent) is already a dependency.

---

## Project signals

- Maven: `spring-boot-starter-*` or parent `spring-boot-starter-parent`
- Gradle: `org.springframework.boot` plugin / dependencies
- Entry: `@SpringBootApplication` main class

If signals conflict (e.g. both Boot and another framework on the classpath), follow the module that owns the feature and ask before adding starters.

---

## Out of scope for this pack

- Quarkus / Micronaut how-tos
- Full Clean Architecture redesign of an existing Spring monolith
- Corporate CI/CD pipelines (use project docs)

---

## References

- [Spring Boot — Structuring Your Code](https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html)
- [Spring Boot — Externalized Configuration](https://docs.spring.io/spring-boot/reference/features/external-config.html)
- [Spring Boot — Build Systems](https://docs.spring.io/spring-boot/reference/using/build-systems.html)
- [Spring Framework — Dependency Injection](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-collaborators.html)
