---
name: vue-developer
description: Implement or fix small-to-medium Vue 3 features without full SDD (Composition API, Pinia, Vitest). Use for isolated Vue work or when invoking /vue-developer.
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

Invoke when the user asks for: `/vue-developer`, `vue fix`, or **small** isolated Vue 3 work that does not need a full PRD/PLAN cycle.

## Outcome

Working Vue components, composables, and tests in the target workspace, validated with tests/build, on a valid feature branch, with optional `/commit` handoff. Does not replace SDD for multi-step or cross-repo features.

## When to prefer SDD instead

Recommend `/sdd-spec` -> `sdd-plan` -> `sdd-develop` if **two or more** apply:

| Signal | Indicator |
|--------|-----------|
| Layers | 3+ layers (views, composables, stores, API client) across many modules |
| API contracts | New or altered HTTP/API contracts shared across apps |
| Repos | Frontend and another repo or service |
| Integrations | New auth, messaging, or external SDKs |
| Size | 10+ files or estimated 4+ hours |
| PLAN exists | User already has an approved PLAN - use `sdd-develop` |

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists, treat it as the acceptance source. Map sections to Vue SFCs/composables; do **not** reinterpret visual decisions. Implement **one session scope** from section 10 only.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Repo context | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Branching | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md`, `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` |
| Pre-PR gate | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` |
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| Vue Composition / SFC | `{{TOOLKIT_ROOT}}/skills/_shared/vue-guidelines/composition-and-sfc.md` |
| Vue style guide essentials | `{{TOOLKIT_ROOT}}/skills/_shared/vue-guidelines/style-guide-essentials.md` |
| Vue reactivity | `{{TOOLKIT_ROOT}}/skills/_shared/vue-guidelines/reactivity.md` |
| Vue routing / state | `{{TOOLKIT_ROOT}}/skills/_shared/vue-guidelines/routing-and-state.md` |
| Vue testing | `{{TOOLKIT_ROOT}}/skills/_shared/vue-guidelines/testing.md` |
| Vue accessibility | `{{TOOLKIT_ROOT}}/skills/_shared/vue-guidelines/accessibility.md` |
| Vue delivery checklist | `{{TOOLKIT_ROOT}}/skills/_shared/vue-guidelines/checklist.md` |
| Frontend core | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| FE structure (ARCH / CONTINUITY needs folder layout) | Prefer `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-architecture.md` — **not** a per-framework CA tree |
| Frontend tests | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-testing.md` |
| Semantic HTML | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/semantic-html.md` |
| a11y basics (HTML/CSS) | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/accessibility-basics.md` |
| CSS foundations | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/css-foundations.md` |
| Modern CSS | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/modern-css.md` |
| SCSS | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/scss-guidelines.md` |
| Inclusive components | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/inclusive-components.md` |
| HTML/CSS checklist | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/checklist.md` |
| Principles | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/principles-cheatsheet.md` (+ `architecture-selection.md` or **one** approved style — never glob `architecture/**`) |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |

Do **not** preload unrelated guideline trees. Do not redesign `vue-guidelines/` in this skill — load existing pack rows only.

**Never by default:** do not preload other stack guideline packs. Load only Vue rows needed for the current task.

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

Confirm Vue project (`package.json` with `vue`, typically Vite). Follow `step-0-context.md`. Summarize acceptance.

### 1. Guidelines (step 0.5)

Follow `step-0.5-review-guidelines.md`: load only required Vue/frontend guideline files for this task.

### 2. Branch (step 3)

Baseline from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>` — never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

List 3-7 concrete tasks; checkpoint per `context-management.mdc` (>= 40% -> pause, offer `/commit`).

### 4. Implement

`<script setup>`, composables, clean Vue architecture. Match existing patterns (Options API only when maintaining legacy code). Apply `vue-guidelines/` while writing — do not paste full bodies into chat.

### 5. Tests

Vitest + Vue Test Utils for changed behavior.

### 6. Build and test

```bash
npm test
npm run build
vue-tsc --noEmit
```

(or project-equivalent scripts)

### 7. Pre-commit (step 3.5) and handoff

Run `step-3.5-precommit-validation.md` when appropriate. Offer `/commit` — do not commit automatically. Before push/PR, run `step-7-checklist.md`.

## Must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Redesign or rewrite the `vue-guidelines/` pack in-session
- Auto-commit or auto-PR
- Leave AI traces in code or identifiers
- Use obsolete corporate pipeline docs

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Scope grew | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Missing design brief | `/impeccable shape` (new session) |
