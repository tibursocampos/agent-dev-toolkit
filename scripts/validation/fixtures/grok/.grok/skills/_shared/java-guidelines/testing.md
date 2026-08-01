# Testing (Java / Spring Boot)

Prefer behavior-focused tests. Greenfield stack: **JUnit 5**, **Mockito**, **AssertJ**. Otherwise match the project.

---

## MUST

- Structure tests with clear **Arrange / Act / Assert** (use `// Arrange`, `// Act`, `// Assert` when the repo uses that style).
- Name tests after behavior (`should_…_when_…` or `shouldResultWhenCondition`) matching neighbors.
- Choose the **narrowest** Spring test slice that still validates the behavior:
  - **Unit**: pure logic / services with Mockito — no Spring context.
  - **`@WebMvcTest`**: web layer (controllers, advice, validation) with collaborators mocked.
  - **`@DataJpaTest`**: persistence slice (repositories, entities) with test DB.
  - **`@SpringBootTest`**: end-to-end application flows when slices are insufficient or the project standardizes on full context.
- Cover new or changed behavior; do not add tests that only bump line coverage without assertions on outcomes.
- Keep shared arrange data in test fixtures / builders / fakes under the project’s test-support package — do not duplicate large arrange blocks.
- Use `@ActiveProfiles` / `application-test.yml` as the project already does for integration tests.
- Clean up resources (Testcontainers, `@DirtiesContext` only when unavoidable and already used sparingly in-repo).
- Assert on observable results (status, payload fields, persisted state, thrown type) — not only that a mock was called, unless interaction is the behavior.

### Selection guide

| Goal | Prefer |
|------|--------|
| Pure domain / mapping logic | Unit test (no Spring) |
| HTTP contract + validation | `@WebMvcTest` |
| Queries / mappings to DB | `@DataJpaTest` |
| Multi-layer flow, security, messaging | `@SpringBootTest` (or project’s integration base) |

---

## MUST NOT

- Start `@SpringBootTest` for every trivial getter or mapper when a unit test suffices.
- Mix conflicting test frameworks in new tests (e.g. JUnit 4 + JUnit 5) when the module is on JUnit 5.
- Depend on test execution order or shared mutable static state across tests.
- Commit credentials or point integration tests at real production systems.
- Disable tests (`@Disabled`) without a tracked reason.
- Use `@MockBean` everywhere in full-context tests when a tighter slice would do — follow repo patterns.
- Sleep/flaky waits instead of deterministic fixtures or Awaitility when the project already standardizes async testing.

---

## Prefer when matching repo

- AssertJ fluent assertions over raw JUnit `assertEquals` when AssertJ is on the classpath.
- Mockito `@ExtendWith(MockitoExtension.class)` or constructor injection of mocks for unit tests.
- `@ParameterizedTest` for input matrices instead of copy-pasted methods.
- Testcontainers / embedded DB: reuse the module’s existing container fixtures.
- `@Sql` / Flyway test migrations: follow existing persistence test setup.
- WebTestClient vs MockMvc: match the stack (`web` vs `webflux`).
- Central `TestInfrastructure` / `Fixtures` / `*Fake` packages when the repo has them.
- Security tests: `@WithMockUser` / jwt post-processors as already used in the module.

### Example shapes (illustrative)

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {
  // MockMvc + @MockBean service — assert status and JSON fields
}

@DataJpaTest
class OrderRepositoryTest {
  // Assert queries against sliced EntityManager / test DB
}

@SpringBootTest
@AutoConfigureMockMvc
class OrderFlowIT {
  // Broader flow when slices cannot express the behavior
}
```

### Pyramid reminder

1. Many fast unit tests for rules and mapping.
2. Slice tests for web and persistence contracts.
3. Fewer full `@SpringBootTest` flows for critical paths.

---

## References

- [Spring Boot — Testing](https://docs.spring.io/spring-boot/reference/testing/index.html)
- [Spring Boot — @WebMvcTest](https://docs.spring.io/spring-boot/reference/testing/spring-boot-applications.html#testing-spring-boot-applications-with-mock-environment)
- [Spring Boot — @DataJpaTest](https://docs.spring.io/spring-boot/reference/testing/spring-boot-applications.html#autoconfigure-test-slice-annotations)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)
