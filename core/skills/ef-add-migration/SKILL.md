---
name: ef-add-migration
description: Add an EF Core migration in the open workspace. Discovers startup project, DbContext, and migrations folder. Use when adding a migration or invoking /ef-add-migration.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
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
| Reference index (routing only) | `skills/ef-add-migration/reference.md` or `{{TOOLKIT_ROOT}}/skills/ef-add-migration/reference.md` after sync |
| Process step detail (lazy) | `skills/ef-add-migration/references/<section>.md` |
| .NET layering | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/clean-architecture.md` |

**Never by default:** do not preload all `references/*.md`, full EF docs, or unrelated dotnet guideline packs. Load **one** `references/<section>.md` per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Process

Read `references/<section>.md` for discovery/commands — **not** full `reference.md`.

### 0. Workspace

Confirm the **target .NET repository** (`.sln` or `*.csproj` with `DbContext`). If the workspace is the toolkit only, stop and ask which repo to open.

### 1. Discover project layout

Use **Glob** and **Grep** (not hardcoded paths). Full checklist: `references/discovery.md`.

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
- **Name omitted:** inspect `git diff` / `git status`, infer from entity/schema changes (see `references/naming.md`), present suggestion, wait for confirmation.

### 3. Ensure `dotnet-ef`

```bash
dotnet ef --version
```

If missing, follow `references/ef-tool.md` (global or local tool-path; no fixed version in this skill body).

### 4. Add migration

From solution root:

```bash
dotnet ef migrations add <MigrationName> -s <StartupProject> -p <TargetProject> -c <DbContext>
```

Use `./dotnet-ef` instead of `dotnet ef` when a repo-local tool is documented in `references/ef-tool.md` or repo README. Command details: `references/commands.md`.

### 5. Verify and summarize

Confirm new `*.cs` + `*.Designer.cs` and updated `*ModelSnapshot.cs` under the migrations folder (`references/artifacts.md`). Optionally note how to apply locally (`database update` - details in `references/commands.md`). SDD handoff: `references/sdd-cross-cut.md`.

## Must not

- Hardcode EF tool package versions in `SKILL.md` (use `references/ef-tool.md`)
- Assume corporate feeds or organization-specific URLs
- Run migrations against production without explicit user request
- Modify this toolkit repo when the user intended a consumer repo

## Handoff

| Situation | Next |
|-----------|------|
| PLAN step with EF | Continue `/sdd-develop - <full-plan-path> - Step N` (path from implement handoff; SDD locations per `STORAGE.md`) |
| Build/test failures after migration | `/repair-dotnet-build` |
| Commit | `/commit` |
