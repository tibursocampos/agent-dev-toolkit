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

## Trigger

Use when user asks for `/electron-developer`, `electron fix`, or a small isolated Electron implementation.

## Outcome

Working main/preload/renderer changes, validated with build and documented smoke (app launch), with optional handoff to `/commit`.

## Renderer stack (orchestration)

Detect renderer framework from `package.json`:

| Dependency | Lazy-load guidelines |
|------------|---------------------|
| `react` | `react-guidelines/` |
| `vue` | `vue-guidelines/` |
| Neither | `javascript-guidelines/`, `html-css-guidelines/` |

**Stay in `electron-developer` identity** - load stack guidelines for UI patterns only; do not switch to `react-developer` / `vue-developer`.

## When to escalate to SDD

Recommend `sdd-spec` -> `sdd-plan` -> `sdd-develop` if two or more apply: main+renderer+packaging overhaul, auto-update pipeline, cross-repo impact, 10+ files, or existing approved PLAN.

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists, treat it as the acceptance source. Map sections to renderer UI; do **not** reinterpret visual decisions. Implement **one session scope** from section 10 only.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.

## Lazy-load references

| When | Path |
|------|------|
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| Branch / commit | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Electron security / CSP | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-security.md` |
| Electron main / renderer | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-main-renderer.md` |
| Electron preload | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-preload.md` |
| Electron IPC | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-ipc.md` |
| Electron packaging | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/electron-packaging.md` |
| Electron delivery checklist | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/checklist.md` |
| Renderer stack | `react-guidelines/` or `vue-guidelines/` or `javascript-guidelines/` |
| Frontend core | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| Markup / styles | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/` |
| Principles | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/` |
| Context | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` |

Do not preload unrelated guideline trees. Load only the `electron-guidelines` rows needed for the current task.

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Electron project (`electron`, `electron-builder`, or `electron-vite` in `package.json`). Identify main/preload/renderer entry points.

### 1. Guidelines

Load Electron + renderer guidelines for this task. Review security defaults before IPC changes.

### 2. Branch

Use `feature/<slug>` or `feat/<id>`. Never commit on `main`/`master`/`develop`.

### 3. Micro-plan

Define 3-7 concrete tasks; checkpoint context at >= 40%.

### 4. Implement

Main/preload/renderer separation, typed IPC, contextIsolation. Match existing electron-vite or electron-builder layout.

### 5. Tests

Unit tests for pure modules; manual smoke: app launches, changed flow works.

### 6. Validate

```bash
npm run build
```

Document smoke steps in chat (launch app, exercise changed feature).

### 7. Handoff

Offer `/commit`. Do not commit automatically.

## Must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Enable `nodeIntegration: true` in renderer without explicit user approval
- Expose raw `ipcRenderer` on `window` without contextBridge
- Auto-commit or auto-PR
- Leave AI traces in code or identifiers

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Scope grew | `sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Missing design brief | `/impeccable shape` (new session) |
