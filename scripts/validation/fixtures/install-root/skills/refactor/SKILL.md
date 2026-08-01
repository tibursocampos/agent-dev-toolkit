---
name: refactor
description: Analyze complexity and smells, draft a safe refactor plan, and execute step-by-step with tests. Use when refactoring code or invoking /refactor.
---


## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/guardrails.mdc`
2. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
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

## Lazy-load

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| C# projects | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/csharp-patterns.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/csharp-formatting.md` |
| Python projects | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/python-guidelines/principles.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/python-guidelines/google-style.md` |
| JavaScript / TypeScript | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/clean-code-js.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/clean-code-ts.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/google-ts-style.md` |
| React components | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/react-guidelines/components-and-state.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/react-guidelines/hooks-and-effects.md` |
| Angular directives / templates | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/angular-guidelines/standalone-and-templates.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/angular-guidelines/style-and-structure.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/angular-guidelines/signals-and-state.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Re-check guardrails and session

Confirm `guardrails.mdc` and `SESSION.md` are loaded before continuing.
If missing, ask user (pt-BR):

```text
Antes do refactor, confirme:
- guardrails.mdc lido
- SESSION.md carregado

Posso seguir? (sim / ajustar / cancelar)
```


### 0. Detect Tech Stack and Load Guidelines

* Check the current workspace files (look for `.csproj`, `package.json`, `requirements.txt`, etc.).
* Lazy-load the corresponding language guidelines from `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/`.

### 1. Code Smells Analysis

* Read the target file. Identify code smells:
  * Methods or functions exceeding 30 lines.
  * Deep nesting (more than 3 levels of indentation).
  * Magic strings or hardcoded parameters.
  * Duplicate blocks of code within the file.
  * Violation of SOLID principles (e.g., class doing too many things).
* Present a summary of identified smells.

### 2. Workflow Decision & Path Selection

* Present the summary of identified code smells and debt.
* Stop and ask the user to choose the workflow execution path based on the scope:
  * **Option A - Direct Developer Skill (`/developer`):** For straightforward local refactoring edits.
  * **Option B - Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`):** For complex structural refactorings requiring a formal specification (PRD) and a step-by-step checklist (PLAN) in Portuguese.
  * **Option D - Plain Chat Plan:** Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.

### 3. Step-by-Step Execution & Validation

* For each accepted refactoring step:
  * Apply the minimum diff modification.
  * Run compiler checks (e.g. `dotnet build`, `npm run build`, `mypy` or build/typecheck commands).
  * Run the unit test suite (e.g. `dotnet test`, `npm test`, `pytest`).
  * If validation fails:
    * Revert the current step immediately.
    * Explain the failure and discuss alternative approaches.
  * If validation passes, proceed to the next step.

### 4. Code Formatting

* Once all steps are complete, run the target formatter on the refactored files (e.g. CSharpier, Prettier, Black, Ruff) to align with style rules.

### 5. Handoff

* Ask the user if they want to review the final diff and handoff to the commit skill:

```
/commit
```

## Must not

* Perform functional changes (adding features, fixing bugs) at the same time as refactoring.
* Commit or push changes automatically without explicit user confirmation.
