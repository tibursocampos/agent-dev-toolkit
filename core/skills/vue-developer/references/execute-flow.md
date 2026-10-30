# vue-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Agent unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Vue project (`package.json` with `vue`, typically Vite). Follow `step-0-context.md`. Summarize acceptance.

### 1. Guidelines (step 0.5)

Follow `step-0.5-review-guidelines.md`: load only required Vue/frontend guideline files for this task.

### 2. Branch (step 3)

Baseline from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>-<slug>` — never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

### 4. Implement

Discover architectural patterns in the touched area first. Follow `structure-and-quality.md` §1: an operator order and the established project style outrank the toolkit style bar. Do not restyle existing members without an explicit yes. On greenfield / no clear comment-language mirror, ask before writing narrative comments/docs (identifiers stay English).

`<script setup>`, composables, clean Vue architecture. Match existing patterns (Options API only when maintaining legacy code). Apply `vue-guidelines/` while writing — do not paste full bodies into chat.

### 5. Tests

Use the project's configured test runner for changed behavior. Preserve existing Vue test utilities and conventions; on a new project without a test baseline, prefer Vitest + Vue Test Utils.

### 6. Build and test

```bash
<configured-package-manager> run <declared-test-script>
<configured-package-manager> run <declared-build-script>
<configured-package-manager> run <declared-typecheck-script>
```

Inspect the lockfile and `package.json` scripts first; preserve the configured package manager. Run typecheck only when the project declares/configures it.

### 7. Pre-commit (step 3.5) and handoff

Run `step-3.5-precommit-validation.md` when appropriate. Offer `/commit` — do not commit automatically. Before push/PR, run `step-7-checklist.md`.
