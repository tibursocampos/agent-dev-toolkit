# Java style (toolkit defaults)

Actionable language and logging rules for Java / Spring Boot work. Prefer repo Checkstyle/Spotless/EditorConfig when present.

---

## MUST

- Use **English** for type names, methods, variables, comments, and log messages.
- Name types clearly: `OrderService`, `CreateOrderRequest`, `OrderEntity` / `Order` per project convention — avoid `Helper`, `Utils`, `Manager`, `GenericService` without a precise meaning.
- Prefer `final` fields for injected dependencies; assign only in the constructor.
- Use `Optional<T>` as a **return type** for “may be absent” from dedicated lookup methods; unwrap at the boundary with explicit empty handling.
- Prefer immutable request/response DTOs where practical (`record` on Java 16+ when the project already uses records).
- Log via SLF4J (`LoggerFactory.getLogger`) or the project’s façade; use parameterized messages (`log.debug("id={}", id)`).
- Guard clauses first: reject invalid input early; avoid deep nested `if` blocks.
- Keep methods focused; extract private helpers instead of monolithic methods.
- Match existing visibility and package-private habits in the module.
- Prefer composition over deep inheritance for new types; extend framework base classes only when the project already does.

### Naming quick reference

| Kind | Convention |
|------|------------|
| Class / record | `PascalCase` |
| Method / field | `camelCase` |
| Constant | Match neighbors (`UPPER_SNAKE` for `static final` if that is the repo style) |
| Package | reverse-DNS, lowercase |
| Test method | `should_when` or `shouldResultWhen` matching repo |

---

## MUST NOT

- Use field injection (`@Autowired` on fields) in new code.
- Use `Optional` as a method **parameter** or field type for general API design.
- Call `Optional.get()` without a prior `isPresent` / prefer `orElse`, `orElseGet`, `orElseThrow`.
- Log secrets, tokens, passwords, full auth headers, or PII beyond what the project’s logging policy allows (see `security-basics.md`).
- Use `System.out` / `System.err` for application logging.
- Swallow exceptions with empty `catch` or log-and-ignore without a documented reason.
- Add wildcard imports when the project forbids them (follow Checkstyle/Spotless).
- Use raw types (`List` without `<T>`) in new code.

---

## Prefer when matching repo

- **Records** for DTOs if the codebase already uses them; otherwise classic immutable POJOs / Lombok as already adopted.
- Lombok: only if the module already depends on it — do not introduce Lombok into a Lombok-free module without ask.
- Nullability: honor JetBrains / JSpecify / Spring null-safety annotations if already in use.
- Streams vs loops: match local style; prefer clarity over clever collectors.
- Equals/hashCode: for entities follow the project’s ID-based equality pattern; for DTOs prefer records or explicit implementations already used.
- Time: `java.time` (`Instant`, `OffsetDateTime`) — avoid new `Date` / `Calendar` usage.
- Collections: return unmodifiable views or copies at API boundaries when the project does.
- Checked exceptions: wrap or translate at boundaries if the project uses unchecked domain errors.

### Logging levels (typical)

| Level | Use |
|-------|-----|
| ERROR | Failure requiring attention; include correlation id if the app has one |
| WARN | Degraded but handled path |
| INFO | Significant lifecycle / business milestones (sparse) |
| DEBUG/TRACE | Diagnostic detail; never tokens |

### Optional patterns

```java
// Prefer return Optional from find-style methods
public Optional<Order> findById(UUID id) { ... }

// Prefer orElseThrow at the service edge
Order order = repository.findById(id)
    .orElseThrow(() -> new EntityNotFoundException(...));

// Avoid Optional parameters
void process(Optional<String> maybeCode) { } // do not
```

---

## References

- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- [SLF4J — Manual](https://www.slf4j.org/manual.html)
- [Oracle — Optional](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Optional.html)
- [Spring Boot — Logging](https://docs.spring.io/spring-boot/reference/features/logging.html)
