# Modulith / vertical slice — Java (overlay C)

Spring Modulith is the **VSA-shaped** modular monolith approach on Java. Load **only** when ARCH declares vertical-slice / modulith (or brownfield already uses Spring Modulith).

> **Principles (WHAT):** `../../code-guidelines/principles/architecture/vertical-slice.md` — do not duplicate that essay.  
> **Selection (WHEN):** `../../code-guidelines/principles/architecture-selection.md`  
> **Boundaries:** `../architecture-boundaries.md` · **Classic layers:** `../layered-structure.md`

---

## MUST

- Treat each application module as a vertical capability boundary: public API package vs internal implementation.
- Respect Modulith allowed dependencies / `@ApplicationModule` (or equivalent) already configured — do not open new cross-module couplings casually.
- Prefer module events (or the project’s integration mechanism) for cross-module collaboration instead of reach-through to another module’s persistence.
- Colocate use-case types that change together (web DTO, application service, persistence for that feature) inside the owning module.
- Mirror neighbor module layout (package-by-feature vs package-by-layer **inside** a module).
- Keep HTTP controllers thin; business orchestration stays in application/services inside the module.

### Typical module sketch

```
com.example.app/
├── order/                 # ApplicationModule
│   ├── package-info.java  # @ApplicationModule
│   ├── api/               # public types other modules may use
│   ├── internal/
│   │   ├── web/
│   │   ├── application/
│   │   └── persistence/
│   └── OrderModuleEvents.java
└── inventory/
    └── ...
```

Match exact package names and `package-info` style to the repo.

---

## MUST NOT

- Introduce Spring Modulith as a redesign of a flat layered app without ARCH + operator approval.
- Access another module’s internal packages or repositories directly when Modulith already forbids it.
- Bypass module events with shared mutable statics or a “common” god service for cross-module writes.
- Force Axon / full event-sourcing when Modulith application events already suffice for the change.
- Default to VSA/Modulith silently when ARCH omits style — discover-first / confirm-first.
- Duplicate principles B content here — pointer only.

---

## Prefer when matching repo

| Concern | Prefer |
|---------|--------|
| Module verification | Existing Modulith verifier / documented module model |
| Slice tests | **`@ApplicationModuleTest`** (or project equivalent) beside neighbor module tests |
| Structural rules | **ArchUnit** module/layer rules when already present — extend, do not fork style |
| Cross-module API | Published types in `api` / named allowed dependency |
| Persistence | One module owns its tables; no foreign-module join shortcuts |
| Hybrid | Modulith modules + classic layers inside each module when brownfield already does that |

### Testing

- Prefer `@ApplicationModuleTest` for module-scoped Spring context over full `@SpringBootTest` when the suite already uses it.
- Integration tests that cross modules should assert event publication/handling the way neighbors do.
- Shared fixtures stay in test-support packages — do not duplicate arrange blocks per module test.

### ArchUnit (when present)

Extend existing rules for `..internal..` visibility and forbidden dependencies; copy package patterns from the nearest `ArchitectureTest`.

---

## Related guidelines

- Clean/hexagonal host: `clean-hexagonal.md`
- DDD inside modules: `ddd-tactical.md`
- Cross-module / async events: `event-driven.md`
- Security / config: `../security-basics.md`, `../configuration.md`

---

## References

- [Spring Modulith reference](https://docs.spring.io/spring-modulith/reference/)
- [Spring Modulith — Testing](https://docs.spring.io/spring-modulith/reference/testing.html)
- [ArchUnit user guide](https://www.archunit.org/userguide/html/000_Index.html)
- [Vertical Slice Architecture overview](https://www.jimmybogard.com/vertical-slice-architecture/)
