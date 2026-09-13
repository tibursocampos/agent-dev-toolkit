# Resilience (Java / Spring)

Compact defaults for outbound I/O and critical inbound paths. Use the **project’s** resilience library or Spring patterns already on the classpath — do **not** mandate Resilience4j (or any specific vendor) when another stack is already wired.

> **Boundaries:** layer/API/cache/DB rules stay in `architecture-boundaries.md`. This file covers timeouts and failure isolation only.

---

## MUST

- Set explicit **timeouts** on new HTTP clients, DB calls, and message consumers when neighbors already configure them (connect + read/response; match units and defaults in-repo).
- Retries: only on **idempotent** or explicitly safe operations; use **backoff + jitter** when the project’s retry API supports it — never tight infinite retry loops.
- Prefer the existing circuit-breaker / bulkhead / rate-limiter registration style in the module (annotations, `Resilience4j`, Spring Retry, Fault Tolerance, gateway policies, etc.).
- Fail fast and surface a mapped error to clients; do not swallow last-resort failures after retry exhaustion.
- Keep resilience config externalized (`application*.yml` / `@ConfigurationProperties`) when the project already does.

---

## MUST NOT

- Add Resilience4j (or a second resilience stack) beside an established library without user approval.
- Retry non-idempotent POSTs/payments/side-effects unless the domain already guarantees safe replay.
- Leave unbounded thread pools or unbounded queues on new executors/listeners.
- Duplicate long vendor tutorials here — follow project docs and existing bean config.

---

## Prefer when matching repo

| Concern | Prefer |
|---------|--------|
| HTTP clients | Timeouts + retry policy on the shared `RestClient` / `WebClient` / Feign setup already used |
| Messaging | Listener ack/retry/DLQ topology already configured — see `architecture/event-driven.md` |
| Isolation | Circuit breaker or bulkhead only where neighbors protect the same dependency |
| Observability | Emit metrics/logs the ops stack already scrapes on open/half-open/exhausted states |

### Minimal checklist (touched outbound call)

1. Timeout present (or inherit from shared client bean).
2. Retry: bounded, jittered when available, idempotent-safe.
3. Circuit/bulkhead: reuse module pattern if the dependency is flaky or shared.
4. On exhaustion: mapped error + no silent drop.

---

## Related guidelines

- API / cache / DB boundaries: `architecture-boundaries.md`
- Messaging DLQ / retry exhaustion ops: `architecture/event-driven.md`
- Boot clients / shutdown: `spring-boot-defaults.md`

---

## References

- [Spring Framework — RestClient](https://docs.spring.io/spring-framework/reference/integration/rest-clients.html)
- [Spring Boot — Graceful Shutdown](https://docs.spring.io/spring-boot/reference/web/graceful-shutdown.html)
