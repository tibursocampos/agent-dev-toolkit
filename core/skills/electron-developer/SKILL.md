---
name: electron-developer
description: Implement or fix small-to-medium Electron apps (main, preload, renderer, IPC, packaging). Use for isolated Electron work or when invoking /electron-developer.
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

---

# Skill: electron-developer

## Trigger

Use when user asks for `/electron-developer`, `electron fix`, or a small isolated Electron implementation.

## Outcome

Working main/preload/renderer changes, validated with build and documented smoke (app launch), with optional handoff to `/commit`.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| Branch / commit | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Electron security / CSP | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-security.md` |
| Electron main / renderer | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-main-renderer.md` |
| Electron preload | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-preload.md` |
| Electron IPC | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-ipc.md` |
| Electron packaging | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-packaging.md` |
| Electron delivery checklist | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/checklist.md` |
| Renderer stack (React) | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/` — only files needed for the renderer task |
| Renderer stack (Vue) | `{{TOOLKIT_ROOT}}/skills/_shared/vue-guidelines/` — only files needed for the renderer task |
| Renderer stack (vanilla/JS) | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/` — only files needed for the renderer task |
| Frontend core | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| Markup / styles | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/` |
| Principles | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/principles-cheatsheet.md` (+ **one** approved style — never glob `architecture/**`) |
| Context | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/electron-developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/electron-developer/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`. do not preload the full `electron-guidelines/` pack plus all renderer stacks. Load security first when IPC/CSP changes; fan-out to main/preload/IPC/packaging only for that surface. Do not dump full stack guideline packs or memory-bank. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

**Progressive load:** DESIGN-BRIEF / workspace context first; then the Electron row for the active concern; open one renderer pack file only when editing renderer UI.

## Reference routing

| Situation | Path |
|-----------|------|
| Scope / SDD escalation / design brief | `references/scope.md` |
| Implement flow | `references/execute-flow.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Scope
Follow `references/scope.md` (SDD escalation, design brief / host detection when present).

### 1. Execute
Follow `references/execute-flow.md` (subagent-first, workspace → guidelines → branch → implement → tests → handoff).

## Must not

Enforce the full list in `references/must-not.md`. Critical: no guideline dumps into children; no auto-commit; lazy-load stack guidelines only — never dump full packs or memory-bank.

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Scope grew | `sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Missing design brief | `/impeccable shape` (new session) |
