# javascript-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Node/JS project (`package.json`, `tsconfig.json`, or JS/TS layout). Read `AGENTS.md` / `README.md`. Detect Express vs Fastify from dependencies; if Nest deps appear, recognize Nest and follow the existing Nest layout — **no** Nest skill and **no** `node-developer`. Summarize the user request and acceptance. Keep DOM/`html-css` routing when the task is frontend.

### 1. Guidelines (step 0.5)

Follow `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md`: load only the guideline files needed for this task. For HTTP APIs load `node-backend.md`; for DOM/`html-css` load `dom-patterns.md` / frontend packs; load TypeScript/clean-code docs when applicable.

### 2. Branch (step 3)

Baseline branch from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>` - never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

List 3-7 concrete tasks (files to touch, tests to add). Stay within one session when possible; checkpoint per `context-management.mdc` (>= 40% -> pause, offer `/commit`).

### 4. Implement

Match existing project patterns (Glob/Read similar modules first).

| Surface | Typical work |
|---------|----------------|
| Node API | Express routers / Fastify plugins, validation, services |
| Nest (recognition) | Follow existing Nest modules — no dedicated Nest pack |
| DOM / html-css | Vanilla or light libs per DESIGN-BRIEF |
| Shared TS/JS | Types, utils, scripts |

Apply the matching `javascript-guidelines` docs while writing - do not paste full bodies into chat.

### 5. Tests

Add or update tests for changed behavior. Prefer integration-style HTTP tests when the project already uses them; unit tests for isolated logic. Runners: Jest / Vitest / Mocha / `node:test` per project.

### 6. Build and test

```bash
npm test
npm run build
```

Add lint/type steps if configured. Fix failures within scope. Ask before running the full suite if the repo is very large.

### 7. Pre-commit (step 3.5) and handoff

Run `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` when appropriate. Offer `/commit` - do not commit automatically.

Before push/PR, run `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` and confirm Express/Fastify or DOM guidance used as needed.

### 8. SDD escalation

If scope grows during work, stop and recommend:

```
/sdd-spec - [feature description]
# then
/sdd-plan - PRD/...
# then
/sdd-develop - PLAN/... - Step 1
```
