---
name: repair-dotnet-build
description: Diagnose and fix failing dotnet build or test runs. Local first; optional pasted CI logs. Use when fixing a build or invoking /repair-dotnet-build.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/guardrails.mdc`
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

# Skill: repair-dotnet-build

## Trigger

Invoke when the user asks for: `/repair-dotnet-build`, `fix build`, `/repair-dotnet-build`, or when build/test failures block progress.

**Arguments (optional):**

| Input | Meaning |
|-------|---------|
| (none) | Run local `dotnet build` / `dotnet test` in the open workspace |
| Pasted log | Analyze the log text the user provides |
| Pasted CI log | User pastes a failed workflow / pipeline log for analysis |

Do not require an external CI build ID or any PAT.

## Outcome

Structured diagnosis, proposed fixes with rationale, fixes applied only after user confirmation, local re-validation, then handoff to `/commit` if the user wants to commit.

## Lazy-load

| When | Path |
|------|------|
| Locale / timezone / Bogus heuristics | `skills/repair-dotnet-build/reference.md` or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/repair-dotnet-build/reference.md` after sync |
| C# patterns | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Commit | `/commit` |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace

Confirm **target repository** (`.sln` or test projects). Summarize failure source: local run or pasted CI log.

### 1. Collect failure evidence

**Local (default):**

```bash
dotnet build
dotnet test --no-build
```

Capture errors: file, line, test name, expected vs actual.

**Pasted log:** extract compile errors, restore failures, and test failures (`[FAIL]`, `Error Message`, `Expected`/`Actual`).

**CI log (optional):** if the user pastes a GitHub Actions (or other CI) log, parse failed steps the same way as pasted local logs. Do not fetch remote CI via CLI or API - ask for a paste when remote logs are needed.

### 2. Structured diagnosis

Present:

```
## Build diagnosis

**Source:** local | pasted log | GitHub Actions
**Branch:** <current branch>
**Failures:** N

### Items
1. [<category>] <summary> - <file>:<line> or <test name>
...
```

Categories: compile, restore/NuGet, test assertion, configuration, pipeline config (YAML only if user supplied log).

### 3. Root-cause investigation

For each item, Read/Grep the codebase. Apply heuristics in `reference.md` section Common causes (culture, timezone, Bogus seed, fixture order, glob in CI YAML).

Load `csharp-patterns.md` only when editing production or test code.

### 4. Propose fixes

List each change: file, problem, cause, proposed fix. **Wait for user confirmation** before Edit/Write.

### 5. Apply and validate

After approval, apply minimal diffs. Re-run:

```bash
dotnet build
dotnet test --no-build
```

Or scoped test filter when the repo is large (see `reference.md` section Scoped test).

### 6. Handoff

When build and targeted tests pass, offer:

```
/commit
```

Do not auto-commit. Do not push unless the user asks via commit skill or explicitly.

## Must not

- External ALM/tracker REST, PATs, or org-specific credential stores
- Mandatory external CI API - local reproduction is enough
- Auto-commit or auto-push
- Corporate agent pool names or private feed assumptions without repo evidence

## Handoff

| Situation | Next |
|-----------|------|
| Commit on valid branch | `/commit` |
| New EF migration needed | `/ef-add-migration` |
| Large feature scope | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
