# vue-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

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
