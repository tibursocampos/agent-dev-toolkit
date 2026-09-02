---
name: developer
description: Smart router for stack skills, or senior fullstack for ad-hoc scripts/HTML/automation. Use for generic development or when invoking /developer.
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
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
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
| Git / language policy | `{{TOOLKIT_ROOT}}/AGENTS.md`, `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |
| Developer flow | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/GUIDE.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/developer/references/<section>.md` |

Do **not** load `dev_persona` or Antigravity KI artifacts.

**Never by default:** do not preload all `references/*.md` or all stack guideline packs. Route first; load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Frontend / design brief | `references/frontend-design-routing.md` |
| Stack match table | `references/stack-routing.md` |
| Fallback execution | `references/fallback-execution.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### 0. Frontend design routing
Follow `references/frontend-design-routing.md` when the task touches UI.

### 1. Stack routing
Follow `references/stack-routing.md` (e.g. `pom.xml` / `build.gradle` → `java-developer`). On match, load that stack `SKILL.md` and stop this router.

### 2. Fallback only
If no stack match: follow `references/fallback-execution.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: route before implement; no guideline dumps into children; no auto-commit.

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| .NET work (explicit) | `/dotnet-developer` |
| Java work (explicit) | `/java-developer` |
| Large scope | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| UI design / brief | `/impeccable` (`shape` / `craft`) |
| New Blip plugin scaffold | `/blip-plugin-developer` |
