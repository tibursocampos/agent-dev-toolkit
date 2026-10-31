---
name: repair-dotnet-build
description: Diagnose and fix failing dotnet build or test runs. Local first; optional pasted CI logs. Use when fixing a build or invoking /repair-dotnet-build.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

---

# Skill: repair-dotnet-build

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

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
| Reference index (routing only) | `skills/repair-dotnet-build/reference.md` or `{{TOOLKIT_ROOT}}/skills/repair-dotnet-build/reference.md` after sync |
| Process step detail (lazy) | `skills/repair-dotnet-build/references/<section>.md` |
| C# production patterns | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| .NET test patterns (when editing tests) | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/dotnet-test-patterns.md` |
| Structure / quality (after edits) | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/structure-and-quality.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Commit | `/commit` |

**Never by default:** do not preload all `references/*.md` or the full dotnet-guidelines tree. Load **one** `references/<section>.md` per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Process

Read `references/<section>.md` for heuristics and templates — **not** full `reference.md`.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace

Confirm **target repository** (`.sln` or test projects). Summarize failure source: local run or pasted CI log.

### 1. Collect failure evidence

**Local (default):** follow `references/local-commands.md`.

```bash
dotnet build
dotnet test --no-build
```

Capture errors: file, line, test name, expected vs actual.

**Pasted log:** extract compile errors, restore failures, and test failures (`references/pasted-ci-log.md`).

**CI log (optional):** if the user pastes a GitHub Actions (or other CI) log, parse failed steps the same way (`references/ci-logs.md`). Do not fetch remote CI via CLI or API - ask for a paste when remote logs are needed.

### 2. Structured diagnosis

Present using `references/diagnosis-template.md`:

```
## Build diagnosis

**Source:** local | pasted log | GitHub Actions
**Branch:** <current branch>
**Failures:** N

### Items
1. [<category>] <summary> - <file>:<line> or <test name>
...
```

Categories: compile, restore/NuGet, test assertion, configuration, pipeline config (YAML only if user provided log).

### 3. Root-cause investigation

For each item, Read/Grep the codebase. Apply heuristics in `references/common-causes.md` (culture, timezone, Bogus seed, fixture order, glob in CI YAML).

Load `csharp-patterns.md` only when editing production C#; load `dotnet-test-patterns.md` when editing tests.

### 4. Propose fixes

List each change: file, problem, cause, proposed fix (`references/fix-proposal.md`). **Wait for user confirmation** before Edit/Write.

### 5. Apply and validate

After approval, apply minimal diffs. After edits, self-check touched code against `structure-and-quality.md` (+ `csharp-patterns.md` when editing C#). Re-run:

```bash
dotnet build
dotnet test --no-build
```

Or scoped test filter when the repo is large (see `references/local-commands.md`).

### 6. Handoff

When build and targeted tests pass, offer `/commit` (`references/commit-handoff.md`, `references/related-skills.md`).

Do not auto-commit. Do not push unless the user asks via commit skill or explicitly.

## Must not

- External ALM/tracker REST, PATs, or org-specific credential stores
- Mandatory external CI API - local reproduction is enough
- Auto-commit or auto-push
- Corporate agent pool names or private feed assumptions without repo evidence
- One error at a time. Make the smallest change. Run `dotnet build` and `dotnet test` again until the status is explicit. Do not extend this skill to Node or Python.

## Handoff

| Situation | Next |
|-----------|------|
| Commit on valid branch | `/commit` |
| New EF migration needed | `/ef-add-migration` |
| Large feature scope | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
