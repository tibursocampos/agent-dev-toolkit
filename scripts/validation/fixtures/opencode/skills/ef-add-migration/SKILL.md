---
name: ef-add-migration
description: Add an EF Core migration in the open workspace. Discovers startup project, DbContext, and migrations folder. Use when adding a migration or invoking /ef-add-migration.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/rules/guardrails.md`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: ef-add-migration

## Trigger

Invoke when the user asks for: `/ef-add-migration`, `add migration`, `/ef-add-migration`, or when a PLAN step requires a new EF Core migration.

Optional argument: migration name in **PascalCase**. If omitted, infer from pending model changes and confirm with the user.

## Outcome

A new EF Core migration in the **target workspace** (not this toolkit repo unless that repo has a `DbContext`). User sees detected projects, final migration name, and created file paths.

## Lazy-load

| When | Path |
|------|------|
| EF tool install / version notes | `skills/ef-add-migration/reference.md` (this repo) or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/skills/ef-add-migration/reference.md` after sync |
| .NET layering | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/skills/_shared/dotnet-guidelines/clean-architecture.md` |

## Process

### 0. Workspace

Confirm the **target .NET repository** (`.sln` or `*.csproj` with `DbContext`). If the workspace is the toolkit only, stop and ask which repo to open.

### 1. Discover project layout

Use **Glob** and **Grep** (not hardcoded paths). Full checklist: `reference.md` section Discovery.

Summarize before running `dotnet ef`:

| Setting | Detected value |
|---------|----------------|
| Solution root | path to `.sln` or repo root |
| Startup project | API/Host/Web/Worker with `Program.cs` |
| Target project | `.csproj` containing `DbContext` |
| DbContext class | e.g. `ApplicationDbContext` |
| Migrations folder | existing `Migrations/` or default under target |

If any value is ambiguous, ask the user once.

### 2. Migration name

- **Name provided:** normalize to PascalCase.
- **Name omitted:** inspect `git diff` / `git status`, infer from entity/schema changes (see `reference.md` section Naming), present suggestion, wait for confirmation.

### 3. Ensure `dotnet-ef`

```bash
dotnet ef --version
```

If missing, follow `reference.md` section EF tool (global or local tool-path; no fixed version in this skill body).

### 4. Add migration

From solution root:

```bash
dotnet ef migrations add <MigrationName> -s <StartupProject> -p <TargetProject> -c <DbContext>
```

Use `./dotnet-ef` instead of `dotnet ef` when a repo-local tool is documented in `reference.md` or repo README.

### 5. Verify and summarize

Confirm new `*.cs` + `*.Designer.cs` and updated `*ModelSnapshot.cs` under the migrations folder. Optionally note how to apply locally (`database update` - details in `reference.md`).

## Must not

- Hardcode EF tool package versions in `SKILL.md` (use `reference.md`)
- Assume corporate feeds or organization-specific URLs
- Run migrations against production without explicit user request
- Modify this toolkit repo when the user intended a consumer repo

## Handoff

| Situation | Next |
|-----------|------|
| PLAN step with EF | Continue `/sdd-develop - <full-plan-path> - Step N` (path from implement handoff; SDD locations per `STORAGE.md`) |
| Build/test failures after migration | `/repair-dotnet-build` |
| Commit | `/commit` |
