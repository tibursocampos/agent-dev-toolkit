# Clean / Hexagonal architecture — Java (overlay C)

Stack HOW for concentric dependency on Java/Spring. Load **only** when ARCH declares concentric / Clean / Hexagonal (or brownfield already uses ports/adapters).

> **Principles (WHAT):** `../../code-guidelines/principles/architecture/concentric-dependency.md` — do not duplicate that essay.  
> **Selection (WHEN):** `../../code-guidelines/principles/architecture-selection.md`  
> **Boundaries:** `../architecture-boundaries.md` · **Classic layers default:** `../layered-structure.md`

---

## MUST

- Keep dependency direction inward: domain/application core must not depend on web, JPA vendors, or messaging clients.
- Place inbound adapters (REST, messaging listeners) and outbound adapters (JPA, HTTP clients) outside the core; core depends on ports (interfaces), adapters implement them.
- Mirror the repo’s package names (`domain`, `application`, `port`, `adapter`, `infrastructure`, …) — do not invent a parallel tree.
- Keep controllers/adapters free of business rules; orchestration lives in application services / use cases.
- Validate at the inbound edge (`@Valid` / Bean Validation) before use-case execution.
- Before changing structure, Glob/Read a neighbor feature and copy its port/adapter shape.

### Default package sketch (greenfield concentric)

```
com.example.app/
├── domain/              # entities, value objects, domain services
├── application/         # use cases / application services
│   └── port/
│       ├── in/          # driving ports (use-case API)
│       └── out/         # driven ports (repos, clients)
├── adapter/
│   ├── in/web/          # controllers, DTOs
│   └── out/persistence/ # JPA repos, entities if separate from domain
└── config/              # Spring wiring
```

Rename folders to match the brownfield (`hexagon`, `core`, `infra`, multi-module `*-domain` / `*-app` / `*-boot`).

---

## MUST NOT

- Force ports/adapters onto a classic `web/service/persistence` app without ARCH = concentric or explicit approval.
- Let JPA entities or Spring Web types become the domain model when the project already separates them.
- Call `EntityManager` / Spring Data repositories from controllers when application services own that path.
- Add ArchUnit or jMolecules as a drive-by dependency when the build does not already use them — Prefer when matching (below).
- Duplicate principles B (onion/hex theory) in this file — link instead.
- Glob-load every `architecture/*` overlay; load this file only for the ARCH style.

---

## Prefer when matching repo

| Tooling | When |
|---------|------|
| **ArchUnit** | Prefer when the build already has ArchUnit tests — extend layer/dependency rules beside existing tests; do not invent a second suite style |
| **jMolecules** | Prefer when already on the classpath — use stereotype annotations / bytecode enhance as neighbors do |
| MapStruct / manual mappers | Match the neighbor adapter |
| Multi-module | `domain` / `application` jars without Spring Web; Boot module = adapters + config |
| Hybrid feature packages | Feature folders **inside** concentric modules are OK when brownfield already does that |

### ArchUnit sketch (only if suite exists)

```java
@AnalyzeClasses(packages = "com.example.app")
class ArchitectureTest {
  @ArchTest
  static final ArchRule domain_must_not_depend_on_adapters =
      noClasses().that().resideInAPackage("..domain..")
          .should().dependOnClassesThat().resideInAPackage("..adapter..");
}
```

Copy package strings from existing ArchUnit rules — do not hard-code a foreign package root.

---

## Related guidelines

- Modulith / VSA Java: `modulith-vertical.md`
- DDD tactical: `ddd-tactical.md`
- Event-driven: `event-driven.md`
- Spring defaults: `../spring-boot-defaults.md`

---

## References

- [Spring Boot — Structuring Your Code](https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html)
- [ArchUnit user guide](https://www.archunit.org/userguide/html/000_Index.html)
- [jMolecules](https://github.com/xmolecules/jmolecules)
- [Hexagonal Architecture (Alistair Cockburn)](https://alistair.cockburn.us/hexagonal-architecture/)
