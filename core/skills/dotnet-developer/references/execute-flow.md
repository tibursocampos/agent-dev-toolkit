# dotnet-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm target repo (`*.sln` / `*.csproj`). Read `AGENTS.md` / `README.md`. Summarize the user request and acceptance (from issue text, PRD snippet, or user description).

### 1. Guidelines (step 0.5)

Follow `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md`: load `dotnet-guidelines` files needed for this task only. Confirm test stack: **xUnit**, **Moq**, **Shouldly**, `Should_<Result>_When_<Condition>`.

### 2. Branch (step 3)

Baseline branch from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>` - never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

List 3-7 concrete tasks (files to touch, tests to add). Stay within one session when possible; checkpoint per `context-management.mdc` (>= 40% -> pause, offer `/commit`).

### 4. Implement

Match existing project patterns (Glob/Read similar types first).

| Layer | Typical work |
|-------|----------------|
| Domain | Entities, value objects, domain services |
| Application | Commands/queries, handlers, validators |
| Infrastructure | EF, repositories, external clients |
| API | Endpoints, DTOs, auth filters |

Apply the **one** ARCH-matched architecture overlay (see lazy-load table) and `csharp-patterns.md` from `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/` while writing - do not paste full bodies into chat. Never glob `architecture/**`.

### 5. Tests

Add or update tests for changed behavior. Prefer integration tests for real flows when the project already uses them; unit tests for isolated logic.

### 6. Build and test

```bash
dotnet build
dotnet test --no-build
```

Fix failures within scope. Ask before running full-solution tests if the repo is very large.

### 7. Pre-commit (step 3.5) and handoff

Run `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` when appropriate. Offer `/commit` - do not commit automatically.

Before push/PR, run `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` and `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/checklist.md`.

### 8. SDD escalation

If scope grows during work, stop and recommend:

```
/sdd-spec - [feature description]
# then
/sdd-plan - PRD/...
# then
/sdd-develop - PLAN/... - Step 1
```
