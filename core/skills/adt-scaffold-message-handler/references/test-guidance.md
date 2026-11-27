## Test guidance

| Level | When |
|-------|------|
| Unit | Handler logic with mocked dependencies - default |
| Integration | Repo already runs Testcontainers, in-memory bus, or shared `WebApplicationFactory` |

Test names: `Should_<Result>_When_<Condition>` per `dotnet-test-patterns.md`.

Avoid tests that only assert the consumer class exists.

---
