# angular-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Agent unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Angular project (`angular.json` or `@angular/core` in `package.json`). Follow `step-0-context.md`. Summarize acceptance.

### 1. Guidelines (step 0.5)

Follow `step-0.5-review-guidelines.md`: load only required Angular/frontend guideline files for this task.

### 2. Branch (step 3)

Baseline from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>-<slug>` — never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

### 4. Implement

Discover architectural patterns in the touched area first. Follow `structure-and-quality.md` §1: an operator order and the established project style outrank the toolkit style bar. Do not restyle existing members without an explicit yes. On greenfield / no clear comment-language mirror, ask before writing narrative comments/docs (identifiers stay English).

Components, services, RxJS patterns. Match existing module structure. Apply `angular-guidelines/` while writing — do not paste full bodies into chat.

### 5. Tests

Use the runner and test command configured by the repository (for example, the test target in `angular.json` and the corresponding package script). Preserve its package manager and established test configuration. Use Jasmine/Karma only when the project uses it or when no test baseline exists and it fits the task.

### 6. Build and test

```bash
<configured-package-manager> run <declared-test-script>
<configured-package-manager> run <declared-build-script>
```

If a required script is absent, use the repository's documented Angular CLI command and configuration; do not assume `npm` or introduce another runner.

### 7. Pre-commit (step 3.5) and handoff

Run `step-3.5-precommit-validation.md` when appropriate. Offer `/commit` — do not commit automatically. Before push/PR, run `step-7-checklist.md`.
