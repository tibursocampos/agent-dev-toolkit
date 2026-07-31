# Build and BOM (Maven / Gradle + Spring Boot)

Keep builds reproducible and aligned with the Spring Boot dependency management model.

---

## MUST

- Use the project’s existing build tool only (Maven **or** Gradle).
- Prefer the **Maven Wrapper** (`mvnw`) or **Gradle Wrapper** (`gradlew`) for local and CI commands when the wrapper is present.
- Import Spring Boot dependency management via `spring-boot-starter-parent` and/or `spring-boot-dependencies` BOM (Maven) or the Spring Boot Gradle plugin’s BOM — match what the repo already uses.
- Declare dependencies **without** overriding versions when the Boot BOM already manages them, unless the repo has an established exception list.
- Use **exact** versions (or the BOM-managed version) — never Maven/Gradle **version ranges** (`[1.0,2.0)`, `1.+`, `latest.release`) for application dependencies.
- Keep multi-module version alignment in the parent / BOM / version catalog the project already uses (`dependencyManagement`, Gradle version catalog, etc.).
- Run tests through the wrapper from the module or reactor root appropriate to the change.
- Keep wrapper properties (`maven-wrapper.properties` / `gradle-wrapper.properties`) consistent with what CI expects.

### Commands (prefer wrapper)

```bash
./mvnw test
./mvnw -pl <module> -am test
./gradlew test
./gradlew :module:test
```

On Windows PowerShell the same wrappers apply (`.\mvnw.cmd`, `.\gradlew.bat`) when present.

---

## MUST NOT

- Add a second build system beside the one already in the module.
- Introduce Quarkus/Micronaut BOM as the default dependency set for a Spring Boot app.
- Pin conflicting versions of Spring Framework / Jackson / Tomcat that diverge from the Boot BOM without a tracked reason.
- Commit local IDE run configurations that hardcode machine-specific JDKs as the only supported path.
- Delete or bypass the wrapper scripts/properties in normal feature work.
- Use `SNAPSHOT` dependencies from untrusted repos without the project already doing so.
- Use `latest` / dynamic versions in published library coordinates consumed by the app.

---

## Prefer when matching repo

- **Maven**: parent `spring-boot-starter-parent` or import `spring-boot-dependencies` in `dependencyManagement`.
- **Gradle**: `id("org.springframework.boot")` + `io.spring.dependency-management` or Boot’s built-in BOM support per Gradle major version used in-repo.
- Version catalogs (`gradle/libs.versions.toml`) or Maven properties: extend the catalog/properties file instead of scattering literals in submodules.
- Plugins: Spotless, Checkstyle, Surefire/Failsafe — run what CI already runs; do not invent a parallel quality gate.
- Java toolchain: match `java.version` / toolchain in parent; do not bump JDK language level in one module casually.
- Native image / AOT: only when the project already builds native or the user asks.
- Multi-module reactor: change the owning module; use `-am` / Gradle project deps so dependents still compile.

### BOM hygiene checklist

| Check | Rule |
|-------|------|
| Starter vs raw library | Prefer `spring-boot-starter-*` |
| Version on dep | Omit if BOM-managed |
| Range | Forbidden for app deps |
| Wrapper | Commit and use `mvnw` / `gradlew` |
| New plugin | Ask before adding |
| BOM conflict | Resolve via Boot-managed set first |

### Adding a dependency (procedure)

1. Confirm no existing starter already provides the API.
2. Add the coordinate without a version if Boot manages it.
3. Run a targeted compile/test via the wrapper.
4. Avoid forcing versions in `<properties>` unless aligning an entire family the repo already overrides.

See also `spring-boot-defaults.md` for starter selection and `configuration.md` for profile-related build concerns (do not bake secrets into `pom.xml` / Gradle scripts).

---

## References

- [Spring Boot — Build Systems](https://docs.spring.io/spring-boot/reference/using/build-systems.html)
- [Spring Boot — Dependency Management](https://docs.spring.io/spring-boot/reference/using/build-systems.html#using.build-systems.dependency-management)
- [Maven Wrapper](https://maven.apache.org/wrapper/)
- [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html)
