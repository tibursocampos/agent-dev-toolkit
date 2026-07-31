---
name: vue-developer
description: Implement or fix small-to-medium Vue 3 features without full SDD (Composition API, Pinia, Vitest). Use for isolated Vue work or when invoking /vue-developer.
---


## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/guardrails.md`
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

Use when user asks for `/vue-developer`, `vue fix`, or a small isolated Vue 3 implementation.

## Outcome

Working Vue components, composables, and tests in the target workspace, validated with tests/build, with optional handoff to `/commit`.

## When to escalate to SDD

Recommend `sdd-spec` -> `sdd-plan` -> `sdd-develop` if two or more apply: 3+ layers touched, new API contracts, cross-repo impact, 10+ files, or existing approved PLAN.

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists, treat it as the acceptance source. Map sections to Vue SFCs/composables; do **not** reinterpret visual decisions. Implement **one session scope** from section 10 only.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.

## Lazy-load references

| When | Path |
|------|------|
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| Branch / commit | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/branch-validation.mdc`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-3-branching.md` |
| Vue guidelines | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/vue-guidelines/` |
| Frontend core | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/frontend-guidelines/frontend-practices.md` |
| Markup / styles | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/html-css-guidelines/` |
| Frontend tests | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/frontend-guidelines/frontend-testing.md` |
| Principles | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/code-guidelines/principles/` |
| Context | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/context-management.mdc` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md` |

Do not preload unrelated guideline trees.

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace

Confirm Vue project (`package.json` with `vue`, typically Vite). Read `README.md`, summarize acceptance.

### 1. Guidelines

Load only required Vue/frontend guidelines for this task.

### 2. Branch

Use `feature/<slug>` or `feat/<id>`. Never commit on `main`/`master`/`develop`.

### 3. Micro-plan

Define 3-7 concrete tasks; checkpoint context at >= 40%.

### 4. Implement

`<script setup>`, composables, clean Vue architecture. Match existing patterns (Options API only when maintaining legacy code).

### 5. Tests

Vitest + Vue Test Utils for changed behavior.

### 6. Validate

```bash
npm test
npm run build
vue-tsc --noEmit
```

(or project-equivalent scripts)

### 7. Handoff

Offer `/commit`. Do not commit automatically.

## Must not

- Auto-commit or auto-PR
- Leave AI traces in code or identifiers
- Use obsolete corporate pipeline docs

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Scope grew | `sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Missing design brief | `/impeccable shape` (new session) |
