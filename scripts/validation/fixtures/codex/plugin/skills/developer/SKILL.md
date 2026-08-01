---
name: developer
description: Smart router for stack skills, or senior fullstack for ad-hoc scripts/HTML/automation. Use for generic development or when invoking /developer.
---


## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

---

## Trigger

Use when user asks for `/developer` or requests generic coding/refactoring tasks without specifying a stack.

## Outcome

Correct stack skill loaded and executed, or ad-hoc implementation in fallback mode with optional handoff to `/commit`.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Git / language policy | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/AGENTS.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/branch-validation.mdc` |
| Developer flow | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/developer-common/GUIDE.md` |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/context-management.mdc` |
| Subagent-first / SPAWN.md | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/developer-common/subagent-first.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md` |

Do **not** load `dev_persona` or Antigravity KI artifacts.

## Frontend design routing

Before UI implementation, check project context:

1. If the task is **net-new UI** or a **visual redesign** and `PRODUCT.md` is missing -> recommend `/impeccable init` first (new session).
2. If `docs/DESIGN-BRIEF.md` (or `docs/design/DESIGN-BRIEF.md`) exists -> treat it as acceptance source; delegate to the matching `*-developer` skill **without reinterpreting visual decisions**.
3. One session = design (`impeccable shape`) **or** implementation (`*-developer`), not both.

Premium UI without a brief -> suggest `/impeccable shape` before stack implementation.

## Routing Logic

1. **Inspect the workspace** - identify stack in this order (frameworks before generic Node):

   | Signal | Route to |
   |--------|----------|
   | User asks for **new** Blip plugin scaffold (no existing `blip-ds` project) | `blip-plugin-developer` |
   | `package.json` with `blip-ds` and `iframe-message-proxy` (existing Blip plugin) | `react-developer` (loads `blip-guidelines/`) |
   | `.csproj` with `Microsoft.AspNetCore.Components`, or `_Imports.razor` / `App.razor` | `blazor-developer` |
   | `package.json` with `electron`, `electron-builder`, or `electron-vite` | `electron-developer` |
   | `package.json` with `vue` (and not React/Angular) | `vue-developer` |
   | `package.json` with `react-native` or `expo` | `react-native-developer` |
   | `package.json` with `react` | `react-developer` |
   | `package.json` with `@angular/core` or `angular` | `angular-developer` |
   | `package.json` (Node.js, no framework above) | `javascript-developer` |
   | `.csproj` / `.sln` without Blazor markers | `dotnet-developer` |
   | `pom.xml`, `build.gradle`, `build.gradle.kts`, or `settings.gradle` | `java-developer` |
   | `.py`, `requirements.txt`, `pyproject.toml` | `python-developer` |

2. **Invoke the specialized skill (if match found)**:
   - Silently read the `SKILL.md` of the matched stack under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/`:
     - `blip-plugin-developer`, `blazor-developer`, `electron-developer`, `vue-developer`, `react-native-developer`, `dotnet-developer`, `java-developer`, `react-developer`, `angular-developer`, `javascript-developer`, or `python-developer`
   - Assume the identity and instructions of that skill immediately.
   - Do **not** ask the user for confirmation to switch skills.

3. **Fallback mode (if no match found)**:
   - If no major framework structure is detected (e.g., isolated `.html`, `.sh`, `.bat`, `.ps1` files), **do not delegate**.
   - Assume the task directly using standard, secure engineering practices as a Senior Developer.
   - Proceed to the Execution Process below.

## Execution Process (fallback mode only)

### Subagent-first (before implement)

Stack `*-developer` skills own this policy when routed. In fallback mode: classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm target repo, read `README.md` (if exists), and summarize requested acceptance.

### 1. Micro-plan

Define 2-5 concrete tasks. Checkpoint context usage after each major change per `context-management.mdc`.

### 2. Implement

Write clean, maintainable code following universal best practices for the target language (e.g., HTML, Bash, Python script).

### 3. Tests / Validation

Run local scripts or linting tools to ensure the code executes without syntax errors.

### 4. Handoff

Offer `/commit`. Do not commit automatically.

## Must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Auto-commit or auto-PR
- Leave AI traces in code comments or identifiers (see `ai-stealth.mdc`)
- Delegate when a clear stack match exists

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| .NET work (explicit) | `/dotnet-developer` |
| Java work (explicit) | `/java-developer` |
| Large scope | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| UI design / brief | `/impeccable` (`shape` / `craft`) |
| New Blip plugin scaffold | `/blip-plugin-developer` |
