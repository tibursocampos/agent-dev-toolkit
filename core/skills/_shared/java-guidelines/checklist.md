# Java / Spring Boot delivery checklist

Use before opening a pull request. Prefer **JUnit 5**, **Mockito**, and **AssertJ** on greenfield; otherwise match the project's test stack.

Cross-stack profile (always): [`../code-guidelines/principles/structure-and-quality.md`](../code-guidelines/principles/structure-and-quality.md) — architecture vs style, source language, constants, layout.

---

## Preparation

- [ ] `AGENTS.md` / README and relevant skills reviewed
- [ ] PLAN step (if applicable) understood
- [ ] Acceptance criteria clear
- [ ] Framework default confirmed: **Spring Boot** (not Quarkus/Micronaut unless already in-repo)
- [ ] `structure-and-quality.md` loaded (index after principles cheatsheet)

---

## Branching

- [ ] Working branch: `feature/<slug>` or `feat/<id>-<slug>`
- [ ] Based on the correct default branch (`main` / `develop` / team default)

---

## Implementation

- [ ] Controllers stay thin (no business rules)
- [ ] Services own orchestration / rules appropriate to the layer
- [ ] Persistence behind repositories (or project equivalent)
- [ ] Dependency direction: web → service → persistence
- [ ] Constructor injection; no new field `@Autowired`
- [ ] DTOs at the API boundary; entities not exposed as public API (unless repo standard)
- [ ] `@Valid` / Bean Validation at the edge
- [ ] `@SpringBootApplication` main remains in root package (or project equivalent)
- [ ] Layered packages by default; hexagonal/Modulith only if already in-repo
- [ ] Config via `application*.yml` / `@ConfigurationProperties` as appropriate
- [ ] No secrets committed; no tokens in logs
- [ ] Identifiers always **English**; comments/docs **mirror** touched area (pt-BR↔pt-BR, EN↔EN) or **ask** on greenfield (user override wins) — `structure-and-quality.md` §2
- [ ] Changes follow `java-guidelines` (load files needed for the task)
- [ ] API contract / cache / query boundaries checked when touched (`architecture-boundaries.md`)
- [ ] Outbound timeouts / retry / isolation match project stack when touched (`resilience.md`)

---

## Style and build

- [ ] Naming / `Optional` / logging / Google-style enforceables per `java-style.md`
- [ ] Parent/BOM-aligned dependencies; **no version ranges**
- [ ] Wrapper used when present (`./mvnw` / `./gradlew`)
- [ ] CSRF/CORS/deny-by-default reviewed for touched security config (`security-basics.md`)

---

## Tests (new or changed behavior)

- [ ] JUnit 5 (`@Test`, `@ParameterizedTest` as needed)
- [ ] AssertJ (or project assertion library) for fluent assertions
- [ ] Mockito for isolated collaborators when unit-testing
- [ ] Names match repo style (`should_…_when_…` or equivalent)
- [ ] Unit tests for pure logic without full context when cheaper
- [ ] `@WebMvcTest` / `@DataJpaTest` for slice-scoped behavior when appropriate
- [ ] `@SpringBootTest` (or project IT base) for real multi-layer flows when needed
- [ ] Shared fixtures under a test-support package — do not duplicate arrange blocks
- [ ] Arrange / Act / Assert structure with clear comments when the repo uses them
- [ ] Contract / property-based / load tests only when risk justifies (`testing.md`)

---

## Build and CI gate

Maven:

```bash
./mvnw test
```

Gradle:

```bash
./gradlew test
```

- [ ] Targeted module tests green for changed code
- [ ] Full multi-module suite only when required or after asking on large repos
- [ ] **Portable CI gate:** run whatever SAST, coverage, OWASP dependency, and secrets scans the **repo already configures** (Maven/Gradle plugins, CI workflows, quality profiles) — do **not** add new plugins or scanners casually
- [ ] Supply-chain / license hygiene when the pipeline already scans (`build-and-bom.md`)

---

## Before PR

- [ ] Diff limited to stated acceptance (YAGNI)
- [ ] Public API / migrations documented if behavior changed
- [ ] No Quarkus/Micronaut defaults introduced by mistake
- [ ] Conventional commit message ready (via `/commit` when requested)
- [ ] Guideline paths touched: `spring-boot-defaults`, `layered-structure`, `architecture-boundaries`, `resilience`, `java-style`, `build-and-bom`, `configuration`, `testing`, `security-basics` as applicable

---

## References

- [Spring Boot — Testing](https://docs.spring.io/spring-boot/reference/testing/index.html)
- [Spring Boot — Structuring Your Code](https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html)
- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- Cross-stack: [`structure-and-quality.md`](../code-guidelines/principles/structure-and-quality.md)
