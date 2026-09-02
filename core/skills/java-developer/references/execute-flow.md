# java-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm target repo (`pom.xml` and/or Gradle `build.gradle` / `build.gradle.kts` / `settings.gradle*`). Read `AGENTS.md` / `README.md`. Default framework: **Spring Boot** unless the project clearly uses another stack (do not invent Quarkus/Micronaut as defaults). Summarize the user request and acceptance.

### 1. Guidelines (step 0.5)

Follow `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md`: load only the `java-guidelines` files needed for this task. Confirm test stack aligned to the project (prefer **JUnit 5**, **Mockito**, **AssertJ** when greenfield).

### 2. Branch (step 3)

Baseline branch from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>` - never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

List 3-7 concrete tasks (files to touch, tests to add). Stay within one session when possible; checkpoint per `context-management.mdc` (>= 40% -> pause, offer `/commit`).

### 4. Implement

Match existing project patterns (Glob/Read similar types first). Prefer Spring Boot idioms: controllers/REST, services, repositories, DTOs, validation.

| Layer | Typical work |
|-------|----------------|
| Web | Controllers, filters, DTOs, validation |
| Service | Application services, domain rules |
| Persistence | Repositories, entities, migrations |
| Integration | Clients, messaging consumers/producers |

Apply `spring-boot-defaults.md` and `layered-structure.md` from `java-guidelines/` while writing - do not paste full bodies into chat.

### 5. Tests

Add or update tests for changed behavior. Prefer integration tests (`@SpringBootTest` / slice tests) for real flows when the project already uses them; unit tests for isolated logic.

### 6. Build and test

Maven:

```bash
./mvnw test
# or: mvn test
```

Gradle:

```bash
./gradlew test
```

Fix failures within scope. Ask before running the full multi-module suite if the repo is very large.

### 7. Pre-commit (step 3.5) and handoff

Run `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` when appropriate. Offer `/commit` - do not commit automatically.

Before push/PR, run `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` and `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/checklist.md`.

### 8. SDD escalation

If scope grows during work, stop and recommend:

```
/sdd-spec - [feature description]
# then
/sdd-plan - PRD/...
# then
/sdd-develop - PLAN/... - Step 1
```
