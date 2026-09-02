---
name: refactor
description: Analyze complexity and smells, draft a safe refactor plan, and execute step-by-step with tests. Use when refactoring code or invoking /refactor.
---


## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
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

# Skill: refactor

## Trigger

Invoke when the user requests: `/refactor`, `refactor code`, `/refactor`, or when code reviews indicate high complexity.

**Arguments (optional):**

| Input | Meaning |
|-------|---------|
| File path | Target file to analyze and refactor |
| Method name | Target specific routine or component within a file |

## Outcome

Safely refactored code with lower cognitive complexity, improved testability, and adherence to language-specific clean code guidelines, without breaking existing test suites.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| C# projects | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/csharp-patterns.md`, `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/csharp-formatting.md` |
| Python projects | `{{TOOLKIT_ROOT}}/skills/_shared/python-guidelines/principles.md`, `{{TOOLKIT_ROOT}}/skills/_shared/python-guidelines/google-style.md` |
| JavaScript / TypeScript | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/clean-code-js.md`, `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/clean-code-ts.md`, `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/google-ts-style.md` |
| React components | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/components-and-state.md`, `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/hooks-and-effects.md` |
| Angular directives / templates | `{{TOOLKIT_ROOT}}/skills/_shared/angular-guidelines/standalone-and-templates.md`, `{{TOOLKIT_ROOT}}/skills/_shared/angular-guidelines/style-and-structure.md`, `{{TOOLKIT_ROOT}}/skills/_shared/angular-guidelines/signals-and-state.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/refactor/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/refactor/references/<section>.md` |

**Never by default:** do not preload all `references/*.md` or all language guideline packs. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Detect stack / guidelines | `references/detect-guidelines.md` |
| Smells analysis | `references/smells-analysis.md` |
| Workflow / execution | `references/workflow-execution.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Re-check guardrails and session

Confirm `guardrails.mdc` and `SESSION.md` are loaded. If missing, ask (pt-BR) before continuing.

### 0. Detect stack
Follow `references/detect-guidelines.md`.

### 1. Smells analysis
Follow `references/smells-analysis.md`.

### 2–5. Workflow, execute, format, handoff
Follow `references/workflow-execution.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: refactor only (no feature/bug mix); no auto-commit.
